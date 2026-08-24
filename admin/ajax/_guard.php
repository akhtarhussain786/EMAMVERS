<?php
/**
 * Admin AJAX Guard — all admin/ajax/*.php files must include this.
 * Checks PHP session (same auth as admin panel), returns JSON only.
 */
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

// Block non-logged-in requests
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
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
    $raw = file_get_contents('php://input');
    return $raw ? (json_decode($raw, true) ?? []) : [];
}
