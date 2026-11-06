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

switch ($action) {

    // ── REVIEW QUEUE ───────────────────────────────────────────────────
    case 'list':
        $allowedStatuses = ['review', 'published', 'changes_requested', 'rejected'];
        $status    = in_array($_GET['status'] ?? '', $allowedStatuses, true) ? $_GET['status'] : 'review';
        $subjectId = intval($_GET['subject_id'] ?? 0);

        $where  = ["q.status = ?", "q.author_user_id IS NOT NULL"];
        $params = [$status];
        if ($subjectId) { $where[] = "q.subject_id = ?"; $params[] = $subjectId; }
        $whereSql = implode(' AND ', $where);

        $stmt = $db->prepare("
            SELECT q.id, q.status, q.difficulty, q.image_url, q.marks, q.negative_marks,
                   q.created_at, q.reviewed_at, q.rejection_reason, q.admin_comment,
                   qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, c.name AS chapter_name, t.name AS topic_name,
                   u.full_name AS author_name,
                   tp.display_name AS author_display_name,
                   tp.questions_approved, tp.questions_rejected
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language='en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN chapters c ON q.chapter_id = c.id
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
        foreach ($allowedStatuses as $st) {
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
        if ($question['status'] === 'published') ajaxErr('This question is already approved and published', 409);

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
            if (!empty($body['difficulty']) && in_array($body['difficulty'], ['easy','medium','hard'], true)) {
                $db->prepare("UPDATE questions SET difficulty = ? WHERE id = ?")->execute([$body['difficulty'], $id]);
            }

            $db->prepare("UPDATE questions SET status='published', reviewed_by=?, reviewed_at=NOW(), rejection_reason=NULL, admin_comment=NULL WHERE id=?")
               ->execute([$adminId, $id]);

            if ($question['author_user_id']) {
                $db->prepare("UPDATE teacher_profiles SET questions_approved = questions_approved + 1 WHERE user_id=?")
                   ->execute([$question['author_user_id']]);

                notifyTeacher($db, $question['author_user_id'], 'Question approved',
                    'Your question #' . $id . ' has been approved by admin and is now live for students.');
            }

            auditLog($db, $adminId, 'APPROVE_QUESTION', $id, 'Approved teacher question #' . $id);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE approve failed: ' . $e->getMessage());
            ajaxErr('Could not approve this question', 500);
        }

        ajaxOk(['question_id' => $id], 'Question approved and published ✓');
        break;

    // ── REQUEST CHANGES ────────────────────────────────────────────────
    case 'request_changes':
        $id      = intval($_GET['id'] ?? 0);
        $body    = getBody();
        $comment = trim($body['comment'] ?? ($body['reason'] ?? ''));
        if (!$id) ajaxErr('id required', 422);
        if ($comment === '') ajaxErr('Feedback comment is mandatory when requesting changes', 422);
        if (mb_strlen($comment) > 1000) ajaxErr('Comment must be under 1000 characters', 422);

        $q = $db->prepare("SELECT id, status, author_user_id FROM questions WHERE id=?");
        $q->execute([$id]);
        $question = $q->fetch(PDO::FETCH_ASSOC);
        if (!$question) ajaxErr('Question not found', 404);

        $db->beginTransaction();
        try {
            $db->prepare("
                UPDATE questions 
                SET status='changes_requested', reviewed_by=?, reviewed_at=NOW(), 
                    rejection_reason=?, admin_comment=? 
                WHERE id=?
            ")->execute([$adminId, $comment, $comment, $id]);

            if ($question['author_user_id']) {
                notifyTeacher($db, $question['author_user_id'], 'Question changes requested',
                    'Admin requested modifications on Question #' . $id . ': ' . $comment);
            }

            auditLog($db, $adminId, 'REQUEST_CHANGES', $id, 'Requested changes on question #' . $id . ': ' . $comment);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE request changes failed: ' . $e->getMessage());
            ajaxErr('Could not request changes', 500);
        }

        ajaxOk(['question_id' => $id], 'Changes requested. The teacher has been notified with your feedback.');
        break;

    // ── REJECT ─────────────────────────────────────────────────────────
    case 'reject':
        $id     = intval($_GET['id'] ?? 0);
        $body   = getBody();
        $reason = trim($body['reason'] ?? ($body['comment'] ?? ''));
        if (!$id) ajaxErr('id required', 422);
        if ($reason === '') ajaxErr('A rejection reason is mandatory so the teacher understands why it was rejected', 422);
        if (mb_strlen($reason) > 1000) ajaxErr('Reason must be under 1000 characters', 422);

        $q = $db->prepare("SELECT id, status, author_user_id FROM questions WHERE id=?");
        $q->execute([$id]);
        $question = $q->fetch(PDO::FETCH_ASSOC);
        if (!$question) ajaxErr('Question not found', 404);

        $db->beginTransaction();
        try {
            $db->prepare("UPDATE questions SET status='rejected', reviewed_by=?, reviewed_at=NOW(), rejection_reason=?, admin_comment=? WHERE id=?")
               ->execute([$adminId, $reason, $reason, $id]);

            if ($question['author_user_id']) {
                $db->prepare("UPDATE teacher_profiles SET questions_rejected = questions_rejected + 1 WHERE user_id=?")
                   ->execute([$question['author_user_id']]);

                notifyTeacher($db, $question['author_user_id'], 'Question rejected',
                    'A question you submitted was rejected. Reason: ' . $reason);
            }

            auditLog($db, $adminId, 'REJECT_QUESTION', $id, 'Rejected teacher question #' . $id . ': ' . $reason);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE reject failed: ' . $e->getMessage());
            ajaxErr('Could not reject this question', 500);
        }

        ajaxOk(['question_id' => $id], 'Question rejected and teacher notified');
        break;

    // ── UNPUBLISH ──────────────────────────────────────────────────────
    case 'unpublish':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('id required', 422);

        $q = $db->prepare("SELECT id, status, author_user_id FROM questions WHERE id=?");
        $q->execute([$id]);
        $question = $q->fetch(PDO::FETCH_ASSOC);
        if (!$question) ajaxErr('Question not found', 404);
        if ($question['status'] !== 'published') ajaxErr('Question is not currently published', 409);

        $db->beginTransaction();
        try {
            $db->prepare("UPDATE questions SET status='draft', reviewed_by=?, updated_at=NOW() WHERE id=?")
               ->execute([$adminId, $id]);

            if ($question['author_user_id']) {
                $db->prepare("UPDATE teacher_profiles SET questions_approved = GREATEST(0, questions_approved - 1) WHERE user_id=?")
                   ->execute([$question['author_user_id']]);

                notifyTeacher($db, $question['author_user_id'], 'Question unpublished',
                    'Your question #' . $id . ' has been unpublished by admin and is no longer live for students.');
            }

            auditLog($db, $adminId, 'UNPUBLISH_QUESTION', $id, 'Unpublished question #' . $id);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE unpublish failed: ' . $e->getMessage());
            ajaxErr('Could not unpublish question', 500);
        }

        ajaxOk(['question_id' => $id], 'Question unpublished and moved to draft.');
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
        $mobile         = trim($body['mobile'] ?? '');
        $password       = (string)($body['password'] ?? '');
        $displayName    = trim($body['display_name'] ?? '') ?: $fullName;
        $qualification  = trim($body['qualification'] ?? '');
        $specialisation = trim($body['specialisation'] ?? '');

        if ($fullName === '') ajaxErr('Full name is required', 422);
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) ajaxErr('A valid email is required', 422);
        if (strlen($password) < 8) ajaxErr('Password must be at least 8 characters', 422);

        if ($mobile === '') {
            do {
                $mobile = 'NA-' . bin2hex(random_bytes(8));
                $probe = $db->prepare("SELECT id FROM users WHERE mobile=?");
                $probe->execute([$mobile]);
            } while ($probe->fetch());
        } else {
            $mobileProbe = $db->prepare("SELECT id FROM users WHERE mobile=?");
            $mobileProbe->execute([$mobile]);
            if ($mobileProbe->fetch()) ajaxErr('An account with this mobile number already exists', 409);
        }

        $exists = $db->prepare("SELECT id FROM users WHERE email=?");
        $exists->execute([$email]);
        if ($exists->fetch()) ajaxErr('An account with that email already exists', 409);

        $db->beginTransaction();
        try {
            $db->prepare("INSERT INTO users (full_name, email, mobile, password_hash, user_type, is_verified, status) VALUES (?,?,?,?,'teacher',1,'active')")
               ->execute([$fullName, $email, $mobile, password_hash($password, PASSWORD_BCRYPT)]);
            $userId = $db->lastInsertId();

            $db->prepare("INSERT INTO teacher_profiles (user_id, display_name, qualification, specialisation, status) VALUES (?,?,?,?,'active')")
               ->execute([$userId, $displayName, $qualification, $specialisation]);

            auditLog($db, $adminId, 'CREATE_TEACHER', $userId, 'Created teacher account for ' . $email);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('EXAMVERSE create teacher failed: ' . $e->getMessage());
            ajaxErr('Could not create teacher account', 500);
        }

        ajaxOk(['user_id' => $userId], 'Teacher account created ✓');
        break;

    case 'set_teacher_status':
        $id     = intval($_GET['id'] ?? 0);
        $body   = getBody();
        $status = in_array($body['status'] ?? '', ['active','suspended'], true) ? $body['status'] : '';
        if (!$id || !$status) ajaxErr('id and valid status required', 422);

        $db->prepare("UPDATE teacher_profiles SET status=? WHERE id=?")->execute([$status, $id]);
        auditLog($db, $adminId, 'SET_TEACHER_STATUS', $id, 'Changed teacher #' . $id . ' status to ' . $status);
        ajaxOk(null, 'Teacher status updated');
        break;

    default:
        ajaxErr('Unknown action: ' . $action, 404);
}
