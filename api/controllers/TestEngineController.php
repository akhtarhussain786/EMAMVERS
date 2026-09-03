<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../services/QuestionBank.php';

class TestEngineController {
    public static function getInstructions($testId) {
        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT t.id, t.title, t.instructions, t.test_type, t.is_paid, t.price,
                   ep.id as pattern_id, ep.name as pattern_name, ep.timer_mode, ep.total_duration_seconds, 
                   ep.total_questions, ep.total_marks, ep.default_positive_marks, ep.default_negative_marks,
                   ep.navigation_policy, ep.languages, e.title as exam_title
            FROM tests t
            JOIN exam_patterns ep ON t.pattern_id = ep.id
            JOIN exams e ON t.exam_id = e.id
            WHERE t.id = :id
        ");
        $stmt->execute(['id' => $testId]);
        $test = $stmt->fetch();

        if (!$test) Response::error('Test not found', 404);

        // Fetch section breakdown
        $stmtSections = $db->prepare("
            SELECT ps.id, ps.section_name, ps.question_count, ps.positive_marks, ps.negative_marks, ps.duration_seconds
            FROM pattern_sections ps
            WHERE ps.pattern_id = :pattern_id
            ORDER BY ps.sort_order ASC
        ");
        $stmtSections->execute(['pattern_id' => $test['pattern_id']]);
        $test['sections'] = $stmtSections->fetchAll();

        Response::json($test, 'Test instructions loaded successfully');
    }

    public static function startAttempt($testId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();

        // Fetch test & pattern details
        $stmtTest = $db->prepare("
            SELECT t.*, ep.pattern_version, ep.timer_mode, ep.total_duration_seconds, ep.navigation_policy, ep.languages
            FROM tests t
            JOIN exam_patterns ep ON t.pattern_id = ep.id
            WHERE t.id = :id AND t.status = 'published'
        ");
        $stmtTest->execute(['id' => $testId]);
        $test = $stmtTest->fetch();

        if (!$test) Response::error('Test is not published or available', 404);

        // Resume an in-progress attempt, otherwise open a new one.
        $stmtCheck = $db->prepare("SELECT id, started_at FROM test_attempts WHERE test_id = :test_id AND user_id = :user_id AND status = 'in_progress' ORDER BY id DESC LIMIT 1");
        $stmtCheck->execute(['test_id' => $testId, 'user_id' => $userId]);
        $existing = $stmtCheck->fetch();

        $randomised = !empty($test['is_randomised']);

        if ($existing) {
            $attemptId = $existing['id'];
            $startedAt = strtotime($existing['started_at']);
        } else {
            $stmtCreate = $db->prepare("
                INSERT INTO test_attempts (test_id, user_id, pattern_version, assembly_mode, status, started_at)
                VALUES (:test_id, :user_id, :pv, :mode, 'in_progress', NOW())
            ");
            $stmtCreate->execute([
                'test_id' => $testId, 'user_id' => $userId,
                'pv' => $test['pattern_version'],
                'mode' => $randomised ? 'randomised' : 'fixed',
            ]);
            $attemptId = $db->lastInsertId();
            $startedAt = time();

            // A randomised blueprint draws its own paper, stored against this
            // attempt so a resume shows the identical questions and ordering.
            if ($randomised) {
                $paper = QuestionBank::assemblePaper(
                    $db, $userId, $test['pattern_id'], $test['exam_id'],
                    (int)($test['total_questions'] ?? 0)
                );
                if (!$paper) {
                    $db->prepare("DELETE FROM test_attempts WHERE id = ?")->execute([$attemptId]);
                    Response::error('This test has no questions available yet. Please try again later.', 409);
                }
                QuestionBank::persistPaper($db, $attemptId, $paper);
            }
        }

        // Remaining time is derived server-side from started_at, so reloading
        // the app cannot hand the candidate a fresh full-length timer.
        $totalDuration = intval($test['total_duration_seconds']) ?: 3600;
        $elapsed = max(0, time() - $startedAt);
        $remainingSeconds = max(0, $totalDuration - $elapsed);

        // Questions come from the attempt for a randomised paper, and from the
        // shared blueprint for a fixed one (a ranked challenge still needs
        // every candidate on the same paper).
        if ($randomised) {
            $stmtQ = $db->prepare("
                SELECT aq.question_id, aq.question_order, aq.positive_marks, aq.negative_marks, aq.section_id,
                       aq.option_order,
                       q.question_type, q.difficulty, q.pyq_year, q.pyq_shift, s.name as section_name
                FROM attempt_questions aq
                JOIN questions q ON aq.question_id = q.id
                LEFT JOIN pattern_sections ps ON aq.section_id = ps.id
                LEFT JOIN subjects s ON ps.subject_id = s.id
                WHERE aq.attempt_id = :attempt_id
                ORDER BY aq.question_order ASC
            ");
            $stmtQ->execute(['attempt_id' => $attemptId]);
        } else {
            $stmtQ = $db->prepare("
                SELECT tq.question_id, tq.question_order, tq.positive_marks, tq.negative_marks, tq.section_id,
                       NULL AS option_order,
                       q.question_type, q.difficulty, q.pyq_year, q.pyq_shift, s.name as section_name
                FROM test_questions tq
                JOIN questions q ON tq.question_id = q.id
                LEFT JOIN pattern_sections ps ON tq.section_id = ps.id
                LEFT JOIN subjects s ON ps.subject_id = s.id
                WHERE tq.test_id = :test_id
                ORDER BY tq.question_order ASC
            ");
            $stmtQ->execute(['test_id' => $testId]);
        }
        $questions = $stmtQ->fetchAll();

        if (!empty($questions)) {
            $questionIds = array_column($questions, 'question_id');
            $ph = implode(',', array_fill(0, count($questionIds), '?'));

            // Three set-based queries instead of three queries per question.
            $transStmt = $db->prepare("SELECT question_id, language, question_text FROM question_translations WHERE question_id IN ($ph)");
            $transStmt->execute($questionIds);
            $translations = [];
            foreach ($transStmt->fetchAll() as $row) {
                $translations[$row['question_id']][] = $row;
            }

            // is_correct is deliberately excluded: the answer key must not be
            // shipped to a client that is still taking the test.
            $optStmt = $db->prepare("SELECT id, question_id, option_key, language, option_text FROM question_options WHERE question_id IN ($ph) ORDER BY option_key ASC");
            $optStmt->execute($questionIds);
            $options = [];
            foreach ($optStmt->fetchAll() as $row) {
                $options[$row['question_id']][] = $row;
            }

            $stateStmt = $db->prepare("SELECT question_id, selected_option_key, numerical_answer, is_marked_for_review, time_spent_seconds FROM attempt_answers WHERE attempt_id = ?");
            $stateStmt->execute([$attemptId]);
            $states = [];
            foreach ($stateStmt->fetchAll() as $row) {
                $states[$row['question_id']] = $row;
            }

            foreach ($questions as &$q) {
                $qId = $q['question_id'];
                $q['translations'] = $translations[$qId] ?? [];
                $q['user_state']   = $states[$qId] ?? null;

                $opts = $options[$qId] ?? [];
                // Re-order options into the sequence stored for this attempt so
                // a resumed test looks identical to how the candidate left it.
                if (!empty($q['option_order'])) {
                    $wanted = explode(',', $q['option_order']);
                    $byKey = [];
                    foreach ($opts as $o) $byKey[$o['option_key']][] = $o;
                    $ordered = [];
                    foreach ($wanted as $key) {
                        foreach ($byKey[$key] ?? [] as $o) $ordered[] = $o;
                        unset($byKey[$key]);
                    }
                    foreach ($byKey as $rest) foreach ($rest as $o) $ordered[] = $o;
                    $opts = $ordered;
                }
                $q['options'] = $opts;
                unset($q['option_order']);
            }
            unset($q);
        }

        $test['remaining_seconds'] = $remainingSeconds;

        Response::json([
            'attempt_id' => intval($attemptId),
            'remaining_seconds' => $remainingSeconds,
            'test' => $test,
            'questions' => $questions
        ], 'Attempt started/resumed successfully');
    }

    /**
     * Returns the paper for an attempt that already exists.
     * Used by custom practice tests, which are assembled before the player opens.
     */
    public static function getAttemptPaper($attemptId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();
        $attempt = self::requireOwnedAttempt($db, $attemptId, $userId);

        $stmt = $db->prepare("
            SELECT aq.question_id, aq.question_order, aq.positive_marks, aq.negative_marks, aq.section_id,
                   aq.option_order, q.question_type, q.difficulty, s.name AS section_name
            FROM attempt_questions aq
            JOIN questions q ON aq.question_id = q.id
            LEFT JOIN subjects s ON q.subject_id = s.id
            WHERE aq.attempt_id = ?
            ORDER BY aq.question_order ASC
        ");
        $stmt->execute([$attemptId]);
        $questions = $stmt->fetchAll();

        if ($questions) {
            $ids = array_column($questions, 'question_id');
            $ph  = implode(',', array_fill(0, count($ids), '?'));

            $tr = $db->prepare("SELECT question_id, language, question_text FROM question_translations WHERE question_id IN ($ph)");
            $tr->execute($ids);
            $translations = [];
            foreach ($tr->fetchAll() as $r) $translations[$r['question_id']][] = $r;

            // is_correct is withheld while the test is live.
            $op = $db->prepare("SELECT id, question_id, option_key, language, option_text FROM question_options WHERE question_id IN ($ph) ORDER BY option_key");
            $op->execute($ids);
            $options = [];
            foreach ($op->fetchAll() as $r) $options[$r['question_id']][] = $r;

            $st = $db->prepare("SELECT question_id, selected_option_key, numerical_answer, is_marked_for_review, time_spent_seconds FROM attempt_answers WHERE attempt_id = ?");
            $st->execute([$attemptId]);
            $states = [];
            foreach ($st->fetchAll() as $r) $states[$r['question_id']] = $r;

            foreach ($questions as &$q) {
                $qId = $q['question_id'];
                $q['translations'] = $translations[$qId] ?? [];
                $q['user_state']   = $states[$qId] ?? null;

                $opts = $options[$qId] ?? [];
                if (!empty($q['option_order'])) {
                    $wanted = explode(',', $q['option_order']);
                    $byKey = [];
                    foreach ($opts as $o) $byKey[$o['option_key']][] = $o;
                    $ordered = [];
                    foreach ($wanted as $key) {
                        foreach ($byKey[$key] ?? [] as $o) $ordered[] = $o;
                        unset($byKey[$key]);
                    }
                    foreach ($byKey as $rest) foreach ($rest as $o) $ordered[] = $o;
                    $opts = $ordered;
                }
                $q['options'] = $opts;
                unset($q['option_order']);
            }
            unset($q);
        }

        Response::json([
            'attempt_id' => (int)$attemptId,
            'questions'  => $questions,
            'test'       => ['title' => 'Custom Practice'],
        ], 'Attempt paper loaded');
    }

    /**
     * Loads an attempt that belongs to the caller, or terminates.
     * $requireOpen rejects attempts that have already been finalised.
     */
    private static function requireOwnedAttempt($db, $attemptId, $userId, $requireOpen = true) {
        $stmt = $db->prepare("
            SELECT att.*, t.exam_id
            FROM test_attempts att
            JOIN tests t ON att.test_id = t.id
            WHERE att.id = :id AND att.user_id = :user_id
        ");
        $stmt->execute(['id' => $attemptId, 'user_id' => $userId]);
        $attempt = $stmt->fetch();

        if (!$attempt) Response::error('Attempt record not found', 404);
        if ($requireOpen && $attempt['status'] !== 'in_progress') {
            Response::error('This attempt has already been submitted', 409);
        }
        return $attempt;
    }

    /**
     * Upserts one answer row. Assumes the attempt has already been
     * ownership-checked by the caller.
     */
    private static function persistAnswer($db, $attempt, $questionId, $optionKey, $numerical, $isMarked, $timeSpent) {
        // The question must be on this attempt's paper. For a randomised
        // attempt that is attempt_questions; for a fixed one, test_questions.
        if (($attempt['assembly_mode'] ?? 'fixed') === 'randomised') {
            $check = $db->prepare("SELECT 1 FROM attempt_questions WHERE attempt_id = :att_id AND question_id = :q_id");
            $check->execute(['att_id' => $attempt['id'], 'q_id' => $questionId]);
        } else {
            $check = $db->prepare("SELECT 1 FROM test_questions WHERE test_id = :test_id AND question_id = :q_id");
            $check->execute(['test_id' => $attempt['test_id'], 'q_id' => $questionId]);
        }
        if (!$check->fetchColumn()) return false;

        $isAnswered = (($optionKey !== null && $optionKey !== '') || ($numerical !== null && $numerical !== '')) ? 1 : 0;

        $stmt = $db->prepare("
            INSERT INTO attempt_answers (attempt_id, question_id, selected_option_key, numerical_answer, is_marked_for_review, is_answered, time_spent_seconds)
            VALUES (:att_id, :q_id, :opt, :num, :marked, :ans, :time_spent)
            ON DUPLICATE KEY UPDATE
                selected_option_key = VALUES(selected_option_key),
                numerical_answer = VALUES(numerical_answer),
                is_marked_for_review = VALUES(is_marked_for_review),
                is_answered = VALUES(is_answered),
                time_spent_seconds = time_spent_seconds + VALUES(time_spent_seconds)
        ");
        $stmt->execute([
            'att_id'     => $attempt['id'],
            'q_id'       => $questionId,
            'opt'        => ($optionKey === '' ? null : $optionKey),
            'num'        => ($numerical === '' ? null : $numerical),
            'marked'     => $isMarked,
            'ans'        => $isAnswered,
            'time_spent' => max(0, $timeSpent),
        ]);
        return true;
    }

    public static function saveAnswerState($attemptId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $db = Database::getConnection();
        $attempt = self::requireOwnedAttempt($db, $attemptId, $userId);

        // Accept either a single answer or a batch under 'responses'.
        $batch = [];
        if (isset($input['responses']) && is_array($input['responses'])) {
            $batch = $input['responses'];
        } else {
            $batch = [$input];
        }

        $saved = 0;
        foreach ($batch as $row) {
            if (!is_array($row)) continue;
            $questionId = isset($row['question_id']) ? intval($row['question_id']) : 0;
            if (!$questionId) continue;

            $optionKey = isset($row['selected_option_key']) ? trim((string)$row['selected_option_key'])
                       : (isset($row['selected_option']) ? trim((string)$row['selected_option']) : null);
            $numerical = isset($row['numerical_answer']) ? trim((string)$row['numerical_answer']) : null;
            $isMarked  = !empty($row['is_marked_for_review']) || !empty($row['is_marked_review']) ? 1 : 0;
            $timeSpent = isset($row['time_spent_seconds']) ? intval($row['time_spent_seconds']) : 0;

            if (self::persistAnswer($db, $attempt, $questionId, $optionKey, $numerical, $isMarked, $timeSpent)) {
                $saved++;
            }
        }

        if ($saved === 0) Response::error('No valid answers for this attempt', 422);

        Response::json(['saved' => $saved], 'Answer state autosaved');
    }

    public static function submitAttempt($attemptId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();

        // 1. Load the attempt (ownership enforced), allowing an already-final one
        //    through so we can report idempotently rather than 404.
        $attempt = self::requireOwnedAttempt($db, $attemptId, $userId, false);

        if ($attempt['status'] === 'submitted' || $attempt['status'] === 'evaluated') {
            Response::json([
                'attempt_id'   => intval($attemptId),
                'score'        => floatval($attempt['score']),
                'accuracy'     => floatval($attempt['accuracy_percentage']),
                'central_rank' => intval($attempt['central_rank']),
                'state_rank'   => intval($attempt['state_rank']),
                'percentile'   => floatval($attempt['percentile']),
            ], 'Attempt already finalized');
        }

        // 2. Persist any answers the client is submitting alongside the request.
        //    The app keeps answers in memory and flushes them here; without this
        //    the attempt would be scored against an empty answer table.
        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        if (isset($input['responses']) && is_array($input['responses'])) {
            foreach ($input['responses'] as $row) {
                if (!is_array($row)) continue;
                $qId = isset($row['question_id']) ? intval($row['question_id']) : 0;
                if (!$qId) continue;

                $optionKey = isset($row['selected_option_key']) ? trim((string)$row['selected_option_key'])
                           : (isset($row['selected_option']) ? trim((string)$row['selected_option']) : null);
                $numerical = isset($row['numerical_answer']) ? trim((string)$row['numerical_answer']) : null;
                $isMarked  = !empty($row['is_marked_for_review']) || !empty($row['is_marked_review']) ? 1 : 0;
                $timeSpent = isset($row['time_spent_seconds']) ? intval($row['time_spent_seconds']) : 0;

                self::persistAnswer($db, $attempt, $qId, $optionKey, $numerical, $isMarked, $timeSpent);
            }
        }

        // 3. Fetch the test blueprint and the answer key in two queries rather
        //    than one query per question.
        if (($attempt['assembly_mode'] ?? 'fixed') === 'randomised') {
            $stmtTQ = $db->prepare("
                SELECT aq.question_id, aq.positive_marks, aq.negative_marks, q.question_type
                FROM attempt_questions aq
                JOIN questions q ON aq.question_id = q.id
                WHERE aq.attempt_id = :att_id
            ");
            $stmtTQ->execute(['att_id' => $attemptId]);
        } else {
            $stmtTQ = $db->prepare("
                SELECT tq.question_id, tq.positive_marks, tq.negative_marks, q.question_type
                FROM test_questions tq
                JOIN questions q ON tq.question_id = q.id
                WHERE tq.test_id = :test_id
            ");
            $stmtTQ->execute(['test_id' => $attempt['test_id']]);
        }
        $testQuestions = $stmtTQ->fetchAll();

        if (empty($testQuestions)) {
            Response::error('This test has no questions assigned', 409);
        }

        $questionIds = array_column($testQuestions, 'question_id');
        $placeholders = implode(',', array_fill(0, count($questionIds), '?'));

        // Answer key: a question may legitimately have multiple correct options.
        $keyStmt = $db->prepare("
            SELECT question_id, option_key, option_text
            FROM question_options
            WHERE is_correct = 1 AND question_id IN ($placeholders)
        ");
        $keyStmt->execute($questionIds);
        $answerKey = [];
        foreach ($keyStmt->fetchAll() as $row) {
            $answerKey[$row['question_id']][] = $row;
        }

        $ansStmt = $db->prepare("SELECT * FROM attempt_answers WHERE attempt_id = ?");
        $ansStmt->execute([$attemptId]);
        $userAnswers = [];
        foreach ($ansStmt->fetchAll() as $row) {
            $userAnswers[$row['question_id']] = $row;
        }

        // 4. Score.
        $totalScore = 0.00;
        $correctCount = 0;
        $wrongCount = 0;
        $unattemptedCount = 0;
        $totalTimeSpent = 0;
        $wrongQuestionIds = [];

        $markCorrect = $db->prepare("UPDATE attempt_answers SET is_correct = 1, marks_awarded = :m WHERE id = :id");
        $markWrong   = $db->prepare("UPDATE attempt_answers SET is_correct = 0, marks_awarded = :m WHERE id = :id");

        foreach ($testQuestions as $tq) {
            $qId = $tq['question_id'];
            $posMarks = floatval($tq['positive_marks']);
            $negMarks = abs(floatval($tq['negative_marks']));
            $userAns = $userAnswers[$qId] ?? null;

            if (!$userAns || !$userAns['is_answered']) {
                $unattemptedCount++;
                continue;
            }

            $totalTimeSpent += intval($userAns['time_spent_seconds']);
            $isCorrect = self::isAnswerCorrect($tq['question_type'], $userAns, $answerKey[$qId] ?? []);

            if ($isCorrect) {
                $correctCount++;
                $totalScore += $posMarks;
                $markCorrect->execute(['m' => $posMarks, 'id' => $userAns['id']]);
            } else {
                $wrongCount++;
                $totalScore -= $negMarks;
                $wrongQuestionIds[] = $qId;
                $markWrong->execute(['m' => -$negMarks, 'id' => $userAns['id']]);
            }
        }

        $attemptedTotal = $correctCount + $wrongCount;
        $accuracy = $attemptedTotal > 0 ? round(($correctCount / $attemptedTotal) * 100, 2) : 0.00;

        // 5. Finalise the attempt first, then derive ranks so this attempt is
        //    counted in its own cohort.
        $stmtFinal = $db->prepare("
            UPDATE test_attempts
            SET status = 'evaluated',
                score = :score,
                accuracy_percentage = :accuracy,
                total_time_spent_seconds = :time_spent,
                correct_count = :correct,
                wrong_count = :wrong,
                unattempted_count = :unattempted,
                submitted_at = NOW()
            WHERE id = :id
        ");
        $stmtFinal->execute([
            'score' => $totalScore,
            'accuracy' => $accuracy,
            'time_spent' => $totalTimeSpent,
            'correct' => $correctCount,
            'wrong' => $wrongCount,
            'unattempted' => $unattemptedCount,
            'id' => $attemptId,
        ]);

        list($centralRank, $stateRank, $percentile) = self::computeRanks($db, $attempt['test_id'], $attemptId, $userId);

        $db->prepare("UPDATE test_attempts SET central_rank = :c, state_rank = :s, percentile = :p WHERE id = :id")
           ->execute(['c' => $centralRank, 's' => $stateRank, 'p' => $percentile, 'id' => $attemptId]);

        // 6. Feed the wrong-answer notebook so the revision screens have data.
        self::recordWrongQuestions($db, $userId, $attemptId, $wrongQuestionIds, $userAnswers, $answerKey);

        // 7. Lost-marks breakdown, expressed in this test's own mark scale.
        self::writeLostMarksAnalysis($db, $attemptId, $testQuestions, $wrongCount);

        // 8. Readiness snapshot, scored against the test's maximum obtainable marks.
        $maxObtainable = 0.0;
        foreach ($testQuestions as $tq) $maxObtainable += floatval($tq['positive_marks']);
        self::upsertExamTwin($db, $userId, $attempt['exam_id'], $totalScore, $maxObtainable, $accuracy,
                             $correctCount, count($testQuestions), $totalTimeSpent);

        Response::json([
            'attempt_id' => intval($attemptId),
            'score' => round($totalScore, 2),
            'max_score' => round($maxObtainable, 2),
            'accuracy' => $accuracy,
            'correct_count' => $correctCount,
            'wrong_count' => $wrongCount,
            'unattempted_count' => $unattemptedCount,
            'central_rank' => $centralRank,
            'state_rank' => $stateRank,
            'percentile' => $percentile,
        ], 'Test attempt evaluated and submitted successfully');
    }

    /**
     * Compares a stored response against the answer key.
     * Handles MCQ (single key), MSQ (set of keys) and numerical questions.
     */
    private static function isAnswerCorrect($questionType, $userAns, $correctOptions) {
        $type = strtoupper((string)$questionType);

        if ($type === 'NUMERICAL' || $type === 'NAT') {
            $given = $userAns['numerical_answer'];
            if ($given === null || $given === '') return false;
            foreach ($correctOptions as $opt) {
                $expected = $opt['option_text'];
                if ($expected === null || $expected === '') continue;
                if (is_numeric($given) && is_numeric($expected)) {
                    // Tolerance covers stored values like "12.50" vs "12.5".
                    if (abs(floatval($given) - floatval($expected)) < 0.0001) return true;
                } elseif (strcasecmp(trim($given), trim($expected)) === 0) {
                    return true;
                }
            }
            return false;
        }

        $selected = $userAns['selected_option_key'];
        if ($selected === null || $selected === '') return false;

        $correctKeys = array_map(function ($o) { return strtoupper(trim($o['option_key'])); }, $correctOptions);
        if (empty($correctKeys)) return false;

        if ($type === 'MSQ' || $type === 'MULTI') {
            // Multi-select answers are stored as a comma-separated key list.
            $given = array_filter(array_map(function ($k) { return strtoupper(trim($k)); }, explode(',', $selected)));
            sort($given);
            sort($correctKeys);
            return $given === $correctKeys;
        }

        return in_array(strtoupper(trim($selected)), $correctKeys, true);
    }

    /** Central rank, state rank and percentile for a freshly evaluated attempt. */
    private static function computeRanks($db, $testId, $attemptId, $userId) {
        // Rank by score, breaking ties on accuracy then elapsed time, matching
        // the tie-break rule advertised by the leaderboard endpoint.
        $stmtSelf = $db->prepare("SELECT score, accuracy_percentage, total_time_spent_seconds FROM test_attempts WHERE id = ?");
        $stmtSelf->execute([$attemptId]);
        $self = $stmtSelf->fetch();

        $betterSql = "
            att.status = 'evaluated' AND att.test_id = :test_id AND att.id <> :attempt_id AND (
                att.score > :score
                OR (att.score = :score2 AND att.accuracy_percentage > :acc)
                OR (att.score = :score3 AND att.accuracy_percentage = :acc2 AND att.total_time_spent_seconds < :time)
            )";
        $rankParams = [
            'test_id' => $testId,
            'attempt_id' => $attemptId,
            'score' => $self['score'], 'score2' => $self['score'], 'score3' => $self['score'],
            'acc' => $self['accuracy_percentage'], 'acc2' => $self['accuracy_percentage'],
            'time' => $self['total_time_spent_seconds'],
        ];

        $stmtRank = $db->prepare("SELECT COUNT(*) + 1 FROM test_attempts att WHERE $betterSql");
        $stmtRank->execute($rankParams);
        $centralRank = intval($stmtRank->fetchColumn());

        $stmtUser = $db->prepare("SELECT state_id FROM users WHERE id = ?");
        $stmtUser->execute([$userId]);
        $userStateId = $stmtUser->fetchColumn();

        $stateRank = null;
        if ($userStateId) {
            $stmtStateRank = $db->prepare("
                SELECT COUNT(*) + 1 FROM test_attempts att
                JOIN users u ON att.user_id = u.id
                WHERE $betterSql AND u.state_id = :sid
            ");
            $stmtStateRank->execute($rankParams + ['sid' => $userStateId]);
            $stateRank = intval($stmtStateRank->fetchColumn());
        }

        $stmtTotal = $db->prepare("SELECT COUNT(*) FROM test_attempts WHERE test_id = ? AND status = 'evaluated'");
        $stmtTotal->execute([$testId]);
        $totalEvaluated = intval($stmtTotal->fetchColumn());

        // Percentile = share of the cohort this attempt beat.
        $percentile = $totalEvaluated > 1
            ? round((($totalEvaluated - $centralRank) / ($totalEvaluated - 1)) * 100, 2)
            : 100.00;

        return [$centralRank, $stateRank, $percentile];
    }

    /** Mirrors wrong answers into the revision tables the profile screens read. */
    private static function recordWrongQuestions($db, $userId, $attemptId, $wrongQuestionIds, $userAnswers, $answerKey) {
        if (empty($wrongQuestionIds)) return;

        // Column names here must match the schema exactly: user_selected_key / correct_key.
        $wrongStmt = $db->prepare("
            INSERT INTO user_wrong_questions (user_id, attempt_id, question_id, user_selected_key, correct_key)
            VALUES (:uid, :aid, :qid, :sel, :cor)
            ON DUPLICATE KEY UPDATE user_selected_key = VALUES(user_selected_key), correct_key = VALUES(correct_key)
        ");
        $noteStmt = $db->prepare("
            INSERT INTO mistake_notebook (user_id, question_id, user_answer, correct_answer)
            VALUES (:uid, :qid, :uans, :cans)
            ON DUPLICATE KEY UPDATE user_answer = VALUES(user_answer), correct_answer = VALUES(correct_answer)
        ");

        foreach ($wrongQuestionIds as $qId) {
            $selected = $userAnswers[$qId]['selected_option_key'] ?? ($userAnswers[$qId]['numerical_answer'] ?? '');
            $correctKeys = array_map(function ($o) { return $o['option_key']; }, $answerKey[$qId] ?? []);
            $correct = implode(',', $correctKeys);

            // Separate try blocks: a failure writing one revision table must not
            // silently skip the other.
            try {
                $wrongStmt->execute(['uid' => $userId, 'aid' => $attemptId, 'qid' => $qId, 'sel' => $selected, 'cor' => $correct]);
            } catch (PDOException $e) {
                error_log('EXAMVERSE user_wrong_questions write failed for question ' . $qId . ': ' . $e->getMessage());
            }
            try {
                $noteStmt->execute(['uid' => $userId, 'qid' => $qId, 'uans' => $selected, 'cans' => $correct]);
            } catch (PDOException $e) {
                error_log('EXAMVERSE mistake_notebook write failed for question ' . $qId . ': ' . $e->getMessage());
            }
        }
    }

    /** Heuristic split of lost marks, scaled to the test's own negative marking. */
    private static function writeLostMarksAnalysis($db, $attemptId, $testQuestions, $wrongCount) {
        $avgPositive = 0.0;
        foreach ($testQuestions as $tq) $avgPositive += floatval($tq['positive_marks']);
        $avgPositive = count($testQuestions) > 0 ? $avgPositive / count($testQuestions) : 2.0;

        $lostPerWrong   = $avgPositive;
        $conceptGap     = round($wrongCount * 0.60 * $lostPerWrong, 2);
        $sillyMistake   = round($wrongCount * 0.25 * $lostPerWrong, 2);
        $timePressure   = round($wrongCount * 0.15 * $lostPerWrong, 2);
        $recoverable    = round($conceptGap + $sillyMistake + $timePressure, 2);

        $advice = $wrongCount === 0
            ? 'No incorrect answers in this attempt. Focus next on raising attempt volume within the time limit.'
            : 'Revisit the concepts behind your incorrect answers first, then re-attempt them from the Mistake Notebook.';

        $db->prepare("
            INSERT INTO lost_marks_analyses (attempt_id, concept_gap_marks, silly_mistake_marks, time_pressure_marks, recoverable_marks_estimate, actionable_advice)
            VALUES (:att_id, :cg, :sm, :tp, :rec, :advice)
        ")->execute([
            'att_id' => $attemptId,
            'cg' => $conceptGap, 'sm' => $sillyMistake, 'tp' => $timePressure,
            'rec' => $recoverable, 'advice' => $advice,
        ]);
    }

    /** Readiness snapshot for the AI Exam Twin, keyed on (user_id, exam_id). */
    private static function upsertExamTwin($db, $userId, $examId, $totalScore, $maxObtainable, $accuracy, $correctCount, $questionCount, $totalTimeSpent) {
        $avgTimePerQ = $questionCount > 0 ? ($totalTimeSpent / $questionCount) : 60;
        $speedScore = round(min(100.0, max(20.0, 100 - ($avgTimePerQ > 60 ? ($avgTimePerQ - 60) * 0.8 : 0))), 2);
        $consistencyScore = round(min(100.0, max(20.0, ($accuracy * 0.7) + (($correctCount / max(1, $questionCount)) * 30))), 2);

        // Readiness is score as a share of the marks actually on offer.
        $overallReadiness = $maxObtainable > 0
            ? round(min(100.0, max(0.0, ($totalScore / $maxObtainable) * 100)), 2)
            : 0.00;

        $db->prepare("
            INSERT INTO exam_twin_snapshots (user_id, exam_id, knowledge_score, accuracy_score, speed_score, consistency_score, overall_readiness, estimated_score_min, estimated_score_max, target_benchmark, diagnosis_summary, recommended_route)
            VALUES (:uid, :eid, :k, :acc, :sp, :cs, :readiness, :min_s, :max_s, :bench, :diag, :route)
            ON DUPLICATE KEY UPDATE
                knowledge_score = VALUES(knowledge_score),
                accuracy_score = VALUES(accuracy_score),
                speed_score = VALUES(speed_score),
                consistency_score = VALUES(consistency_score),
                overall_readiness = VALUES(overall_readiness),
                estimated_score_min = VALUES(estimated_score_min),
                estimated_score_max = VALUES(estimated_score_max),
                diagnosis_summary = VALUES(diagnosis_summary)
        ")->execute([
            'uid' => $userId,
            'eid' => $examId,
            'k' => round($accuracy * 0.9, 2),
            'acc' => $accuracy,
            'sp' => $speedScore,
            'cs' => $consistencyScore,
            'readiness' => $overallReadiness,
            'min_s' => max(0, intval(floor($totalScore * 0.9))),
            'max_s' => intval(ceil(min($maxObtainable ?: $totalScore + 25, $totalScore * 1.15 + 10))),
            'bench' => intval(round($maxObtainable * 0.8)),
            'diag' => sprintf('Accuracy %.2f%% across %d questions, %d correct.', $accuracy, $questionCount, $correctCount),
            'route' => '1. Clear the Mistake Notebook -> 2. Re-attempt weak sections -> 3. Complete the Daily Mission',
        ]);
    }
}
