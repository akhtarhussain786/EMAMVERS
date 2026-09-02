<?php
/**
 * Applies database/migration_v7.sql.
 *
 * CLI only. Each statement is applied independently and "already exists"
 * errors are reported as skips, so the migration is safe to re-run.
 */
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("This migration script can only be run from the command line.\n");
}

require_once __DIR__ . '/../api/config/db.php';

$db = Database::getConnection();
$sql = file_get_contents(__DIR__ . '/migration_v7.sql');

// Split on semicolons at end of line; this file contains no routines or triggers.
$statements = array_filter(array_map('trim', preg_split('/;\s*[\r\n]+/', $sql)));

$applied = $skipped = $failed = 0;

foreach ($statements as $statement) {
    // Strip comment-only fragments
    $meaningful = trim(preg_replace('/^\s*--.*$/m', '', $statement));
    if ($meaningful === '') continue;

    try {
        $db->exec($statement);
        $applied++;
        echo "  ✓ " . summarise($statement) . "\n";
    } catch (PDOException $e) {
        // 1060 duplicate column, 1061 duplicate key, 1091 can't drop, 1826 dup FK
        if (in_array($e->errorInfo[1] ?? 0, [1060, 1061, 1091, 1826], true)) {
            $skipped++;
            echo "  – already applied: " . summarise($statement) . "\n";
        } else {
            $failed++;
            echo "  ✗ FAILED: " . summarise($statement) . "\n     " . $e->getMessage() . "\n";
        }
    }
}

function summarise($statement) {
    $oneLine = preg_replace('/\s+/', ' ', trim(preg_replace('/^\s*--.*$/m', '', $statement)));
    return strlen($oneLine) > 90 ? substr($oneLine, 0, 87) . '...' : $oneLine;
}

echo "\nMigration v7 complete: {$applied} applied, {$skipped} already present, {$failed} failed.\n";
exit($failed > 0 ? 1 : 0);
