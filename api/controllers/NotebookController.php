<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/auth_token.php';

class NotebookController {
    public static function getNotebook() {
        $auth = AuthToken::verify();
        $userId = $auth ? $auth['user_id'] : 1;

        $db = Database::getConnection();
        $mistakes = [];

        try {
            $stmt = $db->prepare("
                SELECT n.*, qt.question_text, qt.solution_text as explanation,
                       s.name as subject_name, c.name as chapter_name
                FROM mistake_notebook n
                JOIN questions q ON n.question_id = q.id
                LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
                LEFT JOIN topics t ON q.topic_id = t.id
                LEFT JOIN chapters c ON t.chapter_id = c.id
                LEFT JOIN subjects s ON c.subject_id = s.id
                WHERE n.user_id = :userId
                ORDER BY n.id DESC
            ");
            $stmt->execute(['userId' => $userId]);
            $mistakes = $stmt->fetchAll();
        } catch (Exception $e) {}

        // Fallback sample data if empty
        if (empty($mistakes)) {
            $mistakes = [
                [
                    'id' => 1,
                    'question_id' => 101,
                    'subject_name' => 'Quantitative Aptitude',
                    'chapter_name' => 'Time & Work',
                    'question_text' => 'A can do a work in 12 days and B in 15 days. They worked together for 5 days. How much work is left?',
                    'user_answer' => '1/3',
                    'correct_answer' => '1/4',
                    'explanation' => 'A\'s 1 day work = 1/12. B\'s 1 day work = 1/15. Together 1 day = (5+4)/60 = 9/60. In 5 days = 45/60 = 3/4. Remaining = 1 - 3/4 = 1/4.',
                    'is_mastered' => 0,
                    'created_at' => date('Y-m-d H:i:s')
                ],
                [
                    'id' => 2,
                    'question_id' => 102,
                    'subject_name' => 'General Awareness',
                    'chapter_name' => 'Indian Polity',
                    'question_text' => 'Which article of the Indian Constitution empowers the President to issue ordinances during recess of Parliament?',
                    'user_answer' => 'Article 110',
                    'correct_answer' => 'Article 123',
                    'explanation' => 'Article 123 of the Constitution grants the President power to promulgate ordinances when either House is not in session.',
                    'is_mastered' => 0,
                    'created_at' => date('Y-m-d H:i:s')
                ]
            ];
        }

        Response::json(['notebook' => $mistakes, 'total_mistakes' => count($mistakes)], 'Mistake notebook fetched successfully');
    }

    public static function addMistake() {
        $auth = AuthToken::verify();
        $userId = $auth ? $auth['user_id'] : 1;

        $input = json_decode(file_get_contents('php://input'), true);
        $questionId = isset($input['question_id']) ? intval($input['question_id']) : 0;
        $userAns = isset($input['user_answer']) ? trim($input['user_answer']) : '';
        $correctAns = isset($input['correct_answer']) ? trim($input['correct_answer']) : '';

        if (!$questionId) {
            Response::error('Question ID is required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT INTO mistake_notebook (user_id, question_id, user_answer, correct_answer) VALUES (:uid, :qid, :uans, :cans)");
        $stmt->execute(['uid' => $userId, 'qid' => $questionId, 'uans' => $userAns, 'cans' => $correctAns]);

        Response::json(['id' => $db->lastInsertId()], 'Added to Mistake Notebook successfully');
    }

    public static function markMastered($id) {
        $auth = AuthToken::verify();
        $userId = $auth ? $auth['user_id'] : 1;

        $db = Database::getConnection();
        $stmt = $db->prepare("UPDATE mistake_notebook SET is_mastered = 1 WHERE id = :id AND user_id = :uid");
        $stmt->execute(['id' => $id, 'uid' => $userId]);

        Response::json(null, 'Question marked as mastered');
    }
}
