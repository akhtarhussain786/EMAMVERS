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

        if (!$result) Response::error('Result record not found', 404);

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
        if (!$stmtAtt->fetch()) Response::error('Attempt not found', 404);

        $stmt = $db->prepare("
            SELECT tq.question_order, tq.positive_marks, tq.negative_marks,
                   q.id as question_id, q.question_type, q.difficulty, q.pyq_year, q.pyq_shift,
                   qt.question_text, qt.solution_text, qt.shortcut_text,
                   aa.selected_option_key, aa.numerical_answer, aa.is_correct, aa.marks_awarded, aa.time_spent_seconds, aa.is_marked_for_review
            FROM attempt_answers aa
            JOIN questions q ON aa.question_id = q.id
            JOIN test_questions tq ON q.id = tq.question_id AND tq.test_id = (SELECT test_id FROM test_attempts WHERE id = :att_id)
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            WHERE aa.attempt_id = :att_id
            ORDER BY tq.question_order ASC
        ");
        $stmt->execute(['att_id' => $attemptId]);
        $solutions = $stmt->fetchAll();

        foreach ($solutions as &$sol) {
            $stmtOpts = $db->prepare("SELECT id, option_key, option_text, is_correct FROM question_options WHERE question_id = :q_id AND language = 'en'");
            $stmtOpts->execute(['q_id' => $sol['question_id']]);
            $sol['options'] = $stmtOpts->fetchAll();
        }

        Response::json($solutions, 'Solutions loaded successfully');
    }
}
