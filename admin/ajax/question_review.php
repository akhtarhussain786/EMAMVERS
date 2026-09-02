<?php
/**
 * Admin AJAX: teacher question review queue and teacher accounts.
 * URL: /EXAMVERSE/admin/ajax/question_review.php?action=...
 * Auth: PHP session + CSRF (see _guard.php)
 */
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';

$db     = Database::getConnection();
$action = $_GET['action'] ?? '';
$adminId = $_SESSION['admin_user']['id'] ?? null;

function auditLog($db, $adminId, $action, $entityId, $details) {
    if (!$adminId) return;
    try {
        $db->prepare("INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, details) VALUES (?,?,'QUESTION',?,?)")
           ->execute([$adminId, $action, $entityId, $details]);
    } catch (PDOException $e) {
        error_log('EXAMVERSE audit log failed: ' . $e->getMessage());
    }
}

function notifyTeacher($db, $userId, $title, $message) {
    if (!$userId) return;
    try {
        $db->prepare("INSERT INTO user_notifications (user_id, title, message, type) VALUES (?,?,?,'system')")
           ->execute([$userId, $title, $message]);
    } catch (PDOException $e) {
        error_log('EXAMVERSE teacher notification failed: ' . $e->getMessage());
    }
}

switch ($action) {

    // ── REVIEW QUEUE ───────────────────────────────────────────────────
    case 'list':
        $status    = in_array($_GET['status'] ?? '', ['review','published','rejected'], true) ? $_GET['status'] : 'review';
        $subjectId = intval($_GET['subject_id'] ?? 0);

        $where  = ["q.status = ?", "q.author_user_id IS NOT NULL"];
        $params = [$status];
        if ($subjectId) { $where[] = "q.subject_id = ?"; $params[] = $subjectId; }
        $whereSql = implode(' AND ', $where);

        $stmt = $db->prepare("
            SELECT q.id, q.status, q.difficulty, q.created_at, q.reviewed_at, q.rejection_reason,
                   qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, t.name AS topic_name,
                   u.full_name AS author_name,
                   tp.display_name AS author_display_name,
                   tp.questions_approved, tp.questions_rejected
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language='en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN topics t ON q.topic_id = t.id
            LEFT JOIN users u ON q.author_user_id = u.id
            LEFT JOIN teacher_profiles tp ON tp.user_id = q.author_user_id
            WHERE $whereSql
            ORDER BY q.created_at ASC LIMIT 100
        ");
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if ($rows) {
            $ids = array_column($rows, 'id');
            $ph  = implode(',', array_fill(0, count($ids), '?'));
            $opt = $db->prepare("SELECT question_id, option_key, option_text, is_correct FROM question_options WHERE question_id IN ($ph) AND language='en' ORDER BY option_key");
            $opt->execute($ids);
            $byQ = [];
            foreach ($opt->fetchAll(PDO::FETCH_ASSOC) as $o) $byQ[$o['question_id']][] = $o;
            foreach ($rows as &$r) $r['options'] = $byQ[$r['id']] ?? [];
            unset($r);
        }

        $counts = [];
        foreach (['review','published','rejected'] as $st) {
            $c = $db->prepare("SELECT COUNT(*) FROM questions WHERE status=? AND author_user_id IS NOT NULL");
            $c->execute([$st]);
            $counts[$st] = intval($c->fetchColumn());
        }

        ajaxOk(['submissions' => $rows, 'counts' => $counts], 'Submissions loaded');
        break;

    // ── APPROVE ────────────────────────────────────────────────────────
    case 'approve':
        $id   = intval($_GET['id'] ?? 0);
        $body = getBody();
        if (!$id) ajaxErr('id required', 422);

        $q = $db->prepare("SELECT id, status, author_user_id FROM questions WHERE id=?");
        $q->execute([$id]);
        $question = $q->fetch(PDO::FETCH_ASSOC);
        if (!$question) ajaxErr('Question not found', 404);
        if ($question['status'] !== 'review') ajaxErr('This question has already been reviewed', 409);

        $db->beginTransaction();
        try {
            // Reviewer edits, if any, are applied before publishing.
            if (!empty($body['question_text']) || !empty($body['explanation'])) {
                $db->prepare("
                    UPDATE question_translations
                    SET question_text = COALESCE(NULLIF(?,''), question_text),
                        solution_text = COALESCE(NULLIF(?,''), solution_text)
                    WHERE question_id = ? AND language='en'
                ")->execute([trim($body['question_text'] ?? ''), trim($body['explanation'] ?? ''), $id]);
            }
            if (!empty($body['correct_option']) && in_array(strtoupper($body['correct_option']), ['A','B','C','D'], true)) {
                $db->prepare("UPDATE question_options SET is_correct = (option_key = ?) WHERE question_id = ? AND language='en'")
                   ->execute([strtoupper($body['correct_option']), $id]);
            }
            // Reviewers frequently re-grade difficulty; keep this in step with
            // the API's approve endpoint, which already supported it.
            if (!empty($body['difficulty']) && in_array($body['difficulty'], ['easy','medium','hard'], true)) {
                $db->prepare("UPDATE questions SET difficulty = ? WHERE id = ?")->execute([$body['difficulty'], $id]);
            }

            $db->prepare("UPDATE questions SET status='published', reviewed_by=?, reviewed_at=NOW(), rejection_reason=NULL WHERE id=?")
               ->execute([$adminId, $id]);
            $db->prepare("UPDATE teacher_profiles SET questions_approved = questions_approved + 1 WHERE user_id=?")
               ->execute([$question['author_user_id']]);

            notifyTeacher($db, $question['author_user_id'], 'Question approved',
                'Your question has been approved and is now live for students.');
            auditLog($db, $adminId, 'APPROVE_QUESTION', $id, 'Approved teacher question #' . $id);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE approve failed: ' . $e->getMessage());
            ajaxErr('Could not approve this question', 500);
        }

        ajaxOk(['question_id' => $id], 'Question approved and published ✓');
        break;

    // ── REJECT ─────────────────────────────────────────────────────────
    case 'reject':
        $id     = intval($_GET['id'] ?? 0);
        $body   = getBody();
        $reason = trim($body['reason'] ?? '');
        if (!$id) ajaxErr('id required', 422);
        if ($reason === '') ajaxErr('A reason is required so the teacher can correct and resubmit', 422);
        if (mb_strlen($reason) > 500) ajaxErr('Reason must be under 500 characters', 422);

        $q = $db->prepare("SELECT id, status, author_user_id FROM questions WHERE id=?");
        $q->execute([$id]);
        $question = $q->fetch(PDO::FETCH_ASSOC);
        if (!$question) ajaxErr('Question not found', 404);
        if ($question['status'] !== 'review') ajaxErr('This question has already been reviewed', 409);

        $db->beginTransaction();
        try {
            $db->prepare("UPDATE questions SET status='rejected', reviewed_by=?, reviewed_at=NOW(), rejection_reason=? WHERE id=?")
               ->execute([$adminId, $reason, $id]);
            $db->prepare("UPDATE teacher_profiles SET questions_rejected = questions_rejected + 1 WHERE user_id=?")
               ->execute([$question['author_user_id']]);

            notifyTeacher($db, $question['author_user_id'], 'Question needs changes',
                'A question you submitted was not approved. Reason: ' . $reason);
            auditLog($db, $adminId, 'REJECT_QUESTION', $id, 'Rejected teacher question #' . $id . ': ' . $reason);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE reject failed: ' . $e->getMessage());
            ajaxErr('Could not reject this question', 500);
        }

        ajaxOk(['question_id' => $id], 'Question rejected and the teacher notified');
        break;

    // ── TEACHER ACCOUNTS ───────────────────────────────────────────────
    case 'teachers':
        $rows = $db->query("
            SELECT tp.id, tp.user_id, tp.display_name, tp.qualification, tp.specialisation,
                   tp.questions_submitted, tp.questions_approved, tp.questions_rejected,
                   tp.status, tp.created_at, u.full_name, u.email
            FROM teacher_profiles tp
            JOIN users u ON tp.user_id = u.id
            ORDER BY tp.created_at DESC
        ")->fetchAll(PDO::FETCH_ASSOC);
        ajaxOk($rows, 'Teachers loaded');
        break;

    case 'create_teacher':
        $body           = getBody();
        $fullName       = trim($body['full_name'] ?? '');
        $email          = trim($body['email'] ?? '');
        $password       = (string)($body['password'] ?? '');
        $displayName    = trim($body['display_name'] ?? '') ?: $fullName;
        $qualification  = trim($body['qualification'] ?? '');
        $specialisation = trim($body['specialisation'] ?? '');

        if ($fullName === '') ajaxErr('Full name is required', 422);
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) ajaxErr('A valid email is required', 422);
        if (strlen($password) < 8) ajaxErr('Password must be at least 8 characters', 422);

        do {
            $mobile = 'NA-' . bin2hex(random_bytes(8));
            $probe = $db->prepare("SELECT id FROM users WHERE mobile=?");
            $probe->execute([$mobile]);
        } while ($probe->fetch());

        $exists = $db->prepare("SELECT id FROM users WHERE email=?");
        $exists->execute([$email]);
        if ($exists->fetch()) ajaxErr('An account with that email already exists', 409);

        $db->beginTransaction();
        try {
            $db->prepare("INSERT INTO users (full_name, email, mobile, password_hash, user_type, is_verified, status) VALUES (?,?,?,?,'teacher',1,'active')")
               ->execute([$fullName, $email, $mobile, password_hash($password, PASSWORD_BCRYPT)]);
            $userId = $db->lastInsertId();
            $db->prepare("INSERT INTO teacher_profiles (user_id, display_name, qualification, specialisation) VALUES (?,?,?,?)")
               ->execute([$userId, $displayName, $qualification ?: null, $specialisation ?: null]);
            auditLog($db, $adminId, 'CREATE_TEACHER', $userId, 'Created teacher account: ' . $email);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE create teacher failed: ' . $e->getMessage());
            ajaxErr('Could not create the teacher account', 500);
        }

        ajaxOk(['user_id' => $userId], 'Teacher account created ✓', 201);
        break;

    case 'teacher_status':
        $id     = intval($_GET['id'] ?? 0);
        $body   = getBody();
        $status = $body['status'] ?? '';
        if (!$id) ajaxErr('id required', 422);
        if (!in_array($status, ['active','suspended'], true)) ajaxErr("status must be 'active' or 'suspended'", 422);

        $stmt = $db->prepare("UPDATE teacher_profiles SET status=? WHERE id=?");
        $stmt->execute([$status, $id]);
        if ($stmt->rowCount() === 0) ajaxErr('Teacher not found', 404);

        auditLog($db, $adminId, 'UPDATE_TEACHER_STATUS', $id, 'Teacher #' . $id . ' set to ' . $status);
        ajaxOk(['status' => $status], 'Teacher status updated');
        break;

    default:
        ajaxErr("Unknown action: $action", 400);
}
