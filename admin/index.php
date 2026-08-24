<?php
session_start();

// Authentication Guard: Check if admin is logged in
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header('Location: login.php');
    exit;
}

$currentAdmin = $_SESSION['admin_user'] ?? [
    'username' => 'admin',
    'full_name' => 'Super Administrator',
    'email' => 'admin@examverse.com',
    'role' => 'super_admin'
];

$page = isset($_GET['page']) ? trim($_GET['page']) : 'dashboard';
$allowedPages = ['dashboard', 'taxonomy', 'patterns', 'questions', 'tests', 'challenges', 'cms', 'audits', 'ai_generator', 'marketplace', 'creators'];

if (!in_array($page, $allowedPages)) {
    $page = 'dashboard';
}

$titleMap = [
    'dashboard'     => 'Operational Dashboard & Analytics Summary',
    'taxonomy'      => 'Exam Taxonomy & Organization Governance',
    'patterns'      => 'Universal Test Pattern Builder',
    'questions'     => 'Question Bank & Multilingual Repository',
    'tests'         => 'Test Series Inventory & Builder',
    'challenges'    => 'Monthly National Flagship Challenges',
    'cms'           => 'Content CMS Hub (Current Affairs, Jobs, Topper Wall)',
    'audits'        => 'System Governance & Audit Logs',
    'ai_generator'  => '🤖 AI Question Generator & API Key Manager',
    'marketplace'   => '🏪 Study Materials Marketplace',
    'creators'      => '👨‍🏫 Creator Accounts & Payout Management',
];

$title = isset($titleMap[$page]) ? $titleMap[$page] : 'Admin Control Center';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EXAMVERSE - PHP Admin Control Center</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="assets/style.css">
</head>
<body>
    <?php include __DIR__ . '/includes/sidebar.php'; ?>

    <div class="main-wrapper">
        <?php include __DIR__ . '/includes/header.php'; ?>

        <main class="content-body">
            <?php 
            $filePath = __DIR__ . "/pages/{$page}.php";
            if (file_exists($filePath)) {
                include $filePath;
            } else {
                echo "<div class='table-card'>Page not found.</div>";
            }
            ?>
        </main>
    </div>
</body>
</html>
