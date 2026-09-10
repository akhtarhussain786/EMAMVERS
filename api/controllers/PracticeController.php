<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../services/QuestionBank.php';

/**
 * Student-configured practice mocks.
 *
 * The student chooses the exam, subjects, question count and duration; the
 * paper is drawn from the bank at that moment and stored against the attempt,
 * so it can be resumed and reviewed like any other test.
 */
class PracticeController {

    const MIN_QUESTIONS = 5;
    const MAX_QUESTIONS = 100;
    const MIN_MINUTES   = 1;
    const MAX_MINUTES   = 180;

    /** Everything the builder screen needs: exams, and per-subject availability. */
    public static function options() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $db = Database::getConnection();

        $examId = isset($_GET['exam_id']) ? (int)$_GET['exam_id'] : 0;

        $exams = $db->query("
            SELECT e.id, e.title, ec.name AS category_name
            FROM exams e
            LEFT JOIN exam_categories ec ON e.category_id = ec.id
            WHERE e.status = 'active'
            ORDER BY e.title ASC
        ")->fetchAll();

        // How many questions are actually available per subject, so the UI can
        // grey out a subject with an empty bank instead of failing on Start.
        $sql = "
            SELECT s.id AS subject_id, s.name AS subject_name, COUNT(q.id) AS available
            FROM subjects s
            LEFT JOIN questions q ON q.subject_id = s.id AND q.status = 'published'
        ";
        $params = [];
        if ($examId) {
            $sql .= " AND EXISTS (SELECT 1 FROM question_exams qe WHERE qe.question_id = q.id AND qe.exam_id = ?)";
            $params[] = $examId;
        }
        $sql .= " GROUP BY s.id, s.name HAVING available > 0 ORDER BY s.name ASC";

        $stmt = $db->prepare($sql);
        $stmt->execute($params);

        Response::json([
            'exams'          => $exams,
            'subjects'       => $stmt->fetchAll(),
            'question_range' => ['min' => self::MIN_QUESTIONS, 'max' => self::MAX_QUESTIONS],
            'minute_range'   => ['min' => self::MIN_MINUTES,   'max' => self::MAX_MINUTES],
            'presets'        => [
                ['label' => 'Quick 10',   'questions' => 10, 'minutes' => 10],
                ['label' => 'Standard 25','questions' => 25, 'minutes' => 25],
                ['label' => 'Full 50',    'questions' => 50, 'minutes' => 45],
            ],
        ], 'Practice options loaded');
    }

    /**
     * Builds and starts a custom practice attempt.
     * Body: exam_id, subject_ids[], question_count, duration_minutes, difficulty (optional)
     */
    public static function start() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $examId     = (int)($input['exam_id'] ?? 0);
        $subjectIds = array_values(array_unique(array_filter(array_map('intval', (array)($input['subject_ids'] ?? [])))));
        $count      = (int)($input['question_count'] ?? 25);
        $minutes    = (int)($input['duration_minutes'] ?? 25);
        $difficulty = $input['difficulty'] ?? null;

        $errors = [];
        if (!$examId) $errors['exam_id'] = 'Choose an exam';
        if (empty($subjectIds)) $errors['subject_ids'] = 'Choose at least one subject';
        if ($count < self::MIN_QUESTIONS || $count > self::MAX_QUESTIONS) {
            $errors['question_count'] = 'Question count must be between ' . self::MIN_QUESTIONS . ' and ' . self::MAX_QUESTIONS;
        }
        if ($minutes < self::MIN_MINUTES || $minutes > self::MAX_MINUTES) {
            $errors['duration_minutes'] = 'Duration must be between ' . self::MIN_MINUTES . ' and ' . self::MAX_MINUTES . ' minutes';
        }
        if ($difficulty !== null && $difficulty !== '' && !in_array($difficulty, ['easy','medium','hard'], true)) {
            $errors['difficulty'] = 'Difficulty must be easy, medium or hard';
        }
        if ($errors) {
            Response::json(null, 'Please correct the highlighted fields', 'error', 422, $errors);
            return;
        }

        $db = Database::getConnection();

        $examStmt = $db->prepare("SELECT id, title FROM exams WHERE id = ? AND status = 'active'");
        $examStmt->execute([$examId]);
        $exam = $examStmt->fetch();
        if (!$exam) Response::error('That exam is not available', 404);

