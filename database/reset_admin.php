<?php
require_once __DIR__ . '/../api/config/db.php';
$db = Database::getConnection();
$hash = password_hash('admin123', PASSWORD_BCRYPT);
$db->exec("INSERT INTO admins (username, email, password_hash, full_name, role) 
           VALUES ('admin', 'admin@examverse.com', '$hash', 'Super Administrator', 'super_admin') 
           ON DUPLICATE KEY UPDATE password_hash = '$hash'");
echo "Admin password updated successfully to 'admin123'\n";
