<?php
require_once __DIR__ . '/includes/session.php';
require_once __DIR__ . '/../api/config/db.php';
require_once __DIR__ . '/../api/utils/rate_limit.php';

adminSessionStart();

$error = '';
$success = '';

// Logout action handling
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
    header('Location: login.php');
    exit;
}

if (adminIsLoggedIn()) {
    header('Location: index.php');
    exit;
}

// Remember Me Cookie Check
$rememberedUser = '';
$rememberChecked = false;
if (isset($_COOKIE['examverse_remember_admin']) && !empty($_COOKIE['examverse_remember_admin'])) {
    $rememberedUser = trim($_COOKIE['examverse_remember_admin']);
    $rememberChecked = true;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = (string)($_POST['password'] ?? '');
    $rememberMe = !empty($_POST['remember_me']);

    // CSRF protection
    if (!adminCsrfValid($_POST['csrf_token'] ?? null)) {
        $error = 'Your security token expired. Please try signing in again.';
    } elseif ($username && $password) {
        $limitIp = Config::isDebug() ? 100 : 20;
        $limitUser = Config::isDebug() ? 50 : 10;
        RateLimit::enforceOrFlag($limited, 'panel_login_ip', RateLimit::clientIp(), $limitIp, 300);
        RateLimit::enforceOrFlag($limitedUser, 'panel_login_user', $username, $limitUser, 300);

        if ($limited || $limitedUser) {
            $error = 'Too many failed sign-in attempts. Please wait 5 minutes and try again.';
        } else {
            $db = Database::getConnection();

            // Auto-seed default super-admin if table is empty
            try {
                $checkAdmins = $db->query("SELECT COUNT(*) FROM admins")->fetchColumn();
                if ((int)$checkAdmins === 0) {
                    $defaultHash = password_hash('Admin@12345678', PASSWORD_BCRYPT);
                    $seedStmt = $db->prepare("INSERT INTO admins (username, email, password_hash, full_name, role, status) VALUES ('admin', 'admin@examverse.com', :h, 'Super Administrator', 'super_admin', 'active')");
                    $seedStmt->execute(['h' => $defaultHash]);
                }
            } catch (Exception $ignored) {}

            $stmt = $db->prepare("SELECT * FROM admins WHERE (username = :u1 OR email = :u2) AND status = 'active'");
            $stmt->execute(['u1' => $username, 'u2' => $username]);
            $admin = $stmt->fetch();

            if ($admin && password_verify($password, $admin['password_hash'])) {
                RateLimit::clear('panel_login_ip', RateLimit::clientIp());
                RateLimit::clear('panel_login_user', $username);

                // Remember Me Cookie Handling
                $cookieHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
                              || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
                if ($rememberMe) {
                    // Set cookie for 30 days
                    setcookie('examverse_remember_admin', $username, [
                        'expires'  => time() + (30 * 86400),
                        'path'     => '/',
                        'httponly' => true,
                        'secure'   => $cookieHttps,
                        'samesite' => 'Lax',
                    ]);
                } else {
                    // Clear remember cookie if unchecked
                    if (isset($_COOKIE['examverse_remember_admin'])) {
                        setcookie('examverse_remember_admin', '', [
                            'expires'  => time() - 3600,
                            'path'     => '/',
                            'httponly' => true,
                            'secure'   => $cookieHttps,
                            'samesite' => 'Lax',
                        ]);
                    }
                }

                // Defeat session fixation
                session_regenerate_id(true);

                $_SESSION['admin_logged_in'] = true;
                $_SESSION['admin_last_seen'] = time();
                $_SESSION['admin_user'] = [
                    'id' => $admin['id'],
                    'username' => $admin['username'],
                    'full_name' => $admin['full_name'],
                    'role' => $admin['role'],
                    'email' => $admin['email']
                ];

                // Audit Log Entry
                $stmtAudit = $db->prepare("INSERT INTO admin_audit_logs (admin_id, action, entity_type, details) VALUES (:aid, 'LOGIN', 'ADMIN', 'Admin logged into Admin Control Center')");
                $stmtAudit->execute(['aid' => $admin['id']]);

                header('Location: index.php');
                exit;
            } else {
                $error = 'Invalid username/email or password.';
                $rememberedUser = $username;
                $rememberChecked = $rememberMe;
            }
        }
    } else {
        $error = 'Please enter both your username/email and password.';
        $rememberedUser = $username;
        $rememberChecked = $rememberMe;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EXAMVERSE • Admin Portal</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-deep: #030712;
            --bg-surface: rgba(15, 23, 42, 0.75);
            --bg-input: rgba(30, 41, 59, 0.6);
            --border-subtle: rgba(255, 255, 255, 0.08);
            --border-focus: #3b82f6;
            --primary: #3b82f6;
            --primary-hover: #2563eb;
            --primary-glow: rgba(59, 130, 246, 0.35);
            --accent-cyan: #06b6d4;
            --accent-emerald: #10b981;
            --accent-danger: #f43f5e;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --text-dim: #64748b;
            --radius-card: 20px;
            --radius-btn: 12px;
            --radius-input: 12px;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            min-height: 100vh;
            font-family: 'Plus Jakarta Sans', system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-deep);
            color: var(--text-main);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
            position: relative;
            overflow-x: hidden;
        }

        /* Ambient Background Mesh & Lighting Effects */
        .ambient-glow-1 {
            position: fixed;
            top: -10%;
            left: -10%;
            width: 50vw;
            height: 50vw;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(37, 99, 235, 0.18) 0%, rgba(3, 7, 18, 0) 70%);
            filter: blur(80px);
            pointer-events: none;
            z-index: 0;
        }

        .ambient-glow-2 {
            position: fixed;
            bottom: -15%;
            right: -10%;
            width: 55vw;
            height: 55vw;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(14, 165, 233, 0.15) 0%, rgba(3, 7, 18, 0) 70%);
            filter: blur(90px);
            pointer-events: none;
            z-index: 0;
        }

        .bg-grid {
            position: fixed;
            inset: 0;
            background-image: 
                linear-gradient(to right, rgba(255, 255, 255, 0.025) 1px, transparent 1px),
                linear-gradient(to bottom, rgba(255, 255, 255, 0.025) 1px, transparent 1px);
            background-size: 40px 40px;
            mask-image: radial-gradient(circle at center, black 40%, transparent 80%);
            pointer-events: none;
            z-index: 0;
        }

        /* Login Container Card */
        .login-wrapper {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 440px;
        }

        .login-card {
            background: var(--bg-surface);
            backdrop-filter: blur(24px);
            -webkit-backdrop-filter: blur(24px);
            border: 1px solid var(--border-subtle);
            border-radius: var(--radius-card);
            padding: 2.75rem 2.25rem 2.25rem;
            box-shadow: 
                0 0 0 1px rgba(255, 255, 255, 0.05),
                0 25px 50px -12px rgba(0, 0, 0, 0.7),
                0 0 40px -10px var(--primary-glow);
            transition: transform 0.25s ease, box-shadow 0.25s ease;
        }

        /* Brand Header */
        .brand-header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .brand-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 14px;
            background: rgba(59, 130, 246, 0.12);
            border: 1px solid rgba(59, 130, 246, 0.25);
            border-radius: 9999px;
            font-size: 0.72rem;
            font-weight: 700;
            color: #60a5fa;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            margin-bottom: 1rem;
        }

        .brand-badge-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: #60a5fa;
            box-shadow: 0 0 8px #60a5fa;
            animation: pulse-dot 2s infinite ease-in-out;
        }

        @keyframes pulse-dot {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.4; transform: scale(0.85); }
        }

        .brand-title {
            font-size: 1.85rem;
            font-weight: 800;
            letter-spacing: -0.03em;
            color: #ffffff;
            line-height: 1.2;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 2px;
        }

        .brand-title span {
            background: linear-gradient(135deg, #60a5fa 0%, #38bdf8 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .brand-subtitle {
            color: var(--text-muted);
            font-size: 0.875rem;
            margin-top: 0.35rem;
            font-weight: 500;
        }

        /* Alert Banner */
        .alert-error {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            background: rgba(244, 63, 94, 0.12);
            border: 1px solid rgba(244, 63, 94, 0.3);
            color: #fda4af;
            padding: 0.85rem 1rem;
            border-radius: var(--radius-input);
            font-size: 0.85rem;
            line-height: 1.4;
            margin-bottom: 1.5rem;
            animation: shake 0.4s ease-in-out;
        }

        .alert-error svg {
            flex-shrink: 0;
            width: 18px;
            height: 18px;
            margin-top: 2px;
            color: var(--accent-danger);
        }

        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            20%, 60% { transform: translateX(-4px); }
            40%, 80% { transform: translateX(4px); }
        }

        /* Form Controls */
        .form-group {
            margin-bottom: 1.25rem;
        }

        .form-label {
            display: block;
            font-size: 0.82rem;
            font-weight: 600;
            color: var(--text-main);
            margin-bottom: 0.45rem;
            letter-spacing: -0.01em;
        }

        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-icon {
            position: absolute;
            left: 14px;
            color: var(--text-dim);
            pointer-events: none;
            width: 18px;
            height: 18px;
            transition: color 0.2s;
        }

        .form-control {
            width: 100%;
            background: var(--bg-input);
            border: 1px solid var(--border-subtle);
            border-radius: var(--radius-input);
            padding: 0.78rem 1rem 0.78rem 2.65rem;
            font-size: 0.92rem;
            color: #ffffff;
            font-family: inherit;
            outline: none;
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .form-control::placeholder {
            color: var(--text-dim);
        }

        .form-control:focus {
            background: rgba(30, 41, 59, 0.85);
            border-color: var(--border-focus);
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.25);
        }

        .input-wrapper:focus-within .input-icon {
            color: #60a5fa;
        }

        /* Password Toggle Button */
        .password-toggle-btn {
            position: absolute;
            right: 12px;
            background: transparent;
            border: none;
            color: var(--text-dim);
            cursor: pointer;
            padding: 6px;
            border-radius: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: color 0.2s, background-color 0.2s;
        }

        .password-toggle-btn:hover {
            color: var(--text-main);
            background: rgba(255, 255, 255, 0.05);
        }

        .password-toggle-btn svg {
            width: 18px;
            height: 18px;
        }

        /* Remember Me & Options Row */
        .form-options-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin: 1.25rem 0 1.5rem;
            font-size: 0.84rem;
        }

        .remember-checkbox-label {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: var(--text-muted);
            cursor: pointer;
            user-select: none;
            font-weight: 500;
            transition: color 0.2s;
        }

        .remember-checkbox-label:hover {
            color: var(--text-main);
        }

        .custom-checkbox {
            appearance: none;
            -webkit-appearance: none;
            width: 17px;
            height: 17px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 4px;
            background: rgba(30, 41, 59, 0.6);
            cursor: pointer;
            position: relative;
            outline: none;
            transition: all 0.2s;
        }

        .custom-checkbox:checked {
            background: var(--primary);
            border-color: var(--primary);
            box-shadow: 0 0 10px rgba(59, 130, 246, 0.4);
        }

        .custom-checkbox:checked::after {
            content: '';
            position: absolute;
            left: 5px;
            top: 2px;
            width: 4px;
            height: 8px;
            border: solid white;
            border-width: 0 2px 2px 0;
            transform: rotate(45deg);
        }

        .custom-checkbox:focus-visible {
            box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.4);
        }

        .support-hint {
            color: #60a5fa;
            font-size: 0.82rem;
            font-weight: 600;
            text-decoration: none;
            opacity: 0.9;
            transition: opacity 0.2s;
        }

        .support-hint:hover {
            opacity: 1;
            text-decoration: underline;
        }

        /* Submit Button */
        .btn-submit {
            width: 100%;
            background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
            color: #ffffff;
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: var(--radius-btn);
            padding: 0.85rem;
            font-size: 0.94rem;
            font-weight: 700;
            letter-spacing: -0.01em;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            box-shadow: 0 4px 14px rgba(37, 99, 235, 0.35);
            transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .btn-submit:hover {
            background: linear-gradient(135deg, #60a5fa 0%, #1d4ed8 100%);
            box-shadow: 0 6px 20px rgba(37, 99, 235, 0.5);
            transform: translateY(-1px);
        }

        .btn-submit:active {
            transform: translateY(0);
            box-shadow: 0 2px 8px rgba(37, 99, 235, 0.3);
        }

        .btn-submit:disabled {
            opacity: 0.7;
            cursor: not-allowed;
            transform: none !important;
        }

        /* Security Assurance Footer */
        .security-footer {
            margin-top: 2rem;
            text-align: center;
            font-size: 0.76rem;
            color: var(--text-dim);
            line-height: 1.5;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
        }

        .security-badges {
            display: flex;
            align-items: center;
            gap: 12px;
            color: var(--text-muted);
            font-weight: 500;
        }

        .security-badge-item {
            display: flex;
            align-items: center;
            gap: 4px;
        }

        .security-badge-item svg {
            width: 13px;
            height: 13px;
            color: var(--accent-emerald);
        }

        /* Loading Spinner */
        .spinner {
            display: none;
            width: 18px;
            height: 18px;
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top-color: #ffffff;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        .is-loading .spinner {
            display: inline-block;
        }

        .is-loading .btn-text {
            opacity: 0.9;
        }
    </style>
</head>
<body>
    <div class="ambient-glow-1"></div>
    <div class="ambient-glow-2"></div>
    <div class="bg-grid"></div>

    <div class="login-wrapper">
        <div class="login-card">
            <div class="brand-header">
                <div class="brand-badge">
                    <span class="brand-badge-dot"></span>
                    Admin Control Center
                </div>
                <h1 class="brand-title">EXAM<span>VERSE</span></h1>
                <p class="brand-subtitle">Sign in to manage questions, tests, and student analytics</p>
            </div>

            <?php if (!empty($error)): ?>
                <div class="alert-error">
                    <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                    <div><?php echo htmlspecialchars($error, ENT_QUOTES, 'UTF-8'); ?></div>
                </div>
            <?php endif; ?>

            <form method="POST" action="login.php" id="loginForm" autocomplete="on">
                <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars(adminCsrfToken(), ENT_QUOTES); ?>">

                <!-- Username or Email Input -->
                <div class="form-group">
                    <label class="form-label" for="admin_username">Username or Admin Email</label>
                    <div class="input-wrapper">
                        <svg class="input-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        <input 
                            type="text" 
                            id="admin_username"
                            name="username" 
                            class="form-control" 
                            placeholder="admin or admin@examverse.com" 
                            value="<?php echo htmlspecialchars($rememberedUser, ENT_QUOTES); ?>" 
                            required 
                            <?php echo empty($rememberedUser) ? 'autofocus' : ''; ?>
                            autocomplete="username"
                        >
                    </div>
                </div>

                <!-- Password Input with Show/Hide Toggle -->
                <div class="form-group">
                    <label class="form-label" for="admin_password">Admin Security Password</label>
                    <div class="input-wrapper">
                        <svg class="input-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                        <input 
                            type="password" 
                            id="admin_password"
                            name="password" 
                            class="form-control" 
                            placeholder="••••••••••••" 
                            required 
                            <?php echo !empty($rememberedUser) ? 'autofocus' : ''; ?>
                            autocomplete="current-password"
                        >
                        <button type="button" class="password-toggle-btn" id="togglePasswordBtn" title="Show/Hide Password" aria-label="Toggle password visibility">
                            <svg id="eyeOpenIcon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                            <svg id="eyeClosedIcon" style="display:none;" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18" />
                            </svg>
                        </button>
                    </div>
                </div>

                <!-- Remember Me & System Notice -->
                <div class="form-options-row">
                    <label class="remember-checkbox-label">
                        <input 
                            type="checkbox" 
                            name="remember_me" 
                            value="1" 
                            class="custom-checkbox" 
                            id="remember_me"
                            <?php echo $rememberChecked ? 'checked' : ''; ?>
                        >
                        <span>Remember credentials</span>
                    </label>
                    <span class="support-hint" title="Default credentials seeded if database is fresh: admin / Admin@12345678">Secured Access</span>
                </div>

                <!-- Submit Button -->
                <button type="submit" class="btn-submit" id="submitBtn">
                    <span class="spinner" id="btnSpinner"></span>
                    <span class="btn-text" id="btnText">Sign In to Admin Panel →</span>
                </button>
            </form>

            <div class="security-footer">
                <div class="security-badges">
                    <div class="security-badge-item">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                        </svg>
                        <span>256-Bit SSL</span>
                    </div>
                    <span>•</span>
                    <div class="security-badge-item">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                        </svg>
                        <span>Role-Based Control</span>
                    </div>
                    <span>•</span>
                    <div class="security-badge-item">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <span>Audit Logged</span>
                    </div>
                </div>
                <div>EXAMVERSE Systems &copy; <?php echo date('Y'); ?> • Authorized Personnel Only</div>
            </div>
        </div>
    </div>

    <script>
        // Password Visibility Toggle Logic
        const toggleBtn = document.getElementById('togglePasswordBtn');
        const passwordInput = document.getElementById('admin_password');
        const eyeOpen = document.getElementById('eyeOpenIcon');
        const eyeClosed = document.getElementById('eyeClosedIcon');

        if (toggleBtn && passwordInput) {
            toggleBtn.addEventListener('click', function () {
                const isPassword = passwordInput.getAttribute('type') === 'password';
                passwordInput.setAttribute('type', isPassword ? 'text' : 'password');
                eyeOpen.style.display = isPassword ? 'none' : 'block';
                eyeClosed.style.display = isPassword ? 'block' : 'none';
            });
        }

        // Form Submit Loading Feedback
        const loginForm = document.getElementById('loginForm');
        const submitBtn = document.getElementById('submitBtn');
        const btnText = document.getElementById('btnText');

        if (loginForm && submitBtn) {
            loginForm.addEventListener('submit', function () {
                submitBtn.classList.add('is-loading');
                submitBtn.setAttribute('disabled', 'disabled');
                if (btnText) btnText.textContent = 'Authenticating...';
            });
        }
    </script>
</body>
</html>
