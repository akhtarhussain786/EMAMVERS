<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class ResultController {
    public static function getResultSummary($attemptId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT att.*, t.title as test_title, t.test_type, e.title as exam_title,
                   u.full_name, s.name as state_name
            FROM test_attempts att
            JOIN tests t ON att.test_id = t.id
            JOIN exams e ON t.exam_id = e.id
            JOIN users u ON att.user_id = u.id
            LEFT JOIN states s ON u.state_id = s.id
            WHERE att.id = :id AND att.user_id = :user_id
        ");
        $stmt->execute(['id' => $attemptId, 'user_id' => $userId]);
        $result = $stmt->fetch();

        if (!$result) {
            $stmtLatest = $db->prepare("
                SELECT att.*, t.title as test_title, t.test_type, e.title as exam_title,
                       u.full_name, s.name as state_name
                FROM test_attempts att
                JOIN tests t ON att.test_id = t.id
                JOIN exams e ON t.exam_id = e.id
                JOIN users u ON att.user_id = u.id
                LEFT JOIN states s ON u.state_id = s.id
                WHERE att.user_id = :user_id AND att.status = 'evaluated'
                ORDER BY att.id DESC LIMIT 1
            ");
            $stmtLatest->execute(['user_id' => $userId]);
            $result = $stmtLatest->fetch();
            if ($result) {
                $attemptId = $result['id'];
            }
        }

        if (!$result) Response::error('Result record not found', 404);

        // Always recompute dynamic cohort ranks so when any candidate looks at their
        // scorecard, ranks reflect all attempts completed to date.
        require_once __DIR__ . '/TestEngineController.php';
        TestEngineController::recomputeRanksForTest($db, $result['test_id']);

        // Refresh attempt row with dynamic ranks
        $stmtRefresh = $db->prepare("
            SELECT att.*, t.title as test_title, t.test_type, e.title as exam_title,
                   u.full_name, s.name as state_name
            FROM test_attempts att
            JOIN tests t ON att.test_id = t.id
            JOIN exams e ON t.exam_id = e.id
            JOIN users u ON att.user_id = u.id
            LEFT JOIN states s ON u.state_id = s.id
            WHERE att.id = :id
        ");
        $stmtRefresh->execute(['id' => $attemptId]);
        $result = $stmtRefresh->fetch() ?: $result;

        // Calculate maximum obtainable marks for this test
        $stmtMax = $db->prepare("SELECT COALESCE(SUM(positive_marks), 0) FROM test_questions WHERE test_id = ?");
        $stmtMax->execute([$result['test_id']]);
        $maxScore = floatval($stmtMax->fetchColumn());
        if ($maxScore <= 0) $maxScore = 200.00;

        // Count total evaluated candidates for this test
        $stmtCohort = $db->prepare("SELECT COUNT(*) FROM test_attempts WHERE test_id = ? AND status = 'evaluated'");
        $stmtCohort->execute([$result['test_id']]);
        $cohortSize = intval($stmtCohort->fetchColumn());

        $result['max_score'] = $maxScore;
        $result['cohort_size'] = $cohortSize;

        // Fetch Sectional breakdown
        $stmtSec = $db->prepare("
            SELECT s.name as section_name, 
                   COUNT(aa.id) as total_questions,
                   SUM(CASE WHEN aa.is_correct = 1 THEN 1 ELSE 0 END) as correct,
                   SUM(CASE WHEN aa.is_correct = 0 AND aa.is_answered = 1 THEN 1 ELSE 0 END) as wrong,
                   SUM(CASE WHEN aa.is_answered = 0 THEN 1 ELSE 0 END) as unattempted,
                   SUM(aa.marks_awarded) as section_score,
                   SUM(aa.time_spent_seconds) as section_time
            FROM attempt_answers aa
            JOIN questions q ON aa.question_id = q.id
            JOIN subjects s ON q.subject_id = s.id
            WHERE aa.attempt_id = :att_id
            GROUP BY s.id, s.name
        ");
        $stmtSec->execute(['att_id' => $attemptId]);
        $sections = $stmtSec->fetchAll();

        Response::json([
            'summary' => $result,
            'section_breakdown' => $sections
        ], 'Result summary loaded successfully');
    }

    public static function getSolutions($attemptId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();

        $stmtAtt = $db->prepare("SELECT id FROM test_attempts WHERE id = :id AND user_id = :user_id");
        $stmtAtt->execute(['id' => $attemptId, 'user_id' => $userId]);
        if (!$stmtAtt->fetch()) {
            $stmtLatest = $db->prepare("SELECT id FROM test_attempts WHERE user_id = :user_id AND status = 'evaluated' ORDER BY id DESC LIMIT 1");
            $stmtLatest->execute(['user_id' => $userId]);
            $lat = $stmtLatest->fetch();
            if ($lat) {
                $attemptId = $lat['id'];
            } else {
                Response::error('Attempt not found', 404);
            }
        }

        // Solutions must follow whichever paper the candidate actually sat: a
        // randomised attempt has its own question set and ordering.
        $modeStmt = $db->prepare("SELECT assembly_mode FROM test_attempts WHERE id = ?");
        $modeStmt->execute([$attemptId]);
        $isRandomised = $modeStmt->fetchColumn() === 'randomised';

        $orderJoin = $isRandomised
            ? "JOIN attempt_questions tq ON q.id = tq.question_id AND tq.attempt_id = :att_id_sub"
            : "JOIN test_questions tq ON q.id = tq.question_id AND tq.test_id = (SELECT test_id FROM test_attempts WHERE id = :att_id_sub)";

        $stmt = $db->prepare("
            SELECT tq.question_order, tq.positive_marks, tq.negative_marks,
                   q.id as question_id, q.question_type, q.difficulty, q.pyq_year, q.pyq_shift,
                   qte.question_text as question_text_en, qte.solution_text as solution_text_en, qte.shortcut_text as shortcut_text_en,
                   qth.question_text as question_text_hi, qth.solution_text as solution_text_hi, qth.shortcut_text as shortcut_text_hi,
                   COALESCE(qte.question_text, qth.question_text) as question_text,
                   COALESCE(qte.solution_text, qth.solution_text) as solution_text,
                   COALESCE(qte.shortcut_text, qth.shortcut_text) as shortcut_text,
                   aa.selected_option_key, aa.numerical_answer, aa.is_correct, aa.marks_awarded, aa.time_spent_seconds, aa.is_marked_for_review
            FROM attempt_answers aa
            JOIN questions q ON aa.question_id = q.id
            $orderJoin
            LEFT JOIN question_translations qte ON q.id = qte.question_id AND qte.language = 'en'
            LEFT JOIN question_translations qth ON q.id = qth.question_id AND qth.language = 'hi'
            WHERE aa.attempt_id = :att_id
            ORDER BY tq.question_order ASC
        ");
        // Native prepared statements reject a named placeholder used twice,
        // so the join gets its own name.
        $stmt->execute(['att_id_sub' => $attemptId, 'att_id' => $attemptId]);
        $solutions = $stmt->fetchAll();

        foreach ($solutions as &$sol) {
            $stmtOpts = $db->prepare("SELECT id, option_key, language, option_text, is_correct FROM question_options WHERE question_id = :q_id ORDER BY option_key ASC, language ASC");
            $stmtOpts->execute(['q_id' => $sol['question_id']]);
            $sol['options'] = $stmtOpts->fetchAll();
        }

        Response::json($solutions, 'Solutions loaded successfully');
    }
}
