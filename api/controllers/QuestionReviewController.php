<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

/**
 * Admin-side review of teacher-submitted questions.
 *
 * Approving flips status from 'review' to 'published', which is the only state
 * student-facing queries draw from. Rejecting records a reason the teacher sees.
 */
class QuestionReviewController {

    /**
     * Resolves the acting admin's id from either a bearer token or a panel
     * session, and opens the DB connection only once authorised.
     */
    private static function actingAdminId(&$db) {
        $user = AuthMiddleware::getOptionalUser();
        $adminId = null;

        if ($user && in_array($user['type'], ['super_admin','content_operator','reviewer','finance_operator'], true)) {
            $adminId = $user['sub'];
        } elseif (AuthMiddleware::hasAdminPanelSession()) {
            $adminId = $_SESSION['admin_user']['id'] ?? null;
        } else {
            Response::error('Unauthorized: admin access required', 401);
        }

        $db = Database::getConnection();
        return $adminId;
    }

    /** The review queue. Defaults to questions awaiting a decision. */
    public static function listSubmissions() {
        $db = null;
        self::actingAdminId($db);

        $status    = in_array($_GET['status'] ?? '', ['review','published','rejected'], true) ? $_GET['status'] : 'review';
        $subjectId = isset($_GET['subject_id']) ? intval($_GET['subject_id']) : 0;
        $limit     = min(100, max(1, intval($_GET['limit'] ?? 50)));

        $where  = ['q.status = ?', 'q.author_user_id IS NOT NULL'];
        $params = [$status];
        if ($subjectId) { $where[] = 'q.subject_id = ?'; $params[] = $subjectId; }
        $whereSql = implode(' AND ', $where);

        $stmt = $db->prepare("
            SELECT q.id, q.status, q.difficulty, q.created_at, q.reviewed_at, q.rejection_reason,
                   qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, t.name AS topic_name,
                   u.full_name AS author_name, tp.display_name AS author_display_name,
                   tp.questions_approved, tp.questions_rejected
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN topics t ON q.topic_id = t.id
            LEFT JOIN users u ON q.author_user_id = u.id
            LEFT JOIN teacher_profiles tp ON tp.user_id = q.author_user_id
            WHERE $whereSql
            ORDER BY q.created_at ASC
            LIMIT $limit
        ");
        $stmt->execute($params);
        $rows = $stmt->fetchAll();

        if ($rows) {
            $ids = array_column($rows, 'id');
            $ph  = implode(',', array_fill(0, count($ids), '?'));
            // The reviewer must see which option is marked correct.
            $opt = $db->prepare("SELECT question_id, option_key, option_text, is_correct FROM question_options WHERE question_id IN ($ph) AND language='en' ORDER BY option_key");
            $opt->execute($ids);
            $byQ = [];
            foreach ($opt->fetchAll() as $o) $byQ[$o['question_id']][] = $o;
            foreach ($rows as &$r) $r['options'] = $byQ[$r['id']] ?? [];
            unset($r);
        }

        $pending = $db->query("SELECT COUNT(*) FROM questions WHERE status='review' AND author_user_id IS NOT NULL")->fetchColumn();

        Response::json([
            'submissions'   => $rows,
            'pending_total' => intval($pending),
            'filter'        => ['status' => $status, 'subject_id' => $subjectId ?: null],
        ], 'Question submissions loaded');
    }

    /** Approves a submission, optionally with reviewer edits applied first. */
    public static function approve($id) {
        $db = null;
        $adminId = self::actingAdminId($db);
        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $question = self::loadPending($db, $id);

        $db->beginTransaction();
        try {
            // A reviewer may correct wording or the answer key before approving.
            if (!empty($input['question_text']) || !empty($input['explanation'])) {
                $db->prepare("
                    UPDATE question_translations
                    SET question_text = COALESCE(NULLIF(?, ''), question_text),
                        solution_text = COALESCE(NULLIF(?, ''), solution_text)
                    WHERE question_id = ? AND language = 'en'
                ")->execute([trim($input['question_text'] ?? ''), trim($input['explanation'] ?? ''), $id]);
            }

            if (!empty($input['correct_option'])) {
                $key = strtoupper(trim($input['correct_option']));
                if (!in_array($key, ['A','B','C','D'], true)) {
                    $db->rollBack();
                    Response::error('correct_option must be A, B, C or D', 422);
                }
                $db->prepare("UPDATE question_options SET is_correct = (option_key = ?) WHERE question_id = ? AND language = 'en'")
                   ->execute([$key, $id]);
            }

            if (!empty($input['difficulty']) && in_array($input['difficulty'], ['easy','medium','hard'], true)) {
                $db->prepare("UPDATE questions SET difficulty = ? WHERE id = ?")->execute([$input['difficulty'], $id]);
            }

            $db->prepare("
                UPDATE questions
                SET status = 'published', reviewed_by = ?, reviewed_at = NOW(), rejection_reason = NULL
                WHERE id = ?
            ")->execute([$adminId, $id]);

            $db->prepare("UPDATE teacher_profiles SET questions_approved = questions_approved + 1 WHERE user_id = ?")
               ->execute([$question['author_user_id']]);

            self::notifyAuthor($db, $question['author_user_id'],
                'Question approved',
                'Your question has been approved and is now live for students.');

            self::audit($db, $adminId, 'APPROVE_QUESTION', $id, 'Approved teacher question #' . $id);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }

        Response::json(['question_id' => intval($id), 'status' => 'published'], 'Question approved and published');
    }

    /** Rejects a submission with a reason the teacher can act on. */
    public static function reject($id) {
        $db = null;
        $adminId = self::actingAdminId($db);
        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $reason = trim($input['reason'] ?? '');
        if ($reason === '') {
            Response::error('A rejection reason is required so the teacher can correct and resubmit', 422);
        }
        if (mb_strlen($reason) > 500) {
            Response::error('Rejection reason must be under 500 characters', 422);
        }

        $question = self::loadPending($db, $id);

        $db->beginTransaction();
        try {
            $db->prepare("
                UPDATE questions
                SET status = 'rejected', reviewed_by = ?, reviewed_at = NOW(), rejection_reason = ?
                WHERE id = ?
            ")->execute([$adminId, $reason, $id]);

            $db->prepare("UPDATE teacher_profiles SET questions_rejected = questions_rejected + 1 WHERE user_id = ?")
               ->execute([$question['author_user_id']]);

            self::notifyAuthor($db, $question['author_user_id'],
                'Question needs changes',
                'A question you submitted was not approved. Reason: ' . $reason);

            self::audit($db, $adminId, 'REJECT_QUESTION', $id, 'Rejected teacher question #' . $id . ': ' . $reason);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }

        Response::json(['question_id' => intval($id), 'status' => 'rejected'], 'Question rejected and the teacher notified');
    }

    // ─── TEACHER ACCOUNT MANAGEMENT ───────────────────────────────────
    // Teacher accounts are created by staff. A student account is never
    // upgraded into one, so there is no self-service path here.

    public static function listTeachers() {
        $db = null;
        self::actingAdminId($db);

        $rows = $db->query("
            SELECT tp.id, tp.user_id, tp.display_name, tp.qualification, tp.specialisation,
                   tp.questions_submitted, tp.questions_approved, tp.questions_rejected,
                   tp.status, tp.created_at,
                   u.full_name, u.email, u.mobile
            FROM teacher_profiles tp
            JOIN users u ON tp.user_id = u.id
            ORDER BY tp.created_at DESC
        ")->fetchAll();

        Response::json($rows, 'Teachers loaded');
    }

    public static function createTeacher() {
        $db = null;
        $adminId = self::actingAdminId($db);
        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $fullName       = trim($input['full_name'] ?? '');
        $email          = trim($input['email'] ?? '');
        $mobile         = trim($input['mobile'] ?? '');
        $password       = (string)($input['password'] ?? '');
        $displayName    = trim($input['display_name'] ?? '') ?: $fullName;
        $qualification  = trim($input['qualification'] ?? '');
        $specialisation = trim($input['specialisation'] ?? '');

        $errors = [];
        if ($fullName === '') $errors['full_name'] = 'Full name is required';
        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors['email'] = 'A valid email is required';
        if (strlen($password) < 8) $errors['password'] = 'Password must be at least 8 characters';
        if ($errors) {
            Response::json(null, 'Please correct the highlighted fields', 'error', 422, $errors);
            return;
        }

        // Placeholder mobile when none is supplied, so UNIQUE(mobile) never collides.
        if ($mobile === '') {
            do {
                $mobile = 'NA-' . bin2hex(random_bytes(8));
                $probe = $db->prepare("SELECT id FROM users WHERE mobile = ?");
                $probe->execute([$mobile]);
            } while ($probe->fetch());
        }

        $exists = $db->prepare("SELECT id FROM users WHERE email = ? OR mobile = ?");
        $exists->execute([$email, $mobile]);
        if ($exists->fetch()) Response::error('An account with that email or mobile already exists', 409);

        $db->beginTransaction();
        try {
            $db->prepare("
                INSERT INTO users (full_name, email, mobile, password_hash, user_type, is_verified, status)
                VALUES (?, ?, ?, ?, 'teacher', 1, 'active')
            ")->execute([$fullName, $email, $mobile, password_hash($password, PASSWORD_BCRYPT)]);
            $userId = $db->lastInsertId();

            $db->prepare("
                INSERT INTO teacher_profiles (user_id, display_name, qualification, specialisation)
                VALUES (?, ?, ?, ?)
            ")->execute([$userId, $displayName, $qualification ?: null, $specialisation ?: null]);

            self::audit($db, $adminId, 'CREATE_TEACHER', $userId, 'Created teacher account: ' . $email);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }

        Response::json(['user_id' => intval($userId)], 'Teacher account created', 'success', 201);
    }

    public static function setTeacherStatus($id) {
        $db = null;
        $adminId = self::actingAdminId($db);
        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $status = $input['status'] ?? '';
        if (!in_array($status, ['active','suspended'], true)) {
            Response::error("status must be 'active' or 'suspended'", 422);
        }

        $stmt = $db->prepare("UPDATE teacher_profiles SET status = ? WHERE id = ?");
        $stmt->execute([$status, $id]);
        if ($stmt->rowCount() === 0) Response::error('Teacher not found', 404);

        self::audit($db, $adminId, 'UPDATE_TEACHER_STATUS', $id, 'Teacher profile #' . $id . ' set to ' . $status);
        Response::json(['status' => $status], 'Teacher status updated');
    }

    private static function loadPending($db, $id) {
        $stmt = $db->prepare("SELECT id, status, author_user_id FROM questions WHERE id = ?");
        $stmt->execute([$id]);
        $q = $stmt->fetch();

        if (!$q) Response::error('Question not found', 404);
        if ($q['author_user_id'] === null) Response::error('This question was not submitted by a teacher', 422);
        if ($q['status'] !== 'review') Response::error('This question has already been reviewed', 409);
        return $q;
    }

    /** Best-effort in-app notification; never fails the review action. */
    private static function notifyAuthor($db, $userId, $title, $message) {
        if (!$userId) return;
        try {
            $db->prepare("INSERT INTO user_notifications (user_id, title, message, type) VALUES (?, ?, ?, 'system')")
               ->execute([$userId, $title, $message]);
        } catch (PDOException $e) {
            error_log('EXAMVERSE teacher notification failed: ' . $e->getMessage());
        }
    }

    private static function audit($db, $adminId, $action, $entityId, $details) {
        if (!$adminId) return;
        try {
            $db->prepare("INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, details) VALUES (?, ?, 'QUESTION', ?, ?)")
               ->execute([$adminId, $action, $entityId, $details]);
        } catch (PDOException $e) {
            error_log('EXAMVERSE audit log failed: ' . $e->getMessage());
        }
    }
}
