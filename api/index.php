<?php
// EXAMVERSE REST API Router v1
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

require_once __DIR__ . '/utils/response.php';
require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/DiscoveryController.php';
require_once __DIR__ . '/controllers/TestEngineController.php';
require_once __DIR__ . '/controllers/ResultController.php';
require_once __DIR__ . '/controllers/ChallengeController.php';
require_once __DIR__ . '/controllers/AiController.php';
require_once __DIR__ . '/controllers/ContentController.php';
require_once __DIR__ . '/controllers/AdminController.php';
require_once __DIR__ . '/controllers/CreatorController.php';
require_once __DIR__ . '/controllers/MarketplaceController.php';

// Extract URI path
$requestUri = $_SERVER['REQUEST_URI'];
$basePath = '/EXAMVERSE/api';
if (strpos($requestUri, $basePath) === 0) {
    $requestUri = substr($requestUri, strlen($basePath));
}
$path = parse_url($requestUri, PHP_URL_PATH);
$path = rtrim($path, '/');
$method = $_SERVER['REQUEST_METHOD'];

// Helper pattern matching
function matchRoute($pattern, $path, &$params) {
    $regex = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '(?P<\1>[^/]+)', $pattern);
    $regex = "#^" . $regex . "$#";
    if (preg_match($regex, $path, $matches)) {
        $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
        return true;
    }
    return false;
}

$params = [];

