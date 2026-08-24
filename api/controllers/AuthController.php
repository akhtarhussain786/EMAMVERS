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
        $identity = isset($input['identity']) ? trim($input['identity']) : ''; // Email or Mobile
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
            WHERE u.email = :identity OR u.mobile = :identity
        ");
        $stmt->execute(['identity' => $identity]);
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

        if (!$fullName || !$email || !$mobile || !$password) {
            Response::error('Full Name, Email, Mobile and Password are required', 400);
        }

        $db = Database::getConnection();
        
        // Check duplicate
        $stmt = $db->prepare("SELECT id FROM users WHERE email = :email OR mobile = :mobile");
        $stmt->execute(['email' => $email, 'mobile' => $mobile]);
        if ($stmt->fetch()) {
            Response::error('User with this email or mobile already exists', 409);
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
}
