<?php
require_once __DIR__ . '/../config/config.php';

// Standard API Response Utility
class Response {
    private static $corsSent = false;

    /**
     * Emits CORS headers for the requesting origin when it is allow-listed.
     * A wildcard is only used when CORS_ALLOWED_ORIGINS is literally '*'.
     */
    public static function sendCorsHeaders() {
        if (self::$corsSent) return;
        self::$corsSent = true;

        $allowed = Config::allowedOrigins();
        $origin  = $_SERVER['HTTP_ORIGIN'] ?? '';

        if (in_array('*', $allowed, true)) {
            header('Access-Control-Allow-Origin: *');
        } elseif ($origin !== '' && in_array($origin, $allowed, true)) {
            header('Access-Control-Allow-Origin: ' . $origin);
            header('Access-Control-Allow-Credentials: true');
            header('Vary: Origin');
        }

        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
        header('X-Content-Type-Options: nosniff');
    }

    public static function json($data = null, $message = '', $status = 'success', $code = 200, $errors = []) {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');
        self::sendCorsHeaders();

        if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
            exit(0);
        }

        echo json_encode([
            'status' => $status,
            'message' => $message,
            'data' => $data,
            'errors' => $errors,
            'timestamp' => date('Y-m-d H:i:s')
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function error($message = 'An error occurred', $code = 400, $errors = []) {
        self::json(null, $message, 'error', $code, $errors);
    }
}