// ROUTE DISPATCHER
if ($path === '/v1/auth/login' && $method === 'POST') {
    AuthController::login();
} elseif ($path === '/v1/auth/signup' && $method === 'POST') {
    AuthController::signup();
} elseif ($path === '/v1/auth/send-otp' && $method === 'POST') {
    AuthController::sendOtp();
} elseif ($path === '/v1/auth/verify-otp' && $method === 'POST') {
    AuthController::verifyOtp();
} elseif ($path === '/v1/auth/meta' && $method === 'GET') {
    AuthController::getStatesAndQualifications();
} elseif ($path === '/v1/home' && $method === 'GET') {
    DiscoveryController::getHomeData();
} elseif ($path === '/v1/exam-categories' && $method === 'GET') {
    DiscoveryController::getCategories();
} elseif (matchRoute('/v1/exams/{id}', $path, $params) && $method === 'GET') {
    DiscoveryController::getExamDetail($params['id']);
} elseif (matchRoute('/v1/tests/{id}/instructions', $path, $params) && $method === 'GET') {
    TestEngineController::getInstructions($params['id']);
} elseif (matchRoute('/v1/tests/{id}/attempts', $path, $params) && $method === 'POST') {
    TestEngineController::startAttempt($params['id']);
} elseif (matchRoute('/v1/attempts/{id}/answers', $path, $params) && ($method === 'PUT' || $method === 'POST')) {
    TestEngineController::saveAnswerState($params['id']);
} elseif (matchRoute('/v1/attempts/{id}/submit', $path, $params) && $method === 'POST') {
    TestEngineController::submitAttempt($params['id']);
} elseif (matchRoute('/v1/attempts/{id}/result', $path, $params) && $method === 'GET') {
    ResultController::getResultSummary($params['id']);
} elseif (matchRoute('/v1/attempts/{id}/solutions', $path, $params) && $method === 'GET') {
    ResultController::getSolutions($params['id']);
} elseif ($path === '/v1/challenges' && $method === 'GET') {
    ChallengeController::getChallenges();
} elseif (matchRoute('/v1/challenges/{id}/register', $path, $params) && $method === 'POST') {
    ChallengeController::registerForChallenge($params['id']);
} elseif (matchRoute('/v1/leaderboards/{context}', $path, $params) && $method === 'GET') {
    ChallengeController::getLeaderboard($params['context']);
} elseif (matchRoute('/v1/ai/exam-twin/{examId}', $path, $params) && $method === 'GET') {
    AiController::getExamTwin($params['examId']);
} elseif ($path === '/v1/ai/daily-mission' && $method === 'GET') {
    AiController::getDailyMission();
} elseif (matchRoute('/v1/attempts/{id}/lost-marks', $path, $params) && $method === 'GET') {
    AiController::getLostMarks($params['id']);
} elseif ($path === '/v1/ai/strategy-simulations' && $method === 'POST') {
    AiController::runStrategySimulation();
} elseif ($path === '/v1/current-affairs' && $method === 'GET') {
    ContentController::getCurrentAffairs();
} elseif (matchRoute('/v1/current-affairs/{id}/generate-quiz', $path, $params) && $method === 'POST') {
    ContentController::generateArticleQuiz($params['id']);
} elseif (matchRoute('/v1/current-affairs/{id}/quiz', $path, $params) && $method === 'GET') {
    ContentController::getArticleQuiz($params['id']);
} elseif (matchRoute('/v1/current-affairs/{id}', $path, $params) && $method === 'GET') {
    ContentController::getCurrentAffairsDetail($params['id']);
} elseif ($path === '/v1/jobs' && $method === 'GET') {
    ContentController::getJobs();
} elseif ($path === '/v1/toppers' && $method === 'GET') {
    ContentController::getTopperWall();
} elseif ($path === '/v1/passport' && $method === 'GET') {
    ContentController::getPreparationPassport();
} elseif ($path === '/v1/admin/login' && $method === 'POST') {
    AdminController::login();
} elseif ($path === '/v1/admin/dashboard' && $method === 'GET') {
    AdminController::getDashboardMetrics();
} elseif ($path === '/v1/admin/exams' && $method === 'GET') {
    AdminController::getExams();
} elseif ($path === '/v1/admin/exams' && $method === 'POST') {
    AdminController::createExam();
} elseif ($path === '/v1/admin/patterns' && $method === 'GET') {
    AdminController::getPatterns();
} elseif ($path === '/v1/admin/questions' && $method === 'GET') {
    AdminController::getQuestions();
} elseif ($path === '/v1/admin/questions/bulk-import' && $method === 'POST') {
    AdminController::bulkImportQuestions();
} elseif ($path === '/v1/admin/audit-logs' && $method === 'GET') {
    AdminController::getAuditLogs();

// ── AI KEY MANAGEMENT ─────────────────────────────────────────────────────
} elseif ($path === '/v1/admin/ai-keys' && $method === 'GET') {
    AiController::listKeys();
} elseif ($path === '/v1/admin/ai-keys' && $method === 'POST') {
    AiController::saveKey();
} elseif (matchRoute('/v1/admin/ai-keys/{id}', $path, $params) && $method === 'DELETE') {
    AiController::deleteKey($params['id']);
} elseif (matchRoute('/v1/admin/ai-keys/{id}/toggle', $path, $params) && $method === 'POST') {
    AiController::toggleKey($params['id']);

// ── AI QUESTION GENERATION ────────────────────────────────────────────────
} elseif ($path === '/v1/ai/generate-questions' && $method === 'POST') {
    AiController::generateQuestions();
} elseif ($path === '/v1/ai/approve-questions' && $method === 'POST') {
    AiController::approveBatch();
} elseif ($path === '/v1/ai/batches' && $method === 'GET') {
    AiController::getBatches();
} elseif (matchRoute('/v1/ai/batches/{batchId}/questions', $path, $params) && $method === 'GET') {
    AiController::getBatchQuestions($params['batchId']);

// ── CREATOR ECONOMY ───────────────────────────────────────────────────────
} elseif ($path === '/v1/creator/register' && $method === 'POST') {
    CreatorController::register();
} elseif ($path === '/v1/creator/dashboard' && $method === 'GET') {
    CreatorController::dashboard();
} elseif ($path === '/v1/creator/materials' && $method === 'POST') {
    CreatorController::uploadMaterial();
} elseif ($path === '/v1/creator/materials' && $method === 'GET') {
    CreatorController::myMaterials();
} elseif ($path === '/v1/creator/payout' && $method === 'POST') {
    CreatorController::requestPayout();

// ── ADMIN: CREATOR MANAGEMENT ─────────────────────────────────────────────
} elseif ($path === '/v1/admin/creators' && $method === 'GET') {
    CreatorController::adminList();
} elseif (matchRoute('/v1/admin/creators/{id}/approve', $path, $params) && $method === 'POST') {
    CreatorController::adminApprove($params['id']);
} elseif (matchRoute('/v1/admin/creators/{id}/suspend', $path, $params) && $method === 'POST') {
    CreatorController::adminSuspend($params['id']);
} elseif (matchRoute('/v1/admin/payouts/{id}/process', $path, $params) && $method === 'POST') {
    CreatorController::adminProcessPayout($params['id']);

// ── MARKETPLACE ───────────────────────────────────────────────────────────
} elseif ($path === '/v1/marketplace' && $method === 'GET') {
    MarketplaceController::list();
} elseif (matchRoute('/v1/marketplace/{id}', $path, $params) && $method === 'GET') {
    MarketplaceController::detail($params['id']);
} elseif (matchRoute('/v1/marketplace/{id}/purchase', $path, $params) && $method === 'POST') {
    MarketplaceController::purchase($params['id']);
} elseif (matchRoute('/v1/marketplace/{id}/download', $path, $params) && $method === 'GET') {
    MarketplaceController::download($params['id']);
} elseif (matchRoute('/v1/marketplace/{id}/rate', $path, $params) && $method === 'POST') {
    MarketplaceController::rate($params['id']);
} elseif ($path === '/v1/marketplace/my-purchases' && $method === 'GET') {
    MarketplaceController::myPurchases();

// ── ADMIN: MARKETPLACE MANAGEMENT ────────────────────────────────────────
} elseif ($path === '/v1/admin/marketplace' && $method === 'GET') {
    MarketplaceController::adminList();
} elseif (matchRoute('/v1/admin/marketplace/{id}/approve', $path, $params) && $method === 'POST') {
    MarketplaceController::adminApprove($params['id']);
} elseif (matchRoute('/v1/admin/marketplace/{id}/reject', $path, $params) && $method === 'POST') {
    MarketplaceController::adminReject($params['id']);
} elseif ($path === '/v1/admin/marketplace/stats' && $method === 'GET') {
    MarketplaceController::adminStats();

// ── EXAM SEARCH ──────────────────────────────────────────────────────────
} elseif ($path === '/v1/exams/search' && $method === 'GET') {
    DiscoveryController::searchExams();

} else {
    Response::error("Endpoint '$path' not found or unsupported method '$method'", 404);
}