        // Split the requested count evenly across the chosen subjects; the
        // remainder goes to the first subjects so the total always matches.
        $perSubject = intdiv($count, count($subjectIds));
        $remainder  = $count % count($subjectIds);

        $paper = [];
        foreach ($subjectIds as $i => $subjectId) {
            $need = $perSubject + ($i < $remainder ? 1 : 0);
            if ($need < 1) continue;

            $picked = [];
            if ($difficulty) {
                foreach (QuestionBank::drawBucket($db, $userId, [
                    'subject_id' => $subjectId, 'difficulty' => $difficulty,
                    'count' => $need, 'exam_id' => $examId,
                ]) as $r) $picked[$r['id']] = $r;
            } else {
                foreach (QuestionBank::difficultySplit($need) as $d => $n) {
                    foreach (QuestionBank::drawBucket($db, $userId, [
                        'subject_id' => $subjectId, 'difficulty' => $d,
                        'count' => $n, 'exam_id' => $examId,
                    ]) as $r) $picked[$r['id']] = $r;
                }
            }

            // Top up from any difficulty when a bucket was short.
            if (count($picked) < $need) {
                foreach (QuestionBank::drawBucket($db, $userId, [
                    'subject_id' => $subjectId,
                    'count' => $need - count($picked) + 10,
                    'exam_id' => $examId,
                ]) as $r) {
                    if (count($picked) >= $need) break;
                    $picked[$r['id']] = $r;
                }
            }

            foreach ($picked as $r) {
                $paper[] = $r + ['section_id' => null, 'positive_marks' => 2.00, 'negative_marks' => 0.50];
            }
        }

        if (empty($paper)) {
            Response::error('No questions are available for that combination yet. Try different subjects.', 409);
        }

        // Custom practice hangs off a per-exam holder test so existing result,
        // solution and history queries keep working unchanged.
        $testId = self::practiceTestId($db, $examId, $exam['title']);

        $db->beginTransaction();
        try {
            $db->prepare("
                INSERT INTO test_attempts (test_id, user_id, pattern_version, assembly_mode, status, started_at)
                VALUES (?, ?, 1, 'randomised', 'in_progress', NOW())
            ")->execute([$testId, $userId]);
            $attemptId = $db->lastInsertId();

            QuestionBank::persistPaper($db, $attemptId, $paper);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }

        Response::json([
            'attempt_id'        => (int)$attemptId,
            'test_id'           => (int)$testId,
            'question_count'    => count($paper),
            'requested_count'   => $count,
            'duration_minutes'  => $minutes,
            'remaining_seconds' => $minutes * 60,
            'exam_title'        => $exam['title'],
            // Honest when the bank could not fill the request.
            'short_by'          => max(0, $count - count($paper)),
        ], count($paper) < $count
            ? 'Practice test ready with ' . count($paper) . ' questions (the bank had fewer than requested)'
            : 'Practice test ready', 'success', 201);
    }

    /** Finds or creates the holder test that custom attempts attach to. */
    private static function practiceTestId($db, $examId, $examTitle) {
        $slug = 'custom-practice-exam-' . $examId;

        $stmt = $db->prepare("SELECT id FROM tests WHERE slug = ?");
        $stmt->execute([$slug]);
        $id = $stmt->fetchColumn();
        if ($id) return (int)$id;

        // Reuse any pattern belonging to this exam; a custom paper does not
        // follow pattern sections, but tests.pattern_id is NOT NULL.
        $pStmt = $db->prepare("SELECT id FROM exam_patterns WHERE exam_id = ? ORDER BY id ASC LIMIT 1");
        $pStmt->execute([$examId]);
        $patternId = $pStmt->fetchColumn();
        if (!$patternId) Response::error('This exam has no pattern configured yet', 409);

        $db->prepare("
            INSERT INTO tests (exam_id, pattern_id, title, slug, test_type, is_paid, price, instructions, status, is_randomised)
            VALUES (?, ?, ?, ?, 'sectional', 0, 0, 'Custom practice test built by the candidate.', 'published', 1)
        ")->execute([$examId, $patternId, $examTitle . ' — Custom Practice', $slug]);

        return (int)$db->lastInsertId();
    }
}
