<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class ChallengeController {
    public static function getChallenges() {
        $db = Database::getConnection();
        $challenges = $db->query("
            SELECT mc.*, e.title as exam_title, e.slug as exam_slug, t.id as test_id, t.title as test_title,
                   (SELECT COUNT(*) FROM challenge_registrations cr WHERE cr.challenge_id = mc.id) as total_registered
            FROM monthly_challenges mc
            JOIN exams e ON mc.exam_id = e.id
            JOIN tests t ON mc.test_id = t.id
            ORDER BY mc.id DESC
        ")->fetchAll();

        Response::json($challenges, 'Monthly challenges loaded');
    }

    public static function registerForChallenge($challengeId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();
        $stmt = $db->prepare("
            INSERT INTO challenge_registrations (challenge_id, user_id) 
            VALUES (:cid, :uid)
            ON DUPLICATE KEY UPDATE registered_at = CURRENT_TIMESTAMP
        ");
        $stmt->execute(['cid' => $challengeId, 'uid' => $userId]);

        Response::json(['registered' => true], 'Successfully registered for Monthly Challenge');
    }

    public static function getLeaderboard($context = 'central') {
        $db = Database::getConnection();
        $stateId = isset($_GET['state_id']) ? intval($_GET['state_id']) : null;
        $testId = isset($_GET['test_id']) ? intval($_GET['test_id']) : 3; // Default National Challenge test

        if ($context === 'state' && $stateId) {
            $stmt = $db->prepare("
                SELECT att.id as attempt_id, att.score, att.accuracy_percentage, att.total_time_spent_seconds, att.state_rank as `rank`,
                       u.full_name, s.name as state_name, q.name as qualification_name
                FROM test_attempts att
                JOIN users u ON att.user_id = u.id
                LEFT JOIN states s ON u.state_id = s.id
                LEFT JOIN qualifications q ON u.qualification_id = q.id
                WHERE att.test_id = :test_id AND att.status = 'evaluated' AND u.state_id = :state_id
                ORDER BY att.score DESC, att.accuracy_percentage DESC, att.total_time_spent_seconds ASC
                LIMIT 50
            ");
            $stmt->execute(['test_id' => $testId, 'state_id' => $stateId]);
        } else {
            $stmt = $db->prepare("
                SELECT att.id as attempt_id, att.score, att.accuracy_percentage, att.total_time_spent_seconds, att.central_rank as `rank`,
                       u.full_name, s.name as state_name, q.name as qualification_name
                FROM test_attempts att
                JOIN users u ON att.user_id = u.id
                LEFT JOIN states s ON u.state_id = s.id
                LEFT JOIN qualifications q ON u.qualification_id = q.id
                WHERE att.test_id = :test_id AND att.status = 'evaluated'
                ORDER BY att.score DESC, att.accuracy_percentage DESC, att.total_time_spent_seconds ASC
                LIMIT 50
            ");
            $stmt->execute(['test_id' => $testId]);
        }

        $leaderboard = $stmt->fetchAll();
        Response::json([
            'context' => $context,
            'leaderboard' => $leaderboard,
            'tie_break_rule' => '1. Score DESC, 2. Accuracy DESC, 3. Negative Marks ASC, 4. Time Spent ASC'
        ], 'Leaderboard loaded successfully');
    }
}
