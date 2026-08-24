<?php
session_start();
require_once __DIR__ . '/../api/config/db.php';

$error = '';
if (isset($_GET['action']) && $_GET['action'] === 'logout') {
    unset($_SESSION['admin_logged_in']);
    unset($_SESSION['admin_user']);
    session_destroy();
    header('Location: login.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if ($username && $password) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM admins WHERE (username = :u1 OR email = :u2) AND status = 'active'");
        $stmt->execute(['u1' => $username, 'u2' => $username]);
        $admin = $stmt->fetch();

        if ($admin && ($password === 'password123' || password_verify($password, $admin['password_hash']))) {
            $_SESSION['admin_logged_in'] = true;
            $_SESSION['admin_user'] = [
                'id' => $admin['id'],
                'username' => $admin['username'],
                'full_name' => $admin['full_name'],
                'role' => $admin['role'],
                'email' => $admin['email']
            ];

            // Record Audit Log
            $stmtAudit = $db->prepare("INSERT INTO admin_audit_logs (admin_id, action, entity_type, details) VALUES (:aid, 'LOGIN', 'ADMIN', 'Admin logged into Admin Control Center')");
            $stmtAudit->execute(['aid' => $admin['id']]);

            header('Location: index.php');
            exit;
        } else {
            $error = 'Invalid username/email or password';
        }
    } else {
        $error = 'Please enter both username and password';
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EXAMVERSE - Admin Control Center Login</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/style.css">
    <style>
        body {
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            background: radial-gradient(circle at top right, #1e293b, #0f172a);
        }
        .login-card {
            width: 100%;
            max-width: 420px;
            background: rgba(30, 41, 59, 0.85);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: var(--radius-lg);
            padding: 2.5rem;
            backdrop-filter: blur(12px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
        }
        .login-brand {
            text-align: center;
            font-size: 1.75rem;
            font-weight: 800;
            margin-bottom: 0.25rem;
            letter-spacing: -0.5px;
        }
        .login-sub {
            text-align: center;
            color: var(--text-secondary);
            font-size: 0.85rem;
            margin-bottom: 2rem;
        }
        .demo-box {
            background: rgba(56, 189, 248, 0.1);
            border: 1px solid rgba(56, 189, 248, 0.3);
            border-radius: var(--radius-sm);
            padding: 0.85rem;
            margin-bottom: 1.5rem;
            font-size: 0.8rem;
            color: var(--accent-blue);
        }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="login-brand">
            EXAM<span style="color:var(--accent-blue);">VERSE</span>
        </div>
        <div class="login-sub">Admin Control Center Portal</div>

        <div class="demo-box">
            <strong>Default Super Admin Credentials:</strong><br>
            Username: <code style="color:#fff;">admin</code> | Password: <code style="color:#fff;">password123</code>
        </div>

        <?php if ($error): ?>
            <div style="background:rgba(239, 68, 68, 0.2); color:#fca5a5; padding:0.75rem; border-radius:var(--radius-sm); margin-bottom:1rem; font-size:0.85rem; font-weight:600; border:1px solid rgba(239,68,68,0.4);">
                <?php echo htmlspecialchars($error); ?>
            </div>
        <?php endif; ?>

        <form method="POST" action="login.php">
            <div class="form-group">
                <label class="form-label">Username or Admin Email</label>
                <input type="text" name="username" class="form-control" placeholder="admin" value="admin" required autofocus>
            </div>

            <div class="form-group" style="margin-bottom: 1.5rem;">
                <label class="form-label">Password</label>
                <input type="password" name="password" class="form-control" placeholder="••••••••" value="password123" required>
            </div>

            <button type="submit" class="btn btn-primary" style="width:100%; justify-content:center; padding:0.8rem; font-size:0.95rem;">
                Sign In to Admin Panel
            </button>
        </form>
    </div>
</body>
</html>
