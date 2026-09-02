<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

/**
 * Teacher question authoring.
 *
 * Teachers are a distinct account type (users.user_type = 'teacher'); a student
 * account is never upgraded into one. Everything a teacher submits lands in the
 * questions table with status='review' and stays invisible to students until an
 * admin approves it.
 */
class TeacherController {

    /**
     * Resolves the teacher profile for the caller, or terminates.
     * Authenticates first so an anonymous request never reaches the database.
     */
    private static function requireTeacher(&$db) {
        $auth = AuthMiddleware::getAuthenticatedUser('teacher');
        $userId = $auth['sub'];

        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT tp.*, u.full_name, u.email
            FROM teacher_profiles tp
            JOIN users u ON tp.user_id = u.id
            WHERE tp.user_id = ?
        ");
        $stmt->execute([$userId]);
        $profile = $stmt->fetch();

        if (!$profile) {
            Response::error('No teacher profile found for this account', 403);
        }
        if ($profile['status'] !== 'active') {
            Response::error('Your teacher account has been suspended. Please contact the administrator.', 403);
        }
        return $profile;
    }

    /** Subjects and topics a teacher can file a question under. */
    public static function getTaxonomy() {
        $db = null;
        self::requireTeacher($db);

        $subjects = $db->query("SELECT id, name, code FROM subjects ORDER BY name ASC")->fetchAll();

        // Topics are returned grouped by subject so the form can cascade.
        $topics = $db->query("
            SELECT t.id, t.name, c.subject_id, c.name AS chapter_name, c.id AS chapter_id
            FROM topics t
            JOIN chapters c ON t.chapter_id = c.id
            ORDER BY c.subject_id ASC, t.name ASC
        ")->fetchAll();

        $bySubject = [];
        foreach ($topics as $t) {
            $bySubject[$t['subject_id']][] = $t;
        }

        foreach ($subjects as &$s) {
            $s['topics'] = $bySubject[$s['id']] ?? [];
        }
        unset($s);

        Response::json([
            'subjects'     => $subjects,
            'difficulties' => ['easy', 'medium', 'hard'],
        ], 'Question taxonomy loaded');
    }

    /**
     * Submits a question for review.
     * Expects: subject_id, topic_id (optional), difficulty, question_text,
     *          options[4] with one correct, explanation.
     */
    public static function submitQuestion() {
        $db = null;
        $profile = self::requireTeacher($db);

        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $subjectId    = intval($input['subject_id'] ?? 0);
        $topicId      = !empty($input['topic_id']) ? intval($input['topic_id']) : null;
        $difficulty   = in_array($input['difficulty'] ?? '', ['easy','medium','hard'], true) ? $input['difficulty'] : 'medium';
        $questionText = trim($input['question_text'] ?? '');
        $explanation  = trim($input['explanation'] ?? '');
        $options      = $input['options'] ?? [];
        $correctKey   = strtoupper(trim($input['correct_option'] ?? ''));

        // ── Validation ───────────────────────────────────────────────────
        $errors = [];

        if (!$subjectId) $errors['subject_id'] = 'Select the subject this question belongs to';
        if ($questionText === '') $errors['question_text'] = 'Question text is required';
        if (mb_strlen($questionText) > 2000) $errors['question_text'] = 'Question text must be under 2000 characters';
        if ($explanation === '') $errors['explanation'] = 'An explanation is required so students learn from the answer';

        if (!is_array($options) || count($options) !== 4) {
            $errors['options'] = 'Exactly four options (A, B, C, D) are required';
        } else {
            $seen = [];
            foreach (['A','B','C','D'] as $i => $key) {
                $text = trim((string)($options[$i]['option_text'] ?? $options[$i] ?? ''));
                if ($text === '') {
                    $errors['options'] = "Option $key cannot be empty";
                    break;
                }
                $norm = mb_strtolower($text);
                if (isset($seen[$norm])) {
                    $errors['options'] = "Options $seen[$norm] and $key are identical";
                    break;
                }
                $seen[$norm] = $key;
            }
        }

        if (!in_array($correctKey, ['A','B','C','D'], true)) {
            $errors['correct_option'] = 'Mark which option (A, B, C or D) is correct';
        }

        if ($errors) {
            Response::json(null, 'Please correct the highlighted fields', 'error', 422, $errors);
            return;
        }

        // Subject must exist.
        $sCheck = $db->prepare("SELECT 1 FROM subjects WHERE id = ?");
        $sCheck->execute([$subjectId]);
        if (!$sCheck->fetchColumn()) Response::error('Selected subject no longer exists', 422);

        // Topic, if given, must belong to that subject.
        $chapterId = null;
        if ($topicId) {
            $tCheck = $db->prepare("
                SELECT c.id AS chapter_id FROM topics t
                JOIN chapters c ON t.chapter_id = c.id
                WHERE t.id = ? AND c.subject_id = ?
            ");
            $tCheck->execute([$topicId, $subjectId]);
            $chapterId = $tCheck->fetchColumn();
            if (!$chapterId) Response::error('The selected topic does not belong to that subject', 422);
        }

        // Reject an exact duplicate of a question this teacher already submitted.
        $dup = $db->prepare("
            SELECT q.id FROM questions q
            JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            WHERE q.author_user_id = ? AND qt.question_text = ? AND q.status <> 'rejected'
            LIMIT 1
        ");
        $dup->execute([$profile['user_id'], $questionText]);
        if ($dup->fetchColumn()) {
            Response::error('You have already submitted this question', 409);
        }

        $db->beginTransaction();
        try {
            // status='review' keeps it out of every student-facing query.
            $qStmt = $db->prepare("
                INSERT INTO questions (subject_id, chapter_id, topic_id, author_user_id, question_type, difficulty, status)
                VALUES (?, ?, ?, ?, 'MCQ', ?, 'review')
            ");
            $qStmt->execute([$subjectId, $chapterId ?: null, $topicId, $profile['user_id'], $difficulty]);
            $questionId = $db->lastInsertId();

            $db->prepare("
                INSERT INTO question_translations (question_id, language, question_text, solution_text)
                VALUES (?, 'en', ?, ?)
            ")->execute([$questionId, $questionText, $explanation]);

            $optStmt = $db->prepare("
                INSERT INTO question_options (question_id, option_key, language, option_text, is_correct)
                VALUES (?, ?, 'en', ?, ?)
            ");
            foreach (['A','B','C','D'] as $i => $key) {
                $text = trim((string)($options[$i]['option_text'] ?? $options[$i] ?? ''));
                $optStmt->execute([$questionId, $key, $text, $key === $correctKey ? 1 : 0]);
            }

            $db->prepare("UPDATE teacher_profiles SET questions_submitted = questions_submitted + 1 WHERE user_id = ?")
               ->execute([$profile['user_id']]);

            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }

        Response::json([
            'question_id' => intval($questionId),
            'status'      => 'review',
        ], 'Question submitted. It will appear for students once an admin approves it.', 'success', 201);
    }

    /** The teacher's own submissions, newest first, optionally filtered by status. */
    public static function myQuestions() {
        $db = null;
        $profile = self::requireTeacher($db);

        $status = $_GET['status'] ?? '';
        $where  = ['q.author_user_id = ?'];
        $params = [$profile['user_id']];

        if (in_array($status, ['review','published','rejected'], true)) {
            $where[] = 'q.status = ?';
            $params[] = $status;
        }
        $whereSql = implode(' AND ', $where);

        $stmt = $db->prepare("
            SELECT q.id, q.status, q.difficulty, q.rejection_reason, q.created_at, q.reviewed_at,
                   qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, t.name AS topic_name
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN topics t ON q.topic_id = t.id
            WHERE $whereSql
            ORDER BY q.created_at DESC
            LIMIT 200
        ");
        $stmt->execute($params);
        $questions = $stmt->fetchAll();

        // Attach options in one extra query rather than one per question.
        if ($questions) {
            $ids = array_column($questions, 'id');
            $ph  = implode(',', array_fill(0, count($ids), '?'));
            $opt = $db->prepare("SELECT question_id, option_key, option_text, is_correct FROM question_options WHERE question_id IN ($ph) AND language='en' ORDER BY option_key");
            $opt->execute($ids);
            $byQ = [];
            foreach ($opt->fetchAll() as $o) $byQ[$o['question_id']][] = $o;
            foreach ($questions as &$q) $q['options'] = $byQ[$q['id']] ?? [];
            unset($q);
        }

        Response::json([
            'questions' => $questions,
            'counts'    => [
                'submitted' => intval($profile['questions_submitted']),
                'approved'  => intval($profile['questions_approved']),
                'rejected'  => intval($profile['questions_rejected']),
                'pending'   => max(0, intval($profile['questions_submitted']) - intval($profile['questions_approved']) - intval($profile['questions_rejected'])),
            ],
        ], 'Your submitted questions');
    }

    /** Headline figures for the teacher dashboard. */
    public static function dashboard() {
        $db = null;
        $profile = self::requireTeacher($db);

        $stmt = $db->prepare("
            SELECT q.status, COUNT(*) AS total
            FROM questions q WHERE q.author_user_id = ?
            GROUP BY q.status
        ");
        $stmt->execute([$profile['user_id']]);
        $byStatus = ['review' => 0, 'published' => 0, 'rejected' => 0, 'draft' => 0];
        foreach ($stmt->fetchAll() as $row) $byStatus[$row['status']] = intval($row['total']);

        $recent = $db->prepare("
            SELECT q.id, q.status, q.created_at, qt.question_text, s.name AS subject_name
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            WHERE q.author_user_id = ?
            ORDER BY q.created_at DESC LIMIT 5
        ");
        $recent->execute([$profile['user_id']]);

        $totalReviewed = $byStatus['published'] + $byStatus['rejected'];

        Response::json([
            'teacher' => [
                'display_name'   => $profile['display_name'],
                'full_name'      => $profile['full_name'],
                'specialisation' => $profile['specialisation'],
            ],
            'stats' => [
                'pending_review' => $byStatus['review'],
                'approved'       => $byStatus['published'],
                'rejected'       => $byStatus['rejected'],
                'total'          => array_sum($byStatus),
                // Share of reviewed submissions that were accepted.
                'approval_rate'  => $totalReviewed > 0
                    ? round(($byStatus['published'] / $totalReviewed) * 100, 1)
                    : null,
            ],
            'recent_submissions' => $recent->fetchAll(),
        ], 'Teacher dashboard loaded');
    }
}
