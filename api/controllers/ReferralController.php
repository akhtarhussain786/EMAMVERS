<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

/**
 * Referral, Rewards & Growth Platform Controller.
 * PRD §17: Single-tier referral attribution, fraud prevention,
 * idempotent reward ledger, and subscription expiry extension.
 */
class ReferralController {

    /**
     * Get or create current user's referral code and referral stats.
     */
    public static function getMyReferrals() {
        $auth = AuthMiddleware::getAuthenticatedUser();
        $userId = $auth['sub'];
        $db = Database::getConnection();

        // 1. Fetch or generate unique referral code
        $codeStmt = $db->prepare("SELECT * FROM referral_codes WHERE user_id = ?");
        $codeStmt->execute([$userId]);
        $codeRow = $codeStmt->fetch(PDO::FETCH_ASSOC);

        if (!$codeRow) {
            $code = 'EV' . strtoupper(substr(md5($userId . '_examverse_' . microtime()), 0, 6));
            $insCode = $db->prepare("INSERT INTO referral_codes (user_id, code) VALUES (?, ?)");
            $insCode->execute([$userId, $code]);
            $codeRow = ['code' => $code, 'status' => 'active'];
        }

        // 2. Fetch referral stats
        $statsStmt = $db->prepare("
            SELECT
                COUNT(*) AS total_referred,
                SUM(CASE WHEN status IN ('qualified', 'rewarded') THEN 1 ELSE 0 END) AS qualified_count,
                SUM(CASE WHEN status = 'pending_qualification' THEN 1 ELSE 0 END) AS pending_count
            FROM referrals
            WHERE referrer_user_id = ?
        ");
        $statsStmt->execute([$userId]);
        $stats = $statsStmt->fetch(PDO::FETCH_ASSOC);

        // 3. Fetch total reward days earned
        $rewStmt = $db->prepare("
            SELECT SUM(reward_days) AS total_reward_days
            FROM referral_rewards
            WHERE beneficiary_user_id = ? AND status = 'issued'
        ");
        $rewStmt->execute([$userId]);
        $rewardDays = (int)($rewStmt->fetchColumn() ?: 0);

        // 4. Fetch recent referral history
        $histStmt = $db->prepare("
            SELECT r.id, r.status, r.created_at, r.qualified_at,
                   u.full_name AS referred_name,
                   (SELECT SUM(reward_days) FROM referral_rewards rr WHERE rr.referral_id = r.id AND rr.beneficiary_user_id = ?) AS earned_days
            FROM referrals r
            JOIN users u ON r.referred_user_id = u.id
            WHERE r.referrer_user_id = ?
            ORDER BY r.created_at DESC
            LIMIT 20
        ");
        $histStmt->execute([$userId, $userId]);
        $history = $histStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json([
            'referral_code'     => $codeRow['code'],
            'share_url'         => 'https://examverse.in/join?ref=' . $codeRow['code'],
            'campaign_title'    => 'Invite Friends, Earn Free Premium',
            'friend_reward_days'=> 30,
            'referrer_reward_days' => 7,
            'stats'             => [
                'total_referred'   => (int)($stats['total_referred'] ?? 0),
                'qualified_count'  => (int)($stats['qualified_count'] ?? 0),
                'pending_count'    => (int)($stats['pending_count'] ?? 0),
                'total_reward_days'=> $rewardDays
            ],
            'history'           => $history
        ], 'Referral dashboard loaded');
    }

    /**
     * Validate a referral code.
     */
    public static function validateCode() {
        $db = Database::getConnection();
        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $code = strtoupper(trim($input['code'] ?? ''));

        if (empty($code)) {
            Response::error('Referral code is required', 400);
        }

        $stmt = $db->prepare("
            SELECT rc.code, u.full_name AS referrer_name, rc.user_id AS referrer_id
            FROM referral_codes rc
            JOIN users u ON rc.user_id = u.id
            WHERE rc.code = ? AND rc.status = 'active'
        ");
        $stmt->execute([$code]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            Response::error('Invalid or expired referral code', 404);
        }

        Response::json([
            'is_valid'      => true,
            'code'          => $row['code'],
            'referrer_name' => $row['referrer_name'],
            'benefit'       => '30 Days Free Premium Pass'
        ], 'Valid referral code');
    }

    /**
     * Attribute a referral during registration.
     */
    public static function attributeReferral($referredUserId, $code) {
        $db = Database::getConnection();
        $code = strtoupper(trim($code));
        if (empty($code)) return false;

        $stmt = $db->prepare("SELECT user_id FROM referral_codes WHERE code = ? AND status = 'active'");
        $stmt->execute([$code]);
        $referrerId = (int)$stmt->fetchColumn();

        // Prevent self-referral
        if (!$referrerId || $referrerId === (int)$referredUserId) {
            return false;
        }

        try {
            $ins = $db->prepare("
                INSERT INTO referrals (referrer_user_id, referred_user_id, referral_code, status)
                VALUES (?, ?, ?, 'attributed')
                ON DUPLICATE KEY UPDATE referral_code = VALUES(referral_code)
            ");
            $ins->execute([$referrerId, $referredUserId, $code]);
            return true;
        } catch (Exception $e) {
            return false;
        }
    }

    /**
     * Qualification Service Hook: Triggered upon first completed test.
     * PRD §17: Awards 30 days to student + 7 days extension to referrer.
     */
    public static function qualifyReferral($userId) {
        $db = Database::getConnection();

        $refStmt = $db->prepare("
            SELECT * FROM referrals
            WHERE referred_user_id = ? AND status IN ('attributed', 'pending_qualification')
        ");
        $refStmt->execute([$userId]);
        $referral = $refStmt->fetch(PDO::FETCH_ASSOC);

        if (!$referral) {
            return false; // Not an attributed user or already qualified
        }

        $referralId  = (int)$referral['id'];
        $referrerId  = (int)$referral['referrer_user_id'];
        $friendId    = (int)$userId;

        $db->beginTransaction();
        try {
            // 1. Reward Friend: 30 days premium
            $friendKey = "REF_FRIEND_{$referralId}_{$friendId}";
            $insRew1 = $db->prepare("
                INSERT INTO referral_rewards (referral_id, beneficiary_user_id, reward_type, reward_days, idempotency_key, status)
                VALUES (?, ?, 'premium_days', 30, ?, 'issued')
                ON DUPLICATE KEY UPDATE status = 'issued'
            ");
            $insRew1->execute([$referralId, $friendId, $friendKey]);
            self::extendUserSubscription($db, $friendId, 30);

            // 2. Reward Referrer: 7 days premium
            $referrerKey = "REF_REFERRER_{$referralId}_{$referrerId}";
            $insRew2 = $db->prepare("
                INSERT INTO referral_rewards (referral_id, beneficiary_user_id, reward_type, reward_days, idempotency_key, status)
                VALUES (?, ?, 'premium_days', 7, ?, 'issued')
                ON DUPLICATE KEY UPDATE status = 'issued'
            ");
            $insRew2->execute([$referralId, $referrerId, $referrerKey]);
            self::extendUserSubscription($db, $referrerId, 7);

            // 3. Mark referral as rewarded
            $upRef = $db->prepare("
                UPDATE referrals
                SET status = 'rewarded', qualified_at = NOW()
                WHERE id = ?
            ");
            $upRef->execute([$referralId]);

            // 4. Send Notifications
            $notif = $db->prepare("INSERT INTO user_notifications (user_id, title, message, type) VALUES (?, ?, ?, 'referral_reward')");
            $notif->execute([$friendId, '🎁 30 Days Free Premium Unlocked!', 'Welcome to EXAMVERSE! Your 30-day free premium access has been activated.']);
            $notif->execute([$referrerId, '🎉 Referral Bonus Earned!', 'Your friend completed their first test! 7 days have been added to your premium pass.']);

            $db->commit();
            return true;
        } catch (Exception $e) {
            $db->rollBack();
            error_log('Failed to qualify referral: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Extend subscription expiry or grant initial pass.
     */
    private static function extendUserSubscription(&$db, $userId, $days) {
        $subStmt = $db->prepare("
            SELECT * FROM user_subscriptions
            WHERE user_id = ? AND status = 'active'
            ORDER BY expiry_date DESC LIMIT 1
        ");
        $subStmt->execute([$userId]);
        $sub = $subStmt->fetch(PDO::FETCH_ASSOC);

        if ($sub && strtotime($sub['expiry_date']) > time()) {
            // Extend from existing expiry
            $newExpiry = date('Y-m-d H:i:s', strtotime("+{$days} days", strtotime($sub['expiry_date'])));
            $upSub = $db->prepare("UPDATE user_subscriptions SET expiry_date = ? WHERE id = ?");
            $upSub->execute([$newExpiry, $sub['id']]);
        } else {
            // New subscription starting now
            $newExpiry = date('Y-m-d H:i:s', strtotime("+{$days} days"));
            $insSub = $db->prepare("
                INSERT INTO user_subscriptions (user_id, plan_id, status, expiry_date, created_at)
                VALUES (?, 1, 'active', ?, NOW())
                ON DUPLICATE KEY UPDATE status = 'active', expiry_date = VALUES(expiry_date)
            ");
            $insSub->execute([$userId, $newExpiry]);
        }
    }
}
