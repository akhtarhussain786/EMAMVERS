<?php
require_once __DIR__ . '/includes/session.php';

adminSessionStart();

// Authentication Guard: Check if admin is logged in
if (!adminIsLoggedIn()) {
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
$allowedPages = ['dashboard', 'users', 'question_review', 'question_bank', 'map_locations', 'taxonomy', 'patterns', 'questions', 'tests', 'challenges', 'cms', 'audits', 'ai_generator', 'marketplace', 'creators'];

if (!in_array($page, $allowedPages)) {
    $page = 'dashboard';
}

$titleMap = [
    'dashboard'     => 'Operational Dashboard & Analytics Summary',
    'users'         => '👥 Registered Student & Candidate Directory',
    'question_review' => '📝 Teacher Question Submissions & Review',
    'question_bank'   => '🏦 Question Bank Health & Top-up Targets',
    'map_locations' => '🗺️ Map Learning Locations & Geography Bank',
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
    <meta name="csrf-token" content="<?php echo htmlspecialchars(adminCsrfToken(), ENT_QUOTES); ?>">
    <script>
        // Attach the CSRF token to every same-origin admin AJAX call.
        window.ADMIN_CSRF_TOKEN = <?php echo json_encode(adminCsrfToken()); ?>;
        (function () {
            const nativeFetch = window.fetch.bind(window);
            window.fetch = function (input, init) {
                init = init || {};
                const url = typeof input === 'string' ? input : (input && input.url) || '';
                if (url.indexOf('ajax/') !== -1 || url.indexOf('/admin/ajax/') !== -1) {
                    init.headers = new Headers(init.headers || {});
                    init.headers.set('X-CSRF-Token', window.ADMIN_CSRF_TOKEN);
                    init.credentials = init.credentials || 'same-origin';
                }
                return nativeFetch(input, init);
            };
        })();
    </script>
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
