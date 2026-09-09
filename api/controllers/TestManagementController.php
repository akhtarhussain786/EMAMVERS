<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

/**
 * Test Management & Operations Controller (TMG).
 * PRD §8.5 - 8.12: Pre-publish validation gate, version locking,
 * live test operations, and post-exam regrade jobs.
 */
class TestManagementController {

    private static function requireAdmin() {
        AuthMiddleware::getAuthenticatedUser('admin');
    }

    /**
     * Run the mandatory pre-publish blocking validation gate (PRD §8.9).
     */
    public static function validateTest($testId) {
        self::requireAdmin();
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM tests WHERE id = ?");
        $stmt->execute([$testId]);
        $test = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$test) {
            Response::error('Test not found', 404);
        }

        // Fetch assigned questions
        $qStmt = $db->prepare("
            SELECT tq.*, q.question_text, q.correct_option, q.status AS question_status,
                   q.option_a, q.option_b, q.option_c, q.option_d, q.content_hash, q.structure_hash
            FROM test_questions tq
            JOIN questions q ON tq.question_id = q.id
            WHERE tq.test_id = ?
            ORDER BY tq.question_order ASC
        ");
        $qStmt->execute([$testId]);
        $questions = $qStmt->fetchAll(PDO::FETCH_ASSOC);

        $errors = [];
        $warnings = [];

        // Check 1: Minimum question count
        $qCount = count($questions);
        if ($qCount === 0) {
            $errors[] = 'Test has no questions assigned.';
        }

        // Check 2: Question approval status
        $unapproved = 0;
        foreach ($questions as $q) {
            if ($q['question_status'] !== 'published') {
                $unapproved++;
            }
        }
        if ($unapproved > 0) {
            $errors[] = "Test contains $unapproved questions that are not in 'published' state.";
        }

        // Check 3: Valid answer keys and options
        $invalidOptions = 0;
        foreach ($questions as $q) {
            if (empty($q['correct_option']) || !in_array(strtoupper(trim($q['correct_option'])), ['A', 'B', 'C', 'D'], true)) {
                $invalidOptions++;
            }
            if (empty(trim($q['option_a'])) || empty(trim($q['option_b']))) {
                $invalidOptions++;
            }
        }
        if ($invalidOptions > 0) {
            $errors[] = "Test contains $invalidOptions questions with missing or malformed options/answers.";
        }

        // Check 4: Duplicate content within the test
        $hashesSeen = [];
        $duplicatesInside = 0;
        foreach ($questions as $q) {
            if (!empty($q['content_hash'])) {
                if (isset($hashesSeen[$q['content_hash']])) {
                    $duplicatesInside++;
                }
                $hashesSeen[$q['content_hash']] = true;
            }
        }
        if ($duplicatesInside > 0) {
            $errors[] = "Test contains $duplicatesInside duplicate questions with identical content.";
        }

        // Check 5: Timing and marks consistency
        if ($test['duration_minutes'] <= 0) {
            $errors[] = 'Duration must be greater than 0 minutes.';
        }
        if ($test['total_marks'] <= 0) {
            $errors[] = 'Total marks must be greater than 0.';
        }

        $isValid = empty($errors);

        Response::json([
            'test_id'        => $testId,
            'is_valid'       => $isValid,
            'can_publish'    => $isValid,
            'question_count' => $qCount,
            'errors'         => $errors,
            'warnings'       => $warnings
        ], $isValid ? 'Test passed pre-publish validation checklist' : 'Test failed pre-publish validation checklist');
    }

    /**
     * Lock version and publish test (PRD §8.8 & §8.9).
     */
    public static function publishTest($testId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM tests WHERE id = ?");
        $stmt->execute([$testId]);
        $test = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$test) {
            Response::error('Test not found', 404);
        }

