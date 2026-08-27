<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/auth_token.php';

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

        if ($user['status'] === 'suspended') {
            Response::error('Account has been suspended. Please contact support.', 403);
        }

        unset($user['password_hash']);
        $token = AuthToken::generate($user['id'], 'student');

        Response::json([
            'token' => $token,
            'user' => $user
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

        // If email field does not contain '@', treat it as mobile number
        if ($email && strpos($email, '@') === false) {
            $mobile = $email;
            $email = $mobile . '@examverse.com';
        }

        if (!$email) {
            $email = $mobile . '@examverse.com';
        }

        if (!$mobile) {
            $mobile = '98' . substr(strval(microtime(true) * 10000), -8);
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
            INSERT INTO users (full_name, email, mobile, password_hash, state_id, qualification_id, is_verified) 
            VALUES (:full_name, :email, :mobile, :password_hash, :state_id, :qualification_id, 1)
        ");
        $stmt->execute([
            'full_name' => $fullName,
            'email' => $email,
            'mobile' => $mobile,
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

    public static function sendOtp() {
        $input = json_decode(file_get_contents('php://input'), true);
        $identity = isset($input['identity']) ? trim($input['identity']) : '';
        if (!$identity) Response::error('Email or mobile required', 400);

        $otp = '123456'; // Default OTP for development baseline
        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT INTO user_otps (mobile_or_email, otp_code, expires_at) VALUES (:identity, :otp, NOW() + INTERVAL 10 MINUTE)");
        $stmt->execute(['identity' => $identity, 'otp' => $otp]);

        Response::json(['otp' => $otp], 'OTP sent successfully (Demo OTP: 123456)');
    }

    public static function verifyOtp() {
        $input = json_decode(file_get_contents('php://input'), true);
        $identity = isset($input['identity']) ? trim($input['identity']) : '';
        $otp = isset($input['otp']) ? trim($input['otp']) : '';

        if (!$identity || !$otp) Response::error('Identity and OTP required', 400);

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT id FROM user_otps WHERE mobile_or_email = :identity AND otp_code = :otp AND is_used = 0 AND expires_at >= NOW() ORDER BY id DESC LIMIT 1");
        $stmt->execute(['identity' => $identity, 'otp' => $otp]);
        $record = $stmt->fetch();

        if (!$record) {
            Response::error('Invalid or expired OTP', 400);
        }

        $db->prepare("UPDATE user_otps SET is_used = 1 WHERE id = :id")->execute(['id' => $record['id']]);
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

        $db = Database::getConnection();

        // Find user
        $stmtUser = $db->prepare("SELECT id FROM users WHERE email = :u1 OR mobile = :u2");
        $stmtUser->execute(['u1' => $identity, 'u2' => $identity]);
        $user = $stmtUser->fetch();

        if (!$user) {
            Response::error('User not found with provided email/mobile', 404);
        }

        $newHash = password_hash($newPassword, PASSWORD_BCRYPT);
        $updateStmt = $db->prepare("UPDATE users SET password_hash = :hash WHERE id = :id");
        $updateStmt->execute(['hash' => $newHash, 'id' => $user['id']]);

        Response::json(['updated' => true], 'Password reset successful. Please log in with your new password.');
    }
}
