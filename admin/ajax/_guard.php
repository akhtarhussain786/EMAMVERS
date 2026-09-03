<?php
/**
 * Admin AJAX Guard — all admin/ajax/*.php files must include this.
 * Enforces the admin session and, for state-changing requests, a CSRF token.
 * Returns JSON only.
 */
require_once __DIR__ . '/../includes/session.php';

adminSessionStart();

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

// Block non-logged-in requests
if (!adminIsLoggedIn()) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Admin session required. Please log in.']);
    exit;
}

// Helper: send JSON response and exit
function ajaxOk($data = null, string $message = 'Success', int $code = 200): void {
    http_response_code($code);
    echo json_encode(['status' => 'success', 'message' => $message, 'data' => $data]);
    exit;
}

function ajaxErr(string $message, int $code = 400): void {
    http_response_code($code);
    echo json_encode(['status' => 'error', 'message' => $message, 'data' => null]);
    exit;
}

function getBody(): array {
    static $cached = null;
    if ($cached !== null) return $cached;
    $raw = file_get_contents('php://input');
    $cached = $raw ? (json_decode($raw, true) ?? []) : [];
    return $cached;
}

/**
 * Anything that mutates state needs a CSRF token. These endpoints are driven by
 * the session cookie, so without this a third-party page could approve payouts
 * or delete keys on behalf of a logged-in admin.
 */
$adminAjaxAction = $_GET['action'] ?? '';
$readOnlyActions = ['list', 'batches', 'batch_questions', 'marketplace_stats', 'stats', 'teachers', 'levels', 'meta'];

if (!in_array($adminAjaxAction, $readOnlyActions, true)) {
    if (!adminCsrfValid(adminCsrfFromRequest(getBody()))) {
        http_response_code(403);
        echo json_encode([
            'status'  => 'error',
            'message' => 'Invalid or missing CSRF token. Reload the admin page and try again.',
            'data'    => null,
        ]);
        exit;
    }
}
