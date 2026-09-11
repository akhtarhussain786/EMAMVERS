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

        // Ensure columns exist on live database
        try {
            $stmt = $db->prepare("
                SELECT u.id, u.full_name, u.email, u.mobile, u.state_id, u.district, u.qualification_id,
                       u.user_type, u.avatar_url, u.target_exam, u.bio, u.is_verified, u.status, u.created_at,
                       s.name as state_name, q.name as qualification_name
                FROM users u
                LEFT JOIN states s ON u.state_id = s.id
                LEFT JOIN qualifications q ON u.qualification_id = q.id
                WHERE u.id = ?
            ");
            $stmt->execute([$userId]);
            $profile = $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            // Auto-heal missing columns if necessary
            try { $db->exec("ALTER TABLE users ADD COLUMN district VARCHAR(150) NULL AFTER state_id"); } catch (Exception $ex) {}
            try { $db->exec("ALTER TABLE users ADD COLUMN target_exam VARCHAR(255) NULL AFTER avatar_url"); } catch (Exception $ex) {}
            try { $db->exec("ALTER TABLE users ADD COLUMN avatar_url VARCHAR(255) NULL AFTER user_type"); } catch (Exception $ex) {}
            try { $db->exec("ALTER TABLE users ADD COLUMN bio TEXT NULL AFTER avatar_url"); } catch (Exception $ex) {}

            $stmt = $db->prepare("
                SELECT u.id, u.full_name, u.email, u.mobile, u.state_id, u.district, u.qualification_id,
                       u.user_type, u.avatar_url, u.target_exam, u.bio, u.is_verified, u.status, u.created_at,
                       s.name as state_name, q.name as qualification_name
                FROM users u
                LEFT JOIN states s ON u.state_id = s.id
                LEFT JOIN qualifications q ON u.qualification_id = q.id
                WHERE u.id = ?
            ");
            $stmt->execute([$userId]);
            $profile = $stmt->fetch(PDO::FETCH_ASSOC);
        }

        if (!$profile) {
            Response::error('User profile not found', 404);
        }

        // Clean internal placeholder mobile
        if (!empty($profile['mobile']) && str_starts_with($profile['mobile'], 'NA-')) {
            $profile['mobile'] = '';
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
        $targetExams = $tStmt->fetchAll(PDO::FETCH_ASSOC);
        $profile['target_exams'] = $targetExams;

        if (empty($profile['target_exam']) && !empty($targetExams)) {
            $profile['target_exam'] = $targetExams[0]['exam_title'] ?? '';
        }

        Response::json($profile, 'User profile fetched');
    }

    public static function updateProfile() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $fullName = trim($input['full_name'] ?? '');
        $email = trim($input['email'] ?? '');
        $mobile = trim($input['mobile'] ?? '');
        $stateId = isset($input['state_id']) && $input['state_id'] !== '' ? intval($input['state_id']) : null;
        $district = trim($input['district'] ?? '');
        $qualificationId = isset($input['qualification_id']) && $input['qualification_id'] !== '' ? intval($input['qualification_id']) : null;
        $targetExam = trim($input['target_exam'] ?? '');
        $bio = trim($input['bio'] ?? '');
        $avatarUrl = trim($input['avatar_url'] ?? '');

        if (empty($fullName)) {
            Response::error('full_name cannot be empty', 422);
        }

        if (mb_strlen($fullName) > 150) {
            Response::error('full_name is too long', 422);
        }

        $db = Database::getConnection();

        // Check duplicate email / mobile if updating them
        if (!empty($email)) {
            $checkEmail = $db->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
            $checkEmail->execute([$email, $userId]);
            if ($checkEmail->fetch()) {
                Response::error('Another account is already registered with this email.', 409);
            }
        }

        if (!empty($mobile) && !str_starts_with($mobile, 'NA-')) {
            $checkMobile = $db->prepare("SELECT id FROM users WHERE mobile = ? AND id != ?");
            $checkMobile->execute([$mobile, $userId]);
            if ($checkMobile->fetch()) {
                Response::error('Another account is already registered with this mobile number.', 409);
            }
        }

        // Ensure columns exist on database
        try {
            $db->exec("ALTER TABLE users ADD COLUMN district VARCHAR(150) NULL AFTER state_id");
        } catch (Exception $ex) {}
        try {
            $db->exec("ALTER TABLE users ADD COLUMN target_exam VARCHAR(255) NULL AFTER avatar_url");
        } catch (Exception $ex) {}

        $fields = [
            'full_name = :name',
            'state_id = :sid',
            'district = :district',
            'qualification_id = :qid',
            'target_exam = :target_exam',
            'bio = :bio',
        ];
        $params = [
            'name' => $fullName,
            'sid' => $stateId,
            'district' => $district ?: null,
            'qid' => $qualificationId,
            'target_exam' => $targetExam ?: null,
            'bio' => $bio,
            'uid' => $userId
        ];

        if (!empty($email)) {
            $fields[] = 'email = :email';
            $params['email'] = $email;
        }
        if (!empty($mobile) && !str_starts_with($mobile, 'NA-')) {
            $fields[] = 'mobile = :mobile';
            $params['mobile'] = $mobile;
        }
        if (!empty($avatarUrl)) {
            $fields[] = 'avatar_url = :avatar';
            $params['avatar'] = $avatarUrl;
        }

        $setSql = implode(', ', $fields);
        $stmt = $db->prepare("UPDATE users SET $setSql WHERE id = :uid");
        $stmt->execute($params);

        // If target exam was provided and matches an existing exam, keep user_target_exams in sync
        if (!empty($targetExam)) {
            $exStmt = $db->prepare("SELECT id FROM exams WHERE title LIKE ? OR slug LIKE ? LIMIT 1");
            $exStmt->execute(["%$targetExam%", "%$targetExam%"]);
            $matchedExamId = $exStmt->fetchColumn();
            if ($matchedExamId) {
                $db->prepare("UPDATE user_target_exams SET is_primary = 0 WHERE user_id = ?")->execute([$userId]);
                $db->prepare("
                    INSERT INTO user_target_exams (user_id, exam_id, target_year, is_primary)
                    VALUES (?, ?, ?, 1)
                    ON DUPLICATE KEY UPDATE is_primary = 1
                ")->execute([$userId, $matchedExamId, (int)date('Y')]);
            }
        }

        Response::json([
            'updated'     => true,
            'full_name'   => $fullName,
            'email'       => $email,
            'mobile'      => $mobile,
            'state_id'    => $stateId,
            'district'    => $district,
            'qualification_id' => $qualificationId,
            'target_exam' => $targetExam,
            'avatar_url'  => $avatarUrl,
        ], 'Profile updated successfully');
    }

    public static function uploadAvatar() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = intval($user['sub'] ?? ($user['id'] ?? 0));
        if (!$userId) {
            Response::error('Unauthorized', 401);
        }

        $db = Database::getConnection();

        // Ensure upload directory exists
        $uploadDir = __DIR__ . '/../../uploads/avatars';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $avatarPath = null;
        $fileExt = 'jpg';

        // 1. Check for standard multipart file upload ($_FILES['avatar'] or $_FILES['image'])
        $fileEntry = $_FILES['avatar'] ?? ($_FILES['image'] ?? ($_FILES['file'] ?? null));
        if (!empty($fileEntry) && $fileEntry['error'] === UPLOAD_ERR_OK) {
            if ($fileEntry['size'] > 5 * 1024 * 1024) {
                Response::error('Avatar image size must be less than 5MB', 422);
            }
            $ext = strtolower(pathinfo($fileEntry['name'], PATHINFO_EXTENSION));
            if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
                $ext = 'jpg';
            }
            $filename = 'avatar_' . $userId . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
            $destination = $uploadDir . '/' . $filename;
            if (move_uploaded_file($fileEntry['tmp_name'], $destination)) {
                $avatarPath = '/uploads/avatars/' . $filename;
            } else {
                Response::error('Failed to save uploaded avatar image', 500);
            }
        } 
        // 2. Base64 payload (JSON: { "avatar_base64": "...", "extension": "jpg" })
        else {
            $input = json_decode(file_get_contents('php://input'), true);
            $base64 = $input['avatar_base64'] ?? ($input['image'] ?? ($input['data'] ?? ''));
            if ($base64) {
                if (preg_match('/^data:image\/(\w+);base64,/', $base64, $matches)) {
                    $ext = strtolower($matches[1]);
                    $base64 = substr($base64, strpos($base64, ',') + 1);
                } else {
                    $ext = strtolower($input['extension'] ?? 'jpg');
                }
                if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
                    $ext = 'jpg';
                }
                $imageData = base64_decode($base64);
                if ($imageData === false || strlen($imageData) < 10) {
                    Response::error('Invalid base64 image data', 422);
                }
                if (strlen($imageData) > 5 * 1024 * 1024) {
                    Response::error('Avatar image size must be less than 5MB', 422);
                }
                $filename = 'avatar_' . $userId . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
                $destination = $uploadDir . '/' . $filename;
                if (file_put_contents($destination, $imageData) !== false) {
                    $avatarPath = '/uploads/avatars/' . $filename;
                } else {
                    Response::error('Failed to write avatar file on server', 500);
                }
            }
        }

        if (!$avatarPath) {
            Response::error('No avatar image file or base64 data provided', 400);
        }

        // Auto-heal avatar_url column in users table
        try {
            $stmt = $db->prepare("UPDATE users SET avatar_url = ? WHERE id = ?");
            $stmt->execute([$avatarPath, $userId]);
        } catch (PDOException $e) {
            try {
                $db->exec("ALTER TABLE users ADD COLUMN avatar_url VARCHAR(255) NULL AFTER user_type");
                $stmt = $db->prepare("UPDATE users SET avatar_url = ? WHERE id = ?");
                $stmt->execute([$avatarPath, $userId]);
            } catch (Exception $ex) {}
        }

        Response::json([
            'avatar_url' => $avatarPath,
            'user_id'    => $userId,
        ], 'Profile image updated successfully');
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

        if (!empty($wrong)) {
            $questionIds = array_values(array_unique(array_column($wrong, 'question_id')));
            $ph = implode(',', array_fill(0, count($questionIds), '?'));

            $optsStmt = $db->prepare("SELECT question_id, option_key, option_text, is_correct FROM question_options WHERE question_id IN ($ph) AND language = 'en' ORDER BY option_key ASC");
            $optsStmt->execute($questionIds);

            $byQuestion = [];
            foreach ($optsStmt->fetchAll(PDO::FETCH_ASSOC) as $opt) {
                $byQuestion[$opt['question_id']][] = $opt;
            }
            foreach ($wrong as &$q) {
                $q['options'] = $byQuestion[$q['question_id']] ?? [];
            }
            unset($q);
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
