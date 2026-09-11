<?php
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';

$db = Database::getConnection();
$action = $_GET['action'] ?? '';
$body = getBody();

if ($action === 'get_user_360') {
    $userId = intval($_GET['user_id'] ?? ($body['user_id'] ?? 0));
    if (!$userId) ajaxErr('User ID is required');

    // 1. Fetch Candidate Profile
    $stmtUser = $db->prepare("
        SELECT u.id, u.full_name, u.email, u.mobile, u.status, u.is_verified, u.district, u.created_at, u.updated_at,
               s.name as state_name, q.name as qualification_name
        FROM users u
        LEFT JOIN states s ON u.state_id = s.id
        LEFT JOIN qualifications q ON u.qualification_id = q.id
        WHERE u.id = ?
    ");
    $stmtUser->execute([$userId]);
    $user = $stmtUser->fetch(PDO::FETCH_ASSOC);
    if (!$user) ajaxErr('Candidate not found', 404);

    // 2. Fetch Subscription Info
    $stmtSub = $db->prepare("
        SELECT us.id as subscription_id, us.status as sub_status, us.expiry_date, us.created_at as sub_started_at,
               sp.id as plan_id, sp.name as plan_name, sp.duration_days, sp.price, sp.description as plan_description
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = ?
        ORDER BY us.id DESC LIMIT 1
    ");
    $stmtSub->execute([$userId]);
    $sub = $stmtSub->fetch(PDO::FETCH_ASSOC);

    $subscriptionData = null;
    if ($sub) {
        $now = time();
        $expiryTime = strtotime($sub['expiry_date']);
        $daysLeft = max(0, ceil(($expiryTime - $now) / 86400));
        $isExpired = $expiryTime < $now;
        
        $subscriptionData = [
            'subscription_id'  => intval($sub['subscription_id']),
            'plan_id'          => intval($sub['plan_id']),
            'plan_name'        => $sub['plan_name'],
            'price'            => floatval($sub['price']),
            'duration_days'    => intval($sub['duration_days']),
            'status'           => $isExpired ? 'expired' : $sub['sub_status'],
            'expiry_date'      => $sub['expiry_date'],
            'started_at'       => $sub['sub_started_at'],
            'days_left'        => $daysLeft,
            'is_expired'       => $isExpired,
            'plan_description' => $sub['plan_description'],
        ];
    }

    // Available plans for quick grant/upgrade
    $allPlans = $db->query("SELECT id, name, duration_days, price FROM subscription_plans WHERE is_active = 1 ORDER BY price ASC")->fetchAll(PDO::FETCH_ASSOC);

    // 3. Exam & Test Performance Aggregates
    $stmtAgg = $db->prepare("
        SELECT COUNT(*) as total_attempts,
               SUM(CASE WHEN status = 'evaluated' THEN 1 ELSE 0 END) as completed_attempts,
               COALESCE(AVG(CASE WHEN status = 'evaluated' THEN score END), 0) as avg_score,
               COALESCE(MAX(CASE WHEN status = 'evaluated' THEN score END), 0) as max_score,
               COALESCE(AVG(CASE WHEN status = 'evaluated' THEN accuracy_percentage END), 0) as avg_accuracy,
               MIN(CASE WHEN status = 'evaluated' AND central_rank > 0 THEN central_rank END) as best_air_rank,
               MIN(CASE WHEN status = 'evaluated' AND state_rank > 0 THEN state_rank END) as best_state_rank,
               COALESCE(SUM(correct_count), 0) as total_correct,
               COALESCE(SUM(wrong_count), 0) as total_wrong,
               COALESCE(SUM(unattempted_count), 0) as total_unattempted,
               COALESCE(SUM(total_time_spent_seconds), 0) as total_time_spent
        FROM test_attempts
        WHERE user_id = ?
    ");
    $stmtAgg->execute([$userId]);
    $agg = $stmtAgg->fetch(PDO::FETCH_ASSOC);

    // 4. Test Attempts History List
    $stmtHist = $db->prepare("
        SELECT att.id as attempt_id, att.test_id, att.status, att.score, att.accuracy_percentage,
               att.central_rank, att.state_rank, att.percentile,
               att.correct_count, att.wrong_count, att.unattempted_count,
               att.total_time_spent_seconds, att.started_at, att.submitted_at,
               t.title as test_title, t.total_questions, e.title as exam_title
        FROM test_attempts att
        JOIN tests t ON att.test_id = t.id
        LEFT JOIN exams e ON t.exam_id = e.id
        WHERE att.user_id = ?
        ORDER BY att.id DESC
        LIMIT 50
    ");
    $stmtHist->execute([$userId]);
    $history = $stmtHist->fetchAll(PDO::FETCH_ASSOC);

    // 5. Learning & Mistake Insights
    $wrongCount = (int)$db->prepare("SELECT COUNT(*) FROM user_wrong_questions WHERE user_id = ?")->execute([$userId]) ? $db->prepare("SELECT COUNT(*) FROM user_wrong_questions WHERE user_id = ?")->fetchColumn() : 0;
    $notebookCount = (int)$db->prepare("SELECT COUNT(*) FROM mistake_notebook WHERE user_id = ?")->execute([$userId]) ? $db->prepare("SELECT COUNT(*) FROM mistake_notebook WHERE user_id = ?")->fetchColumn() : 0;
    $bookmarksCount = (int)$db->prepare("SELECT COUNT(*) FROM user_bookmarks WHERE user_id = ?")->execute([$userId]) ? $db->prepare("SELECT COUNT(*) FROM user_bookmarks WHERE user_id = ?")->fetchColumn() : 0;

    // 6. Referral Data
    $stmtRefCode = $db->prepare("SELECT code FROM referral_codes WHERE user_id = ? LIMIT 1");
    $stmtRefCode->execute([$userId]);
    $refCode = $stmtRefCode->fetchColumn() ?: 'EXAM' . str_pad($userId, 4, '0', STR_PAD_LEFT);

    $stmtRefs = $db->prepare("SELECT COUNT(*) as invited_count FROM referrals WHERE referrer_user_id = ?");
    $stmtRefs->execute([$userId]);
    $refStats = $stmtRefs->fetch(PDO::FETCH_ASSOC);

    ajaxOk([
        'user' => $user,
        'subscription' => $subscriptionData,
        'available_plans' => $allPlans,
        'performance' => [
            'total_attempts'      => intval($agg['total_attempts']),
            'completed_attempts'  => intval($agg['completed_attempts']),
            'avg_score'           => round(floatval($agg['avg_score']), 1),
            'max_score'           => round(floatval($agg['max_score']), 1),
            'avg_accuracy'        => round(floatval($agg['avg_accuracy']), 1),
            'best_air_rank'       => $agg['best_air_rank'] ? intval($agg['best_air_rank']) : null,
            'best_state_rank'     => $agg['best_state_rank'] ? intval($agg['best_state_rank']) : null,
            'total_correct'       => intval($agg['total_correct']),
            'total_wrong'         => intval($agg['total_wrong']),
            'total_unattempted'   => intval($agg['total_unattempted']),
            'total_time_spent'    => intval($agg['total_time_spent']),
            'wrong_notebook_items'=> $wrongCount + $notebookCount,
            'bookmarks_count'     => $bookmarksCount,
            'referral_code'       => $refCode,
            'invited_friends'     => intval($refStats['invited_count'] ?? 0),
        ],
        'attempts' => $history
    ], 'Candidate 360 profile loaded');
}

// Grant or Extend Subscription
if ($action === 'grant_subscription') {
    $userId = intval($body['user_id'] ?? 0);
    $planId = intval($body['plan_id'] ?? 0);
    $days = intval($body['days'] ?? 30);
    if (!$userId || !$planId || $days <= 0) ajaxErr('Invalid user ID, plan ID, or days.');

    $stmtPlan = $db->prepare("SELECT name FROM subscription_plans WHERE id = ?");
    $stmtPlan->execute([$planId]);
    $planName = $stmtPlan->fetchColumn();
    if (!$planName) ajaxErr('Plan not found.');

    $stmtCur = $db->prepare("SELECT id, expiry_date FROM user_subscriptions WHERE user_id = ? AND status IN ('active', 'trial', 'expiring') ORDER BY expiry_date DESC LIMIT 1");
    $stmtCur->execute([$userId]);
    $cur = $stmtCur->fetch();

    if ($cur) {
        $base = strtotime($cur['expiry_date']) > time() ? strtotime($cur['expiry_date']) : time();
        $newExpiry = date('Y-m-d H:i:s', $base + ($days * 86400));
        $stmtUp = $db->prepare("UPDATE user_subscriptions SET expiry_date = ?, plan_id = ?, status = 'active' WHERE id = ?");
        $stmtUp->execute([$newExpiry, $planId, $cur['id']]);
    } else {
        $newExpiry = date('Y-m-d H:i:s', time() + ($days * 86400));
        $stmtIns = $db->prepare("INSERT INTO user_subscriptions (user_id, plan_id, status, expiry_date) VALUES (?, ?, 'active', ?)");
        $stmtIns->execute([$userId, $planId, $newExpiry]);
    }

    // Send In-app Notification
    try {
        $db->prepare("INSERT INTO user_notifications (user_id, title, message, type, is_read) VALUES (?, ?, ?, 'subscription', 0)")
           ->execute([$userId, "🌟 {$planName} Activated!", "Your membership has been extended by {$days} days. Valid until " . date('d M Y', strtotime($newExpiry)) . "."]);
    } catch (Exception $e) {}

    auditLog($db, $_SESSION['admin_user']['id'] ?? 1, 'GRANT_SUBSCRIPTION', $userId, "Granted {$planName} for {$days} days");

    ajaxOk(['new_expiry' => $newExpiry], "Successfully granted {$days} days of {$planName} to candidate.");
}

// Send Custom In-app Notification
if ($action === 'send_notification') {
    $userId = intval($body['user_id'] ?? 0);
    $title = trim($body['title'] ?? '');
    $message = trim($body['message'] ?? '');
    if (!$userId || !$title || !$message) ajaxErr('User, title and message are required.');

    $stmt = $db->prepare("INSERT INTO user_notifications (user_id, title, message, type, is_read) VALUES (?, ?, ?, 'system', 0)");
    $stmt->execute([$userId, $title, $message]);

    auditLog($db, $_SESSION['admin_user']['id'] ?? 1, 'SEND_NOTIFICATION', $userId, "Sent alert: {$title}");

    ajaxOk(null, 'Notification sent to candidate app successfully.');
}

ajaxErr('Invalid action specified.');
