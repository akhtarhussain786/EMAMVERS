<?php
require_once __DIR__ . '/../api/config/db.php';

try {
    $db = Database::getConnection();
    $sql = file_get_contents(__DIR__ . '/migration_v10.sql');
    $db->exec($sql);
    echo "Migration v10 (system_settings) applied successfully.\n";
} catch (Exception $e) {
    echo "Migration v10 failed: " . $e->getMessage() . "\n";
    exit(1);
}
