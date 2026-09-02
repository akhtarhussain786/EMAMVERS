<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/auth_token.php';
require_once __DIR__ . '/../utils/rate_limit.php';
require_once __DIR__ . '/../config/config.php';

class AuthController {
    public static function getStatesAndQualifications() {
        $db = Database::getConnection();
        $states = $db->query("SELECT id, code, name FROM states ORDER BY name ASC")->fetchAll();
        $qualifications = $db->query("SELECT id, code, name FROM qualifications ORDER BY id ASC")->fetchAll();
        
        Response::json([
            'states' => $states,
            'qualifications' => $qualifications
        ], 'States and Qualifications loaded successfully');
    }

    public static function login() {
        $input = json_decode(file_get_contents('php://input'), true);
        $identity = '';
        if (isset($input['identity']) && trim($input['identity']) !== '') {
            $identity = trim($input['identity']);
        } elseif (isset($input['mobile_or_email']) && trim($input['mobile_or_email']) !== '') {
            $identity = trim($input['mobile_or_email']);
        } elseif (isset($input['email']) && trim($input['email']) !== '') {
            $identity = trim($input['email']);
        } elseif (isset($input['mobile']) && trim($input['mobile']) !== '') {
            $identity = trim($input['mobile']);
        }

        $password = isset($input['password']) ? trim($input['password']) : '';

        if (!$identity || !$password) {
            Response::error('Email/Mobile and Password are required', 400);
        }

        RateLimit::enforce('login_ip', RateLimit::clientIp(), 20, 900);
        RateLimit::enforce('login_identity', $identity, 5, 900);

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT u.*, s.name as state_name, q.name as qualification_name 
            FROM users u
            LEFT JOIN states s ON u.state_id = s.id
            LEFT JOIN qualifications q ON u.qualification_id = q.id
            WHERE u.email = :email OR u.mobile = :mobile
        ");
        $stmt->execute(['email' => $identity, 'mobile' => $identity]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            Response::error('Invalid email/mobile or password', 401);
        }

        RateLimit::clear('login_ip', RateLimit::clientIp());
        RateLimit::clear('login_identity', $identity);

        if ($user['status'] === 'suspended') {
            Response::error('Account has been suspended. Please contact support.', 403);
        }

        unset($user['password_hash']);

        // Teachers get their own token type so student-only endpoints reject them
        // and the app knows which dashboard to open. Creators are students who
        // also sell material, so they keep student access.
        $accountType = ($user['user_type'] ?? 'student') === 'teacher' ? 'teacher' : 'student';
        $token = AuthToken::generate($user['id'], $accountType, ['name' => $user['full_name']]);

        Response::json([
            'token'        => $token,
            'account_type' => $accountType,
            'user_type'    => $user['user_type'] ?? 'student',
            'user'         => $user
        ], 'Login successful');
    }

