<?php
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("This maintenance script can only be run from the command line.\n");
}

require_once __DIR__ . '/../api/config/db.php';

try {
    $db = Database::getConnection();
    echo "=== Running Migration v4: Bookmarks, Wrong Questions, Notifications & Target Exams ===\n";

    $sql = file_get_contents(__DIR__ . '/migration_v4.sql');
    $statements = array_filter(array_map('trim', explode(';', $sql)));

    foreach ($statements as $stmt) {
        if (!empty($stmt) && strpos($stmt, 'SELECT') !== 0 && strpos($stmt, 'USE') !== 0) {
            try {
                $db->exec($stmt);
                echo "Executed statement successfully.\n";
            } catch (PDOException $e) {
                echo "Notice: " . $e->getMessage() . "\n";
            }
        }
    }

    echo "Migration v4 Finished Successfully!\n";
} catch (Exception $e) {
    echo "Error running migration: " . $e->getMessage() . "\n";
}