        // Check validation
        $qStmt = $db->prepare("
            SELECT COUNT(*) AS total,
                   SUM(CASE WHEN q.status != 'published' THEN 1 ELSE 0 END) AS unapproved
            FROM test_questions tq
            JOIN questions q ON tq.question_id = q.id
            WHERE tq.test_id = ?
        ");
        $qStmt->execute([$testId]);
        $check = $qStmt->fetch(PDO::FETCH_ASSOC);

        if (($check['total'] ?? 0) === 0 || ($check['unapproved'] ?? 0) > 0) {
            Response::error('Cannot publish test: Pre-publish validation failed. All questions must be published.', 422);
        }

        $db->beginTransaction();
        try {
            // Determine next version number
            $verStmt = $db->prepare("SELECT MAX(version_no) FROM test_versions WHERE test_id = ?");
            $verStmt->execute([$testId]);
            $maxVer = (int)$verStmt->fetchColumn();
            $newVer = $maxVer + 1;

            // Create immutable test version snapshot
            $insVer = $db->prepare("
                INSERT INTO test_versions (
                    test_id, version_no, title, instructions, duration_minutes,
                    total_marks, pass_percentage, negative_marking, validation_status,
                    is_locked, locked_at, created_by
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'valid', 1, NOW(), ?)
            ");
            $insVer->execute([
                $testId,
                $newVer,
                $test['title'],
                $test['instructions'] ?? '',
                $test['duration_minutes'],
                $test['total_marks'],
                $test['pass_percentage'],
                $test['negative_marking'],
                $adminId
            ]);
            $versionId = (int)$db->lastInsertId();

            // Set test status to published
            $upTest = $db->prepare("UPDATE tests SET status = 'published' WHERE id = ?");
            $upTest->execute([$testId]);

            // Audit
            $audit = $db->prepare("
                INSERT INTO audit_logs (admin_id, action, target_type, target_id, details)
                VALUES (?, 'TEST_PUBLISH_VERSION_LOCKED', 'tests', ?, ?)
            ");
            $audit->execute([$adminId, $testId, json_encode(['version_no' => $newVer, 'version_id' => $versionId])]);

            $db->commit();

            Response::json([
                'test_id'    => $testId,
                'version_no' => $newVer,
                'status'     => 'published'
            ], 'Test published and version locked successfully');
        } catch (Exception $e) {
            $db->rollBack();
            Response::error('Failed to publish test: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Create an audited regrade job for post-exam answer key correction (PRD §8.11).
     */
    public static function createRegradeJob($testId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $questionId = intval($input['question_id'] ?? 0);
        $oldAnswer  = trim($input['old_answer'] ?? '');
        $newAnswer  = trim($input['new_answer'] ?? '');
        $action     = in_array($input['scoring_action'] ?? '', ['change_key', 'give_bonus', 'exclude_question'], true) ? $input['scoring_action'] : 'change_key';
        $reason     = trim($input['reason'] ?? 'Official answer key correction');

        if (!$questionId || !$newAnswer) {
            Response::error('question_id and new_answer are required', 400);
        }

        // Fetch affected attempts
        $attStmt = $db->prepare("
            SELECT ta.id, ta.score, ta.correct_count, ta.wrong_count,
                   aa.id AS answer_id, aa.user_answer, aa.is_correct
            FROM test_attempts ta
            JOIN attempt_answers aa ON ta.id = aa.attempt_id
            WHERE ta.test_id = ? AND aa.question_id = ? AND ta.status IN ('submitted', 'evaluated', 'finalized')
        ");
        $attStmt->execute([$testId, $questionId]);
        $affectedRows = $attStmt->fetchAll(PDO::FETCH_ASSOC);
        $affectedCount = count($affectedRows);

        $db->beginTransaction();
        try {
            // 1. Create regrade job record
            $insJob = $db->prepare("
                INSERT INTO regrade_jobs (
                    test_id, question_id, old_answer, new_answer, scoring_action,
                    affected_attempts_count, processed_attempts_count, status, reason, created_by
                ) VALUES (?, ?, ?, ?, ?, ?, 0, 'running', ?, ?)
            ");
            $insJob->execute([$testId, $questionId, $oldAnswer, $newAnswer, $action, $affectedCount, $reason, $adminId]);
            $jobId = (int)$db->lastInsertId();

            // 2. Update question correct option
            $upQ = $db->prepare("UPDATE questions SET correct_option = ? WHERE id = ?");
            $upQ->execute([$newAnswer, $questionId]);

            // 3. Recalculate score for each attempt
            $processed = 0;
            foreach ($affectedRows as $row) {
                $userAns = trim($row['user_answer'] ?? '');
                $wasCorrect = (bool)$row['is_correct'];
                $isNowCorrect = ($action === 'give_bonus') || (strtoupper($userAns) === strtoupper($newAnswer));

                if ($wasCorrect !== $isNowCorrect) {
                    // Update attempt answer
                    $upAns = $db->prepare("UPDATE attempt_answers SET is_correct = ? WHERE id = ?");
                    $upAns->execute([$isNowCorrect ? 1 : 0, $row['answer_id']]);

                    // Recalculate total score for this attempt
                    $calcStmt = $db->prepare("
                        SELECT
                            SUM(CASE WHEN is_correct = 1 THEN positive_marks ELSE 0 END) -
                            SUM(CASE WHEN is_correct = 0 AND user_answer IS NOT NULL AND user_answer != '' THEN negative_marks ELSE 0 END) AS new_score,
                            SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS new_correct,
                            SUM(CASE WHEN is_correct = 0 AND user_answer IS NOT NULL AND user_answer != '' THEN 1 ELSE 0 END) AS new_wrong
                        FROM (
                            SELECT aa.is_correct, aa.user_answer,
                                   COALESCE(aq.positive_marks, 2.00) AS positive_marks,
                                   COALESCE(aq.negative_marks, 0.50) AS negative_marks
                            FROM attempt_answers aa
                            LEFT JOIN attempt_questions aq ON aa.attempt_id = aq.attempt_id AND aa.question_id = aq.question_id
                            WHERE aa.attempt_id = ?
                        ) AS sub
                    ");
                    $calcStmt->execute([$row['id']]);
                    $newTotals = $calcStmt->fetch(PDO::FETCH_ASSOC);

                    $upAtt = $db->prepare("
                        UPDATE test_attempts
                        SET score = ?, correct_count = ?, wrong_count = ?
                        WHERE id = ?
                    ");
                    $upAtt->execute([
                        max(0, floatval($newTotals['new_score'] ?? 0)),
                        intval($newTotals['new_correct'] ?? 0),
                        intval($newTotals['new_wrong'] ?? 0),
                        $row['id']
                    ]);
                }
                $processed++;
            }

            // 4. Mark job completed
            $finJob = $db->prepare("
                UPDATE regrade_jobs
                SET processed_attempts_count = ?, status = 'completed', completed_at = NOW()
                WHERE id = ?
            ");
            $finJob->execute([$processed, $jobId]);

            // 5. Audit
            $audit = $db->prepare("
                INSERT INTO audit_logs (admin_id, action, target_type, target_id, details)
                VALUES (?, 'TEST_REGRADE_JOB_EXECUTED', 'regrade_jobs', ?, ?)
            ");
            $audit->execute([$adminId, $jobId, json_encode([
                'test_id' => $testId,
                'question_id' => $questionId,
                'affected_attempts' => $affectedCount,
                'new_answer' => $newAnswer
            ])]);

            $db->commit();

            Response::json([
                'job_id'            => $jobId,
                'test_id'           => $testId,
                'affected_attempts' => $affectedCount,
                'status'            => 'completed'
            ], 'Regrade completed and scores updated consistently');
        } catch (Exception $e) {
            $db->rollBack();
            Response::error('Failed to run regrade job: ' . $e->getMessage(), 500);
        }
    }
}
