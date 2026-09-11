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
        
        $districtsByState = [
            'Bihar' => ['Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Darbhanga', 'Purnia', 'Rohtas (Sasaram)', 'Begusarai', 'Saran (Chhapra)', 'Vaishali', 'Samastipur', 'Nalanda (Bihar Sharif)', 'Munger', 'Siwan', 'East Champaran (Motihari)', 'West Champaran (Bettiah)', 'Katihar', 'Bhojpur (Ara)', 'Madhubani', 'Saharsa', 'Nawada', 'Buxar', 'Kishanganj', 'Sitamarhi', 'Gopalganj', 'Jehanabad', 'Aurangabad', 'Banka', 'Khagaria', 'Jamui', 'Arwal', 'Lakhisarai', 'Sheikhpura', 'Kaimur (Bhabua)', 'Madhepura', 'Supaul', 'Sheohar', 'Araria'],
            'Madhya Pradesh' => ['Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain', 'Sagar', 'Rewa', 'Satna', 'Ratlam', 'Chhindwara', 'Dewas', 'Khandwa', 'Khargone', 'Shivpuri', 'Vidisha', 'Morena', 'Bhind', 'Sehore', 'Hoshangabad (Narmadapuram)', 'Katni', 'Singrauli', 'Damoh', 'Mandsaur', 'Neemuch', 'Shahdol', 'Betul', 'Guna', 'Dhar', 'Raisen', 'Balaghat', 'Seoni', 'Datia', 'Narsinghpur', 'Tikamgarh', 'Mandla', 'Barwani', 'Ashoknagar', 'Harda', 'Anuppur', 'Panna', 'Alirajpur', 'Burhanpur', 'Sidhi', 'Sheopur', 'Dindori', 'Umaria', 'Niwari'],
            'Uttar Pradesh' => ['Lucknow', 'Kanpur Nagar', 'Varanasi', 'Prayagraj (Allahabad)', 'Agra', 'Meerut', 'Noida (Gautam Buddha Nagar)', 'Ghaziabad', 'Bareilly', 'Aligarh', 'Moradabad', 'Saharanpur', 'Gorakhpur', 'Faizabad (Ayodhya)', 'Jhansi', 'Muzaffarnagar', 'Mathura', 'Budaun', 'Rampur', 'Shahjahanpur', 'Firozabad', 'Mainpuri', 'Etawah', 'Unnao', 'Rae Bareli', 'Sitapur', 'Hardoi', 'Lakhimpur Kheri', 'Sultanpur', 'Barabanki', 'Bahraich', 'Basti', 'Azamgarh', 'Ballia', 'Jaunpur', 'Mirzapur', 'Sonbhadra', 'Deoria', 'Ghazipur'],
            'Rajasthan' => ['Jaipur', 'Jodhpur', 'Kota', 'Bikaner', 'Ajmer', 'Udaipur', 'Bhilwara', 'Alwar', 'Bharatpur', 'Sikar', 'Pali', 'Sri Ganganagar', 'Chittorgarh', 'Jhunjhunu', 'Nagaur', 'Tonk', 'Hanumangarh', 'Beawar', 'Dausa', 'Sawai Madhopur', 'Churu', 'Barmer', 'Jaisalmer', 'Jalore', 'Banswara', 'Dungarpur', 'Pratapgarh', 'Rajsamand', 'Sirohi', 'Karauli', 'Dholpur', 'Bundi', 'Baran'],
            'Delhi NCR' => ['New Delhi', 'Central Delhi', 'South Delhi', 'North Delhi', 'East Delhi', 'West Delhi', 'North East Delhi', 'South West Delhi', 'North West Delhi', 'South East Delhi', 'Shahdara'],
            'Maharashtra' => ['Mumbai City', 'Mumbai Suburban', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Chhatrapati Sambhajinagar (Aurangabad)', 'Solapur', 'Amravati', 'Kolhapur', 'Navi Mumbai', 'Nanded', 'Sangli', 'Jalgaon', 'Akola', 'Latur', 'Dhule', 'Ahmednagar', 'Chandrapur', 'Parbhani', 'Satara', 'Beed', 'Yavatmal'],
            'West Bengal' => ['Kolkata', 'North 24 Parganas', 'South 24 Parganas', 'Howrah', 'Hooghly', 'Purba Medinipur', 'Paschim Medinipur', 'Purba Bardhaman', 'Paschim Bardhaman', 'Murshidabad', 'Nadia', 'Malda', 'Jalpaiguri', 'Darjeeling', 'Siliguri', 'Birbhum', 'Bankura', 'Purulia', 'Cooch Behar'],
            'Haryana' => ['Gurugram (Gurgaon)', 'Faridabad', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal', 'Sonipat', 'Panchkula', 'Bhiwani', 'Sirsa', 'Jhajjar', 'Jind', 'Kurukshetra', 'Rewari', 'Kaithal', 'Palwal', 'Fatehabad', 'Mahendragarh', 'Nuh', 'Charkhi Dadri'],
            'Punjab' => ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali (SAS Nagar)', 'Hoshiarpur', 'Pathankot', 'Moga', 'Firozpur', 'Gurdaspur', 'Barnala', 'Sangrur', 'Kapurthala', 'Faridkot', 'Muktsar', 'Fatehgarh Sahib', 'Mansa', 'Rupnagar', 'Fazilka', 'Malerkotla'],
            'Jharkhand' => ['Ranchi', 'Jamshedpur (East Singhbhum)', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh', 'Giridih', 'Ramgarh', 'Dumka', 'Palamu (Medininagar)', 'Chaibasa (West Singhbhum)', 'Godda', 'Sahebganj', 'Koderma', 'Chatra', 'Gumla', 'Latehar', 'Pakur', 'Garhwa', 'Simdega', 'Khunti', 'Lohardaga', 'Jamtara', 'Saraikela Kharsawan'],
            'Chhattisgarh' => ['Raipur', 'Bhilai / Durg', 'Bilaspur', 'Korba', 'Rajnandgaon', 'Jagdalpur (Bastar)', 'Ambikapur (Surguja)', 'Raigarh', 'Dhamtari', 'Mahasamund', 'Kanker', 'Kawardha (Kabirdham)', 'Janjgir-Champa', 'Bemetara', 'Balod', 'Baloda Bazar', 'Gariaband', 'Mungeli', 'Surajpur', 'Balrampur', 'Kondagaon', 'Sukma', 'Bijapur', 'Narayanpur', 'Gaurela-Pendra-Marwahi', 'Manendragarh-Chirmiri-Bharatpur', 'Mohla-Manpur-Ambagarh Chowki', 'Sakti', 'Sarangarh-Bilaigarh', 'Khairagarh-Chhuikhadan-Gandai'],
            'Uttarakhand' => ['Dehradun', 'Haridwar', 'Nainital', 'Udham Singh Nagar (Rudrapur)', 'Roorkee', 'Rishikesh', 'Haldwani', 'Pauri Garhwal', 'Tehri Garhwal', 'Almora', 'Pithoragarh', 'Chamoli', 'Uttarkashi', 'Bageshwar', 'Champawat', 'Rudraprayag']
        ];
        
        Response::json([
            'states' => $states,
            'qualifications' => $qualifications,
            'districts_by_state' => $districtsByState
        ], 'States, Districts and Qualifications loaded successfully');
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

        RateLimit::enforce('login_ip', RateLimit::clientIp(), 50, 300);
        RateLimit::enforce('login_identity', $identity, 20, 300);

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
            // Auto-heal default demo student or teacher account if logging in with password123
            if ($password === 'password123' && in_array(strtolower($identity), ['demo@examverse.com', 'teacher@examverse.com', '9876543200', '9876543299'], true)) {
                $isTeacher = in_array(strtolower($identity), ['teacher@examverse.com', '9876543299'], true);
                $dEmail = $isTeacher ? 'teacher@examverse.com' : 'demo@examverse.com';
                $dMobile = $isTeacher ? '9876543299' : '9876543200';
                $dName = $isTeacher ? 'Faculty Teacher' : 'Demo Student';
                $dType = $isTeacher ? 'teacher' : 'student';
                $dHash = password_hash('password123', PASSWORD_BCRYPT);
                
                if ($user) {
                    $db->prepare("UPDATE users SET password_hash = ?, is_verified = 1, status = 'active' WHERE id = ?")->execute([$dHash, $user['id']]);
                    $user['status'] = 'active';
                    $user['is_verified'] = 1;
                } else {
                    $db->prepare("INSERT INTO users (full_name, email, mobile, password_hash, user_type, is_verified, status) VALUES (?, ?, ?, ?, ?, 1, 'active')")->execute([$dName, $dEmail, $dMobile, $dHash, $dType]);
                    $newId = $db->lastInsertId();
                    if ($isTeacher) {
                        try {
                            $db->prepare("INSERT INTO teacher_profiles (user_id, display_name, qualification, specialisation, status) VALUES (?, 'Prof. Sharma', 'M.Sc Mathematics, B.Ed', 'Quantitative Aptitude', 'active')")->execute([$newId]);
                        } catch (Exception $eT) {}
                    }
                    $stmt->execute(['email' => $identity, 'mobile' => $identity]);
                    $user = $stmt->fetch();
                }
            } else {
                Response::error('Invalid email/mobile or password', 401);
            }
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

        $district = isset($input['district']) ? trim($input['district']) : null;
        $userType = isset($input['user_type']) && in_array(strtolower(trim($input['user_type'])), ['student', 'teacher']) ? strtolower(trim($input['user_type'])) : 'student';

        $passwordHash = password_hash($password, PASSWORD_BCRYPT);
        try {
            $stmt = $db->prepare("
                INSERT INTO users (full_name, email, mobile, mobile_hash, password_hash, state_id, district, qualification_id, user_type, is_verified) 
                VALUES (:full_name, :email, :mobile, :mobile_hash, :password_hash, :state_id, :district, :qualification_id, :user_type, 1)
            ");
            $stmt->execute([
                'full_name' => $fullName,
                'email' => $email,
                'mobile' => $mobile,
                'mobile_hash' => self::mobileHash($mobile),
                'password_hash' => $passwordHash,
                'state_id' => $stateId,
                'district' => $district,
                'qualification_id' => $qualificationId,
                'user_type' => $userType
            ]);
        } catch (PDOException $e) {
            // Auto-heal missing column(s) on live database
            if (strpos($e->getMessage(), '1054') !== false || stripos($e->getMessage(), 'Unknown column') !== false) {
                try {
                    $db->exec("ALTER TABLE users ADD COLUMN state_id INT NULL AFTER password_hash");
                } catch (Exception $ex) {}
                try {
                    $db->exec("ALTER TABLE users ADD COLUMN district VARCHAR(100) NULL AFTER state_id");
                } catch (Exception $ex) {}
                try {
                    $db->exec("ALTER TABLE users ADD COLUMN qualification_id INT NULL AFTER district");
                } catch (Exception $ex) {}
                try {
                    $db->exec("ALTER TABLE users ADD COLUMN user_type ENUM('student','creator','teacher') NOT NULL DEFAULT 'student' AFTER status");
                } catch (Exception $ex) {}

                try {
                    $stmt = $db->prepare("
                        INSERT INTO users (full_name, email, mobile, mobile_hash, password_hash, state_id, district, qualification_id, user_type, is_verified) 
                        VALUES (:full_name, :email, :mobile, :mobile_hash, :password_hash, :state_id, :district, :qualification_id, :user_type, 1)
                    ");
                    $stmt->execute([
                        'full_name' => $fullName,
                        'email' => $email,
                        'mobile' => $mobile,
                        'mobile_hash' => self::mobileHash($mobile),
                        'password_hash' => $passwordHash,
                        'state_id' => $stateId,
                        'district' => $district,
                        'qualification_id' => $qualificationId,
                        'user_type' => $userType
                    ]);
                } catch (Exception $e2) {
                    $stmt = $db->prepare("
                        INSERT INTO users (full_name, email, mobile, mobile_hash, password_hash, user_type, is_verified) 
                        VALUES (:full_name, :email, :mobile, :mobile_hash, :password_hash, :user_type, 1)
                    ");
                    $stmt->execute([
                        'full_name' => $fullName,
                        'email' => $email,
                        'mobile' => $mobile,
                        'mobile_hash' => self::mobileHash($mobile),
                        'password_hash' => $passwordHash,
                        'user_type' => $userType
                    ]);
                }
            } else {
                throw $e;
            }
        }

        $userId = $db->lastInsertId();

        // If teacher, initialize teacher profile
        if ($userType === 'teacher') {
            try {
                $specialisation = isset($input['specialisation']) && trim($input['specialisation']) !== '' ? trim($input['specialisation']) : 'Faculty Educator';
                $teacherQual = isset($input['teacher_qualification']) && trim($input['teacher_qualification']) !== '' ? trim($input['teacher_qualification']) : 'Teaching Degree / Post Graduate';
                $db->prepare("
                    INSERT INTO teacher_profiles (user_id, display_name, qualification, specialisation, status) 
                    VALUES (?, ?, ?, ?, 'active')
                    ON DUPLICATE KEY UPDATE display_name = VALUES(display_name), status = 'active'
                ")->execute([$userId, $fullName, $teacherQual, $specialisation]);
            } catch (Exception $eT) {
                // Non-fatal if table not migrated yet
            }
        }

        $token = AuthToken::generate($userId, $userType, ['name' => $fullName]);

        // Check and attribute referral if provided
        $referralCode = trim($input['referral_code'] ?? '');
        if ($referralCode) {
            require_once __DIR__ . '/ReferralController.php';
            ReferralController::attributeReferral($userId, $referralCode);
        }

        // Fetch inserted user
        $user = null;
        try {
            $stmtUser = $db->prepare("
                SELECT u.id, u.full_name, u.email, u.mobile, u.state_id, u.district, u.qualification_id, u.user_type, s.name as state_name, q.name as qualification_name
                FROM users u
                LEFT JOIN states s ON u.state_id = s.id
                LEFT JOIN qualifications q ON u.qualification_id = q.id
                WHERE u.id = :id
            ");
            $stmtUser->execute(['id' => $userId]);
            $user = $stmtUser->fetch();
        } catch (Exception $e) {
            $stmtUser = $db->prepare("SELECT id, full_name, email, mobile, user_type FROM users WHERE id = :id");
            $stmtUser->execute(['id' => $userId]);
            $user = $stmtUser->fetch();
        }

        Response::json([
            'token' => $token,
            'account_type' => $userType,
            'user_type' => $userType,
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

        // Dispatch OTP via configured SMS Gateway service
        require_once __DIR__ . '/../services/SmsService.php';
        $smsResult = SmsService::sendOtp($identity, $otp);

        if (Config::isDebug()) {
            Response::json([
                'dev_otp' => $otp,
                'sms_status' => $smsResult
            ], 'OTP generated. Debug mode: code returned in dev_otp.');
        }

        if (!$smsResult['success'] && $smsResult['provider'] !== 'dev_mock') {
            Response::error('Failed to send SMS: ' . $smsResult['message'], 502);
        }

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
