<?php
require_once __DIR__ . '/../api/config/db.php';

echo "Connecting to database...\n";
$pdo = Database::getConnection();

function runSqlFile($pdo, $filePath) {
    if (!file_exists($filePath)) {
        echo "File not found: {$filePath}\n";
        return;
    }
    $content = file_get_contents($filePath);
    // Remove comments
    $lines = explode("\n", $content);
    $cleanLines = [];
    foreach ($lines as $line) {
        $trimmed = trim($line);
        if ($trimmed === '' || strpos($trimmed, '--') === 0 || strpos($trimmed, '/*') === 0) {
            continue;
        }
        $cleanLines[] = $line;
    }
    $cleanSql = implode("\n", $cleanLines);
    $queries = array_filter(array_map('trim', explode(';', $cleanSql)));

    foreach ($queries as $query) {
        if (empty($query)) continue;
        try {
            $pdo->exec($query);
            echo "SUCCESS: " . substr(str_replace(["\r", "\n"], ' ', $query), 0, 60) . "...\n";
        } catch (PDOException $e) {
            // Ignore duplicate column or index errors if already applied
            if (strpos($e->getMessage(), 'Duplicate column') !== false || strpos($e->getMessage(), 'Duplicate key') !== false) {
                echo "ALREADY APPLIED: " . substr(str_replace(["\r", "\n"], ' ', $query), 0, 50) . "...\n";
            } else {
                echo "ERROR executing query: " . $e->getMessage() . "\n";
            }
        }
    }
}

echo "--- Running migration_v12.sql ---\n";
runSqlFile($pdo, __DIR__ . '/migration_v12.sql');

echo "--- Running seed_subscription_plans.sql ---\n";
runSqlFile($pdo, __DIR__ . '/seed_subscription_plans.sql');

echo "=== MIGRATION V12 COMPLETE ===\n";