    public static function signup() {
        $input = json_decode(file_get_contents('php://input'), true);
        $fullName = isset($input['full_name']) ? trim($input['full_name']) : '';
        $email = isset($input['email']) ? trim($input['email']) : '';
        $mobile = isset($input['mobile']) ? trim($input['mobile']) : '';
        $password = isset($input['password']) ? trim($input['password']) : '';
        $stateId = isset($input['state_id']) ? intval($input['state_id']) : null;
        $qualificationId = isset($input['qualification_id']) ? intval($input['qualification_id']) : null;

        if (!$fullName || (!$email && !$mobile) || !$password) {
            Response::error('Full Name, Email/Mobile and Password are required', 400);
        }

        if (strlen($password) < 8) {
            Response::error('Password must be at least 8 characters long', 422);
        }

        RateLimit::enforce('signup_ip', RateLimit::clientIp(), 10, 3600);

        // If email field does not contain '@', treat it as mobile number
        if ($email && strpos($email, '@') === false) {
            $mobile = $email;
            $email = $mobile . '@examverse.com';
        }

        if (!$email) {
            $email = $mobile . '@examverse.com';
        }

        // Email-only signups get a reserved, guaranteed-unique placeholder so
        // they never collide on the UNIQUE(mobile) constraint.
        if (!$mobile) {
            $db = Database::getConnection();
            do {
                $mobile = 'NA-' . bin2hex(random_bytes(8));
                $probe = $db->prepare("SELECT id FROM users WHERE mobile = :m");
                $probe->execute(['m' => $mobile]);
            } while ($probe->fetch());
        }

        $db = Database::getConnection();
        
        // Check duplicate
        $stmt = $db->prepare("SELECT id, email, mobile FROM users WHERE email = :email OR mobile = :mobile");
        $stmt->execute(['email' => $email, 'mobile' => $mobile]);
        $existing = $stmt->fetch();
        if ($existing) {
            if ($existing['email'] === $email) {
                Response::error('Account with this email already exists. Please Log In.', 409);
            } else {
                Response::error('Account with this mobile number already exists. Please Log In.', 409);
            }
        }

        $passwordHash = password_hash($password, PASSWORD_BCRYPT);
        $stmt = $db->prepare("
            INSERT INTO users (full_name, email, mobile, mobile_hash, password_hash, state_id, qualification_id, is_verified) 
            VALUES (:full_name, :email, :mobile, :mobile_hash, :password_hash, :state_id, :qualification_id, 1)
        ");
        $stmt->execute([
            'full_name' => $fullName,
            'email' => $email,
            'mobile' => $mobile,
            'mobile_hash' => self::mobileHash($mobile),
            'password_hash' => $passwordHash,
            'state_id' => $stateId,
            'qualification_id' => $qualificationId
        ]);

        $userId = $db->lastInsertId();
        $token = AuthToken::generate($userId, 'student');

        // Fetch inserted user
        $stmtUser = $db->prepare("
            SELECT u.id, u.full_name, u.email, u.mobile, u.state_id, u.qualification_id, s.name as state_name, q.name as qualification_name
            FROM users u
            LEFT JOIN states s ON u.state_id = s.id
            LEFT JOIN qualifications q ON u.qualification_id = q.id
            WHERE u.id = :id
        ");
        $stmtUser->execute(['id' => $userId]);
        $user = $stmtUser->fetch();

        Response::json([
            'token' => $token,
            'user' => $user
        ], 'Account created successfully', 'success', 201);
    }

    /**
     * SHA-256 of the digits-only mobile number, used for privacy-preserving
     * contact matching. Placeholder numbers hash to NULL so they never match.
     */
    public static function mobileHash($mobile) {
        $digits = preg_replace('/[^0-9]/', '', (string)$mobile);
        if (strlen($digits) < 10) return null;
        // Match on the last 10 digits so country-code prefixes do not matter.
        return hash('sha256', substr($digits, -10));
    }

    public static function sendOtp() {
        $input = json_decode(file_get_contents('php://input'), true);
        $identity = isset($input['identity']) ? trim($input['identity']) : '';
        if (!$identity) Response::error('Email or mobile required', 400);

        RateLimit::enforce('otp_ip', RateLimit::clientIp(), 15, 3600);
        RateLimit::enforce('otp_identity', $identity, 5, 3600);

        $db = Database::getConnection();

        // Invalidate any outstanding codes so only the newest one works.
        $db->prepare("UPDATE user_otps SET is_used = 1 WHERE mobile_or_email = :identity AND is_used = 0")
           ->execute(['identity' => $identity]);

        $otp = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Stored as a hash: a database read must not yield usable codes.
        $stmt = $db->prepare("INSERT INTO user_otps (mobile_or_email, otp_code, expires_at) VALUES (:identity, :otp, NOW() + INTERVAL 10 MINUTE)");
        $stmt->execute(['identity' => $identity, 'otp' => self::hashOtp($identity, $otp)]);

        // Delivery (SMS/email) is not wired up yet. Outside debug the code is
        // never returned to the client; it is written to the error log so a
        // local operator can still complete the flow.
        if (Config::isDebug()) {
            Response::json(['dev_otp' => $otp], 'OTP generated. Debug mode: code returned in dev_otp.');
        }

        error_log("EXAMVERSE OTP for {$identity}: {$otp}");
        Response::json(null, 'If that account exists, an OTP has been sent.');
    }

    /** OTPs are stored hashed and bound to the identity they were issued for. */
    private static function hashOtp($identity, $otp) {
        return hash_hmac('sha256', strtolower(trim($identity)) . '|' . $otp, Config::appKey());
    }

    /**
     * Returns the matching unused, unexpired OTP row, or null.
     * Does not consume it — callers decide when to burn the code.
     */
    private static function findValidOtp($db, $identity, $otp) {
        $stmt = $db->prepare("
            SELECT id FROM user_otps
            WHERE mobile_or_email = :identity
              AND otp_code = :otp
              AND is_used = 0
              AND expires_at >= NOW()
            ORDER BY id DESC LIMIT 1
        ");
        $stmt->execute(['identity' => $identity, 'otp' => self::hashOtp($identity, $otp)]);
        return $stmt->fetch() ?: null;
    }

    public static function verifyOtp() {
        $input = json_decode(file_get_contents('php://input'), true);
        $identity = isset($input['identity']) ? trim($input['identity']) : '';
        $otp = isset($input['otp']) ? trim($input['otp']) : '';

        if (!$identity || !$otp) Response::error('Identity and OTP required', 400);

        RateLimit::enforce('otp_verify_ip', RateLimit::clientIp(), 20, 900);
        RateLimit::enforce('otp_verify_identity', $identity, 6, 900);

        $db = Database::getConnection();
        if (!self::findValidOtp($db, $identity, $otp)) {
            Response::error('Invalid or expired OTP', 400);
        }

        // Deliberately not consumed here: resetPassword re-checks and burns it,
        // so a verified-but-abandoned flow cannot leave a spent code behind.
        Response::json(null, 'OTP verified successfully');
    }

    public static function resetPassword() {
        $input = json_decode(file_get_contents('php://input'), true);
        $identity = isset($input['identity']) ? trim($input['identity']) : '';
        $otp = isset($input['otp']) ? trim($input['otp']) : '';
        $newPassword = isset($input['new_password']) ? trim($input['new_password']) : '';

        if (!$identity || !$newPassword) {
            Response::error('Identity and new password are required', 422);
        }
        if (!$otp) {
            Response::error('OTP is required to reset a password', 422);
        }
        if (strlen($newPassword) < 8) {
            Response::error('Password must be at least 8 characters long', 422);
        }

        RateLimit::enforce('reset_ip', RateLimit::clientIp(), 15, 900);
        RateLimit::enforce('reset_identity', $identity, 5, 900);

        $db = Database::getConnection();

        // The OTP is the entire authorisation for this operation — verify first.
        $otpRecord = self::findValidOtp($db, $identity, $otp);
        if (!$otpRecord) {
            Response::error('Invalid or expired OTP', 400);
        }

        $stmtUser = $db->prepare("SELECT id FROM users WHERE email = :u1 OR mobile = :u2");
        $stmtUser->execute(['u1' => $identity, 'u2' => $identity]);
        $user = $stmtUser->fetch();

        if (!$user) {
            // Burn the code anyway so it cannot be reused to probe for accounts.
            $db->prepare("UPDATE user_otps SET is_used = 1 WHERE id = :id")->execute(['id' => $otpRecord['id']]);
            Response::error('Invalid or expired OTP', 400);
        }

        $db->beginTransaction();
        try {
            $newHash = password_hash($newPassword, PASSWORD_BCRYPT);
            $db->prepare("UPDATE users SET password_hash = :hash WHERE id = :id")
               ->execute(['hash' => $newHash, 'id' => $user['id']]);
            // Single-use: burn this code and any other outstanding one.
            $db->prepare("UPDATE user_otps SET is_used = 1 WHERE mobile_or_email = :identity AND is_used = 0")
               ->execute(['identity' => $identity]);
            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }

        RateLimit::clear('reset_identity', $identity);
        Response::json(['updated' => true], 'Password reset successful. Please log in with your new password.');
    }
}
