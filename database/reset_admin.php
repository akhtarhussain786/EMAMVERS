<?php
/**
 * Resets (or creates) the super-admin account.
 *
 * CLI only, and the password must be supplied explicitly — this script used to
 * be reachable over HTTP and reset the admin password to a known constant.
 *
 * Usage: php database/reset_admin.php '<new-password>' [username] [email]
 */
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("This maintenance script can only be run from the command line.\n");
}

require_once __DIR__ . '/../api/config/db.php';

$password = $argv[1] ?? '';
$username = $argv[2] ?? 'admin';
$email    = $argv[3] ?? 'admin@examverse.com';

if ($password === '') {
    fwrite(STDERR, "Usage: php database/reset_admin.php '<new-password>' [username] [email]\n");
    exit(1);
}
if (strlen($password) < 12) {
    fwrite(STDERR, "Refusing to set an admin password shorter than 12 characters.\n");
    exit(1);
}

$db = Database::getConnection();
$hash = password_hash($password, PASSWORD_BCRYPT);

$stmt = $db->prepare("
    INSERT INTO admins (username, email, password_hash, full_name, role, status)
    VALUES (:username, :email, :hash, 'Super Administrator', 'super_admin', 'active')
    ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash), status = 'active'
");
$stmt->execute(['username' => $username, 'email' => $email, 'hash' => $hash]);

echo "Admin '{$username}' password updated.\n";
