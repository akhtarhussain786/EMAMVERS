<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class UserController {

    // ─── USER PROFILE ─────────────────────────────────────────────────

    public static function getProfile() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT u.id, u.full_name, u.email, u.mobile, u.state_id, u.qualification_id,
                   u.user_type, u.avatar_url, u.bio, u.is_verified, u.status, u.created_at,
                   s.name as state_name, q.name as qualification_name
            FROM users u
            LEFT JOIN states s ON u.state_id = s.id
            LEFT JOIN qualifications q ON u.qualification_id = q.id
            WHERE u.id = ?
        ");
        $stmt->execute([$userId]);
        $profile = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$profile) {
            Response::error('User profile not found', 404);
        }

        // Fetch target exams
        $tStmt = $db->prepare("
            SELECT te.*, e.title as exam_title, e.slug as exam_slug, ec.name as category_name
            FROM user_target_exams te
            JOIN exams e ON te.exam_id = e.id
            JOIN exam_categories ec ON e.category_id = ec.id
            WHERE te.user_id = ?
            ORDER BY te.is_primary DESC, te.created_at DESC
        ");
        $tStmt->execute([$userId]);
        $profile['target_exams'] = $tStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json($profile, 'User profile fetched');
    }

    public static function updateProfile() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $input = json_decode(file_get_contents('php://input'), true);
        $fullName = trim($input['full_name'] ?? '');
        $stateId = isset($input['state_id']) ? intval($input['state_id']) : null;
        $qualificationId = isset($input['qualification_id']) ? intval($input['qualification_id']) : null;
        $bio = trim($input['bio'] ?? '');
        $avatarUrl = trim($input['avatar_url'] ?? '');

        if (empty($fullName)) {
            Response::error('full_name cannot be empty', 422);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("
            UPDATE users 
            SET full_name = :name, state_id = :sid, qualification_id = :qid, bio = :bio, avatar_url = :avatar
            WHERE id = :uid
        ");
        $stmt->execute([
            'name' => $fullName,
            'sid' => $stateId,
            'qid' => $qualificationId,
            'bio' => $bio,
            'avatar' => $avatarUrl,
            'uid' => $userId
        ]);

        Response::json(['updated' => true], 'Profile updated successfully');
    }

    // ─── BOOKMARKS ────────────────────────────────────────────────────

    public static function getBookmarks() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);
        $type = trim($_GET['type'] ?? '');

        $db = Database::getConnection();
        $where = ["ub.user_id = ?"];
        $params = [$userId];

        if ($type) {
            $where[] = "ub.item_type = ?";
            $params[] = $type;
        }

        $whereStr = implode(' AND ', $where);

        $stmt = $db->prepare("
            SELECT ub.*, 
                   CASE 
                     WHEN ub.item_type = 'question' THEN (SELECT question_text FROM question_translations WHERE question_id = ub.item_id AND language='en' LIMIT 1)
                     WHEN ub.item_type = 'article' THEN (SELECT title FROM current_affairs WHERE id = ub.item_id)
                     WHEN ub.item_type = 'material' THEN (SELECT title FROM study_materials WHERE id = ub.item_id)
                     WHEN ub.item_type = 'test' THEN (SELECT title FROM tests WHERE id = ub.item_id)
                   END as item_title
            FROM user_bookmarks ub
            WHERE $whereStr
            ORDER BY ub.created_at DESC
        ");
        $stmt->execute($params);
        $bookmarks = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json($bookmarks, 'User bookmarks loaded');
    }

    public static function addBookmark() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $input = json_decode(file_get_contents('php://input'), true);
        $itemType = trim($input['item_type'] ?? 'question');
        $itemId = intval($input['item_id'] ?? 0);
        $notes = trim($input['notes'] ?? '');

        if (!$itemId || !in_array($itemType, ['question', 'article', 'material', 'test'])) {
            Response::error('Invalid item_type or item_id', 422);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("
            INSERT INTO user_bookmarks (user_id, item_type, item_id, notes)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE notes = VALUES(notes), created_at = CURRENT_TIMESTAMP
        ");
        $stmt->execute([$userId, $itemType, $itemId, $notes]);

        Response::json(['bookmark_id' => $db->lastInsertId(), 'bookmarked' => true], 'Item bookmarked successfully');
    }

    public static function deleteBookmark($id) {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $db = Database::getConnection();
        $stmt = $db->prepare("DELETE FROM user_bookmarks WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $userId]);

        Response::json(['deleted' => true], 'Bookmark removed');
    }

    // ─── WRONG QUESTION NOTEBOOK ──────────────────────────────────────

    public static function getWrongQuestions() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT wq.*, qt.question_text, qt.solution_text, q.difficulty, s.name as subject_name
            FROM user_wrong_questions wq
            JOIN questions q ON wq.question_id = q.id
            JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            WHERE wq.user_id = ?
            ORDER BY wq.created_at DESC
        ");
        $stmt->execute([$userId]);
        $wrong = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($wrong as &$q) {
            $optsStmt = $db->prepare("SELECT option_key, option_text, is_correct FROM question_options WHERE question_id = ? AND language = 'en'");
            $optsStmt->execute([$q['question_id']]);
            $q['options'] = $optsStmt->fetchAll(PDO::FETCH_ASSOC);
        }

        Response::json($wrong, 'Wrong question notebook loaded');
    }

    // ─── NOTIFICATIONS ────────────────────────────────────────────────

    public static function getNotifications() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM user_notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50");
        $stmt->execute([$userId]);
        $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $unreadCount = $db->prepare("SELECT COUNT(*) FROM user_notifications WHERE user_id = ? AND is_read = 0");
        $unreadCount->execute([$userId]);

        Response::json([
            'notifications' => $notifications,
            'unread_count' => intval($unreadCount->fetchColumn())
        ], 'User notifications loaded');
    }

    public static function markNotificationRead($id) {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $db = Database::getConnection();
        $stmt = $db->prepare("UPDATE user_notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $userId]);

        Response::json(['updated' => true], 'Notification marked as read');
    }

    // ─── TARGET EXAMS ─────────────────────────────────────────────────

    public static function addTargetExam() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $input = json_decode(file_get_contents('php://input'), true);
        $examId = intval($input['exam_id'] ?? 0);
        $targetYear = intval($input['target_year'] ?? 2026);
        $isPrimary = !empty($input['is_primary']) ? 1 : 0;

        if (!$examId) Response::error('exam_id is required', 422);

        $db = Database::getConnection();

        if ($isPrimary) {
            // Unset previous primary target exam
            $db->prepare("UPDATE user_target_exams SET is_primary = 0 WHERE user_id = ?")->execute([$userId]);
        }

        $stmt = $db->prepare("
            INSERT INTO user_target_exams (user_id, exam_id, target_year, is_primary)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE target_year = VALUES(target_year), is_primary = VALUES(is_primary)
        ");
        $stmt->execute([$userId, $examId, $targetYear, $isPrimary]);

        Response::json(['target_id' => $db->lastInsertId()], 'Target exam updated successfully');
    }
}
