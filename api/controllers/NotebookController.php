<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class NotebookController {
    public static function getNotebook() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT n.*, 
                   qte.question_text as question_text_en, qte.solution_text as explanation_en,
                   qth.question_text as question_text_hi, qth.solution_text as explanation_hi,
                   COALESCE(qte.question_text, qth.question_text) as question_text,
                   COALESCE(qte.solution_text, qth.solution_text) as explanation,
                   s.name as subject_name, c.name as chapter_name
            FROM mistake_notebook n
            JOIN questions q ON n.question_id = q.id
            LEFT JOIN question_translations qte ON q.id = qte.question_id AND qte.language = 'en'
            LEFT JOIN question_translations qth ON q.id = qth.question_id AND qth.language = 'hi'
            LEFT JOIN topics t ON q.topic_id = t.id
            LEFT JOIN chapters c ON t.chapter_id = c.id
            LEFT JOIN subjects s ON c.subject_id = s.id
            WHERE n.user_id = :userId
            ORDER BY n.is_mastered ASC, n.id DESC
        ");
        $stmt->execute(['userId' => $userId]);
        $mistakes = $stmt->fetchAll();

        Response::json(['notebook' => $mistakes, 'total_mistakes' => count($mistakes)], 'Mistake notebook fetched successfully');
    }

    public static function addMistake() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

        $input = json_decode(file_get_contents('php://input'), true);
        $questionId = isset($input['question_id']) ? intval($input['question_id']) : 0;
        $userAns = isset($input['user_answer']) ? trim($input['user_answer']) : '';
        $correctAns = isset($input['correct_answer']) ? trim($input['correct_answer']) : '';

        if (!$questionId) {
            Response::error('Question ID is required', 400);
        }

        $db = Database::getConnection();

        $exists = $db->prepare("SELECT 1 FROM questions WHERE id = ?");
        $exists->execute([$questionId]);
        if (!$exists->fetchColumn()) Response::error('Question not found', 404);

        // Re-adding the same question updates the entry rather than duplicating it.
        $stmt = $db->prepare("
            INSERT INTO mistake_notebook (user_id, question_id, user_answer, correct_answer)
            VALUES (:uid, :qid, :uans, :cans)
            ON DUPLICATE KEY UPDATE user_answer = VALUES(user_answer), correct_answer = VALUES(correct_answer), is_mastered = 0
        ");
        $stmt->execute(['uid' => $userId, 'qid' => $questionId, 'uans' => $userAns, 'cans' => $correctAns]);

        Response::json(['id' => $db->lastInsertId()], 'Added to Mistake Notebook successfully');
    }

    public static function markMastered($id) {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

        $db = Database::getConnection();
        $stmt = $db->prepare("UPDATE mistake_notebook SET is_mastered = 1 WHERE id = :id AND user_id = :uid");
        $stmt->execute(['id' => $id, 'uid' => $userId]);

        Response::json(null, 'Question marked as mastered');
    }
}
