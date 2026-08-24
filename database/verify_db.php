<?php
mysqli_report(MYSQLI_REPORT_OFF);
$m = new mysqli('127.0.0.1','root','','examverse_db');
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
