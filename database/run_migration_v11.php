<?php
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("This maintenance script can only be run from the command line.\n");
}

require_once __DIR__ . '/../api/config/db.php';
$pdo = Database::getConnection();

$sql = file_get_contents(__DIR__ . '/migration_v11.sql');
$pdo->exec($sql);

echo "SUCCESS: Migration v11 executed successfully!\n";
