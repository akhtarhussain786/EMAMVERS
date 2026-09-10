<?php
/**
 * Draws randomised papers from the question bank.
 *
 * Every attempt gets its own selection, so retaking a mock never serves the
 * same paper twice. Selection is a *preference* rather than a hard exclusion:
 * recently-seen questions rank last but are not removed, so a thin bank
 * degrades into "slightly familiar" instead of failing to assemble.
 */
class QuestionBank {

    /** Questions from this many recent attempts rank last in a draw. */
    const RECENT_ATTEMPTS_WINDOW = 5;

    /**
     * Selects questions for one bucket (subject × difficulty × exam).
     * @return array question rows, already randomised
     */
    public static function drawBucket($db, $userId, array $bucket) {
        $subjectId  = isset($bucket['subject_id']) ? (int)$bucket['subject_id'] : 0;
        $difficulty = $bucket['difficulty'] ?? null;
        $count      = max(0, (int)($bucket['count'] ?? 0));
        $examId     = isset($bucket['exam_id']) ? (int)$bucket['exam_id'] : 0;
        if ($count === 0) return [];

        $where  = ["q.status = 'published'"];
        $params = [];

        if ($subjectId) { $where[] = 'q.subject_id = ?'; $params[] = $subjectId; }
        if ($difficulty && in_array($difficulty, ['easy','medium','hard'], true)) {
            $where[] = 'q.difficulty = ?';
            $params[] = $difficulty;
        }
        // Restrict to this department's bank when the exam has one.
        if ($examId) {
            $where[] = 'EXISTS (SELECT 1 FROM question_exams qe WHERE qe.question_id = q.id AND qe.exam_id = ?)';
            $params[] = $examId;
        }
        // A question with no correct option could not be scored.
        $where[] = "EXISTS (SELECT 1 FROM question_options o WHERE o.question_id = q.id AND o.is_correct = 1)";
        $whereSql = implode(' AND ', $where);

        $sql = "
            SELECT q.id, q.subject_id, q.difficulty, q.question_type,
                   COALESCE(seen.seen_count, 0) AS seen_recently
            FROM questions q
            LEFT JOIN (
                SELECT aq.question_id, COUNT(*) AS seen_count
                FROM attempt_questions aq
                JOIN (
                    SELECT id FROM test_attempts
                    WHERE user_id = ? ORDER BY id DESC LIMIT " . self::RECENT_ATTEMPTS_WINDOW . "
                ) recent ON recent.id = aq.attempt_id
                GROUP BY aq.question_id
            ) seen ON seen.question_id = q.id
            WHERE $whereSql
            ORDER BY seen_recently ASC, RAND()
            LIMIT $count
        ";
        $stmt = $db->prepare($sql);
        $stmt->execute(array_merge([$userId], $params));
        return $stmt->fetchAll();
    }

    /** Assembles a whole paper from a pattern's sections. */
    public static function assemblePaper($db, $userId, $patternId, $examId, $fallbackCount = 0) {
        $sections = [];
        if ($patternId) {
            $stmt = $db->prepare("
                SELECT id, section_name, subject_id, question_count, positive_marks, negative_marks, sort_order
                FROM pattern_sections WHERE pattern_id = ? ORDER BY sort_order ASC
            ");
            $stmt->execute([$patternId]);
            $sections = $stmt->fetchAll();
        }

        $paper = [];

        if ($sections) {
            foreach ($sections as $section) {
                $needed = (int)$section['question_count'];
                $picked = [];

                // Mirror a real paper's spread rather than drawing uniformly.
                foreach (self::difficultySplit($needed) as $difficulty => $n) {
                    foreach (self::drawBucket($db, $userId, [
                        'subject_id' => $section['subject_id'],
                        'difficulty' => $difficulty,
                        'count'      => $n,
                        'exam_id'    => $examId,
                    ]) as $r) $picked[$r['id']] = $r;
                }

                // Top up from any difficulty when a bucket came up short.
                if (count($picked) < $needed) {
                    foreach (self::drawBucket($db, $userId, [
                        'subject_id' => $section['subject_id'],
                        'count'      => $needed - count($picked) + 10,
                        'exam_id'    => $examId,
                    ]) as $r) {
                        if (count($picked) >= $needed) break;
                        $picked[$r['id']] = $r;
                    }
                }

                foreach (array_slice($picked, 0, $needed, true) as $r) {
                    $paper[] = $r + [
                        'section_id'     => $section['id'],
                        'positive_marks' => $section['positive_marks'],
                        'negative_marks' => $section['negative_marks'],
                    ];
                }
            }
        } elseif ($fallbackCount > 0) {
            foreach (self::drawBucket($db, $userId, ['count' => $fallbackCount, 'exam_id' => $examId]) as $r) {
                $paper[] = $r + ['section_id' => null, 'positive_marks' => 2.00, 'negative_marks' => 0.50];
            }
        }

        return $paper;
    }

    /** Roughly 30/50/20 easy/medium/hard, the usual competitive-exam spread. */
    public static function difficultySplit($total) {
        $easy = (int)round($total * 0.30);
        $hard = (int)round($total * 0.20);
        return ['easy' => $easy, 'medium' => max(0, $total - $easy - $hard), 'hard' => $hard];
    }

    /**
     * Persists the drawn paper against the attempt, shuffling both the question
     * order and each question's option order.
     */
    public static function persistPaper($db, $attemptId, array $paper) {
        if (!$paper) return 0;
        shuffle($paper);

        $stmt = $db->prepare("
            INSERT INTO attempt_questions
                (attempt_id, question_id, question_order, section_id, positive_marks, negative_marks, option_order)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");

        $order = 1;
        foreach ($paper as $q) {
            // Shuffling options stops a retaker recalling "the answer was C".
            $keys = self::optionKeysFor($db, $q['id']);
            shuffle($keys);
            $stmt->execute([
                $attemptId, $q['id'], $order++, $q['section_id'] ?? null,
                $q['positive_marks'] ?? 2.00, $q['negative_marks'] ?? 0.50,
                $keys ? implode(',', $keys) : null,
            ]);
        }
        return count($paper);
    }

    private static function optionKeysFor($db, $questionId) {
        $stmt = $db->prepare("SELECT DISTINCT option_key FROM question_options WHERE question_id = ? AND language = 'en' ORDER BY option_key");
        $stmt->execute([$questionId]);
        return $stmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
    }

    /** Bank depth per subject/difficulty, for the admin screen and the top-up job. */
    public static function bankLevels($db, $examId = null) {
        $sql = "SELECT s.id AS subject_id, s.name AS subject_name, q.difficulty, COUNT(*) AS total
                FROM questions q JOIN subjects s ON q.subject_id = s.id
                WHERE q.status = 'published'";
        $params = [];
        if ($examId) {
            $sql .= " AND EXISTS (SELECT 1 FROM question_exams qe WHERE qe.question_id = q.id AND qe.exam_id = ?)";
            $params[] = $examId;
        }
        $sql .= " GROUP BY s.id, s.name, q.difficulty ORDER BY s.name, q.difficulty";
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }
}
