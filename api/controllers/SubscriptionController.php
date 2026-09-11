<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class SubscriptionController {

    /**
     * Get all available subscription plans and user's current active status
     */
    public static function getPlans() {
        $authUser = null;
        try {
            $authUser = AuthMiddleware::getAuthenticatedUser('student');
        } catch (Exception $e) {}

        $userId = $authUser ? $authUser['sub'] : null;
        $db = Database::getConnection();

        // 1. Fetch Active Plans
        $plans = $db->query("
            SELECT id, name, duration_days, price, description, is_active, created_at
            FROM subscription_plans
            WHERE is_active = 1
            ORDER BY price ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        // Feature list for plans
        $features = [
            'Unlimited Mock Tests & Sectional Tests',
            'All-India Central AIR & State Rank Predictor',
            'Full AI Exam-Twin Score Simulations',
            'Step-by-Step Solutions & Shortcut Tricks',
            'Revision Mistake Notebook Access',
            'State Geography & Interactive Map Quizzes',
            'Ad-Free Ultra Fast Learning Experience'
        ];

        // 2. Fetch User's Current Active Subscription if logged in
        $mySubscription = null;
        if ($userId) {
            $stmtSub = $db->prepare("
                SELECT us.id as subscription_id, us.status as sub_status, us.expiry_date, us.created_at as started_at,
                       sp.id as plan_id, sp.name as plan_name, sp.price, sp.duration_days
                FROM user_subscriptions us
                JOIN subscription_plans sp ON us.plan_id = sp.id
                WHERE us.user_id = ?
                ORDER BY us.id DESC LIMIT 1
            ");
            $stmtSub->execute([$userId]);
            $sub = $stmtSub->fetch(PDO::FETCH_ASSOC);

            if ($sub) {
                $now = time();
                $expiryTime = strtotime($sub['expiry_date']);
                $daysLeft = max(0, ceil(($expiryTime - $now) / 86400));
                $isExpired = $expiryTime < $now;

                $mySubscription = [
                    'subscription_id' => intval($sub['subscription_id']),
                    'plan_id'         => intval($sub['plan_id']),
                    'plan_name'       => $sub['plan_name'],
                    'price'           => floatval($sub['price']),
                    'status'          => $isExpired ? 'expired' : $sub['sub_status'],
                    'is_active'       => !$isExpired && in_array($sub['sub_status'], ['active', 'trial']),
                    'expiry_date'     => $sub['expiry_date'],
                    'started_at'      => $sub['started_at'],
                    'days_left'       => $daysLeft,
                    'is_expired'      => $isExpired,
                ];
            }
        }

        Response::json([
            'plans'           => $plans,
            'features'        => $features,
            'my_subscription' => $mySubscription,
        ], 'Subscription plans loaded successfully');
    }

    /**
     * Get authenticated student's active subscription details and history
     */
    public static function getMySubscription() {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];
        $db = Database::getConnection();

        $stmtSub = $db->prepare("
            SELECT us.id as subscription_id, us.status as sub_status, us.expiry_date, us.created_at as started_at,
                   sp.id as plan_id, sp.name as plan_name, sp.price, sp.duration_days, sp.description
            FROM user_subscriptions us
            JOIN subscription_plans sp ON us.plan_id = sp.id
            WHERE us.user_id = ?
            ORDER BY us.id DESC
        ");
        $stmtSub->execute([$userId]);
        $history = $stmtSub->fetchAll(PDO::FETCH_ASSOC);

        $current = null;
        if (!empty($history)) {
            $latest = $history[0];
            $now = time();
            $expiryTime = strtotime($latest['expiry_date']);
            $daysLeft = max(0, ceil(($expiryTime - $now) / 86400));
            $isExpired = $expiryTime < $now;

            $current = [
                'subscription_id' => intval($latest['subscription_id']),
                'plan_id'         => intval($latest['plan_id']),
                'plan_name'       => $latest['plan_name'],
                'price'           => floatval($latest['price']),
                'status'          => $isExpired ? 'expired' : $latest['sub_status'],
                'is_active'       => !$isExpired && in_array($latest['sub_status'], ['active', 'trial']),
                'expiry_date'     => $latest['expiry_date'],
                'started_at'      => $latest['started_at'],
                'days_left'       => $daysLeft,
                'is_expired'      => $isExpired,
            ];
        }

        Response::json([
            'current' => $current,
            'history' => $history,
        ], 'My subscription details loaded');
    }

    /**
     * Purchase / Activate a subscription plan
     */
    public static function subscribe() {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $planId = intval($input['plan_id'] ?? 0);
        $paymentMethod = trim((string)($input['payment_method'] ?? 'upi'));

        if (!$planId) {
            Response::error('Plan ID is required', 400);
        }

        $db = Database::getConnection();

        // Check plan exists
        $stmtPlan = $db->prepare("SELECT id, name, duration_days, price, description FROM subscription_plans WHERE id = ? AND is_active = 1");
        $stmtPlan->execute([$planId]);
        $plan = $stmtPlan->fetch(PDO::FETCH_ASSOC);

        if (!$plan) {
            Response::error('Selected subscription plan not found or inactive', 404);
        }

        $days = intval($plan['duration_days']);
        $planName = $plan['name'];
        $price = floatval($plan['price']);

        // Check existing active subscription to extend
        $stmtCur = $db->prepare("
            SELECT id, expiry_date 
            FROM user_subscriptions 
            WHERE user_id = ? AND status IN ('active', 'trial', 'expiring') AND expiry_date > NOW()
            ORDER BY expiry_date DESC LIMIT 1
        ");
        $stmtCur->execute([$userId]);
        $cur = $stmtCur->fetch(PDO::FETCH_ASSOC);

        if ($cur) {
            // Extend existing expiry
            $baseTime = strtotime($cur['expiry_date']) > time() ? strtotime($cur['expiry_date']) : time();
            $newExpiry = date('Y-m-d H:i:s', $baseTime + ($days * 86400));

            $stmtUp = $db->prepare("UPDATE user_subscriptions SET expiry_date = ?, plan_id = ?, status = 'active' WHERE id = ?");
            $stmtUp->execute([$newExpiry, $planId, $cur['id']]);
            $subId = $cur['id'];
        } else {
            // New subscription starting immediately
            $newExpiry = date('Y-m-d H:i:s', time() + ($days * 86400));
            $stmtIns = $db->prepare("INSERT INTO user_subscriptions (user_id, plan_id, status, expiry_date) VALUES (?, ?, 'active', ?)");
            $stmtIns->execute([$userId, $planId, $newExpiry]);
            $subId = $db->lastInsertId();
        }

        // Send In-app Congratulations Notification
        try {
            $stmtNotif = $db->prepare("
                INSERT INTO user_notifications (user_id, title, message, type, is_read) 
                VALUES (?, ?, ?, 'subscription', 0)
            ");
            $stmtNotif->execute([
                $userId,
                "🌟 {$planName} Activated!",
                "Congratulations! Your ExamVerse Pro pass is now active for {$days} days until " . date('d M Y', strtotime($newExpiry)) . ". Enjoy unlimited tests and AI tools."
            ]);
        } catch (Exception $e) {}

        $receiptNo = 'EV-SUB-' . strtoupper(dechex(time())) . '-' . str_pad($userId, 4, '0', STR_PAD_LEFT);

        Response::json([
            'subscription_id' => intval($subId),
            'plan_name'       => $planName,
            'price_paid'      => $price,
            'duration_days'   => $days,
            'expiry_date'     => $newExpiry,
            'receipt_no'      => $receiptNo,
            'payment_method'  => $paymentMethod,
            'access_granted'  => true,
        ], "Congratulations! {$planName} successfully activated.");
    }
}
