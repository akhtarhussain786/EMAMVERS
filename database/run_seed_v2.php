<?php
mysqli_report(MYSQLI_REPORT_OFF);
$m = new mysqli('127.0.0.1','root','','examverse_db');
$m->set_charset('utf8mb4');
$sql = file_get_contents('database/seed_exams_v2.sql');

$statements = array_filter(array_map('trim', explode(';', $sql)));
$errors = [];
$success = 0;
$last_result = '';

foreach ($statements as $stmt) {
    if (empty($stmt) || strlen(trim($stmt)) < 3) continue;
    if (!$m->query($stmt)) {
        $errCode = $m->errno;
        // Skip duplicate entry
        if (in_array($errCode, [1062, 1050, 1022])) {
            $errors[] = "[SKIP-{$errCode}] " . substr($m->error, 0, 80);
        } else {
            $errors[] = "[ERR-{$errCode}] {$m->error} | " . substr($stmt, 0, 100);
        }
    } else {
        $result = $m->store_result();
        if ($result) {
            $row = $result->fetch_assoc();
            if ($row) $last_result = implode(', ', $row);
            $result->free();
        }
        $success++;
    }
}

echo "Seed done! OK: $success | $last_result\n";
if ($errors) {
    echo "Skipped/Errors (" . count($errors) . "):\n";
    foreach ($errors as $e) echo "  $e\n";
}
