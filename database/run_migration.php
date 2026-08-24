<?php
// Graceful migration runner — skips duplicate column/table errors and continues
mysqli_report(MYSQLI_REPORT_OFF); // Disable exceptions
$m = new mysqli('127.0.0.1','root','','examverse_db');
$m->set_charset('utf8mb4');
$sql = file_get_contents('database/migration_v2.sql');

$statements = array_filter(array_map('trim', explode(';', $sql)));
$errors = [];
$success = 0;

foreach ($statements as $stmt) {
    if (empty($stmt) || strlen(trim($stmt)) < 3) continue;
    if (!$m->query($stmt)) {
        $errCode = $m->errno;
        // Skip harmless: duplicate column (1060), table exists (1050), dup key (1061), dup constraint (1022,1826)
        if (in_array($errCode, [1060, 1050, 1061, 1022, 1826])) {
            $errors[] = "[SKIP-{$errCode}] " . substr($m->error, 0, 100);
        } else {
            $errors[] = "[ERR-{$errCode}] {$m->error} | " . substr($stmt, 0, 80);
        }
    } else {
        $success++;
    }
}

echo "Migration done! OK: $success\n";
if ($errors) {
    echo "Skipped (" . count($errors) . "):\n";
    foreach ($errors as $e) echo "  $e\n";
}
