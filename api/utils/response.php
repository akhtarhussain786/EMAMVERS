<?php
// Standard API Response Utility
class Response {
    public static function json($data = null, $message = '', $status = 'success', $code = 200, $errors = []) {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
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
