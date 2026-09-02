<?php
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("This maintenance script can only be run from the command line.\n");
}

require_once __DIR__ . '/../api/config/config.php';

mysqli_report(MYSQLI_REPORT_OFF);
$m = new mysqli(
    Config::get('DB_HOST', '127.0.0.1'),
    Config::get('DB_USER', 'root'),
    Config::get('DB_PASS', ''),
    Config::get('DB_NAME', 'examverse_db')
);
if ($m->connect_errno) {
    fwrite(STDERR, "Connection failed: {$m->connect_error}\n");
    exit(1);
}
$r = $m->query('SELECT COUNT(*) as cnt FROM exams');
$row = $r->fetch_assoc();
echo 'Total exams: '.$row['cnt']."\n";
$r2 = $m->query('SELECT COUNT(*) as cnt FROM exam_categories');
$row2 = $r2->fetch_assoc();
echo 'Total categories: '.$row2['cnt']."\n";
$r3 = $m->query('SELECT COUNT(*) as cnt FROM ai_api_keys');
$row3 = $r3->fetch_assoc();
echo 'AI keys table exists: YES, rows='.$row3['cnt']."\n";
$r4 = $m->query('SELECT COUNT(*) as cnt FROM study_materials');
$row4 = $r4->fetch_assoc();
echo 'Study materials table: YES, rows='.$row4['cnt']."\n";
