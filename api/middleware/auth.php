<?php
require_once __DIR__ . '/../utils/auth_token.php';
require_once __DIR__ . '/../utils/response.php';

class AuthMiddleware {
    public static function getAuthenticatedUser($requiredType = null) {
        $headers = getallheaders();
        $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : (isset($headers['authorization']) ? $headers['authorization'] : '');

        if (!$authHeader || strpos($authHeader, 'Bearer ') !== 0) {
            Response::error('Unauthorized: Missing or malformed token', 401);
        }

        $token = substr($authHeader, 7);
        $payload = AuthToken::verify($token);

        if (!$payload) {
            Response::error('Unauthorized: Invalid or expired token', 401);
        }

        if ($requiredType && $payload['type'] !== $requiredType && $payload['type'] !== 'super_admin') {
            Response::error('Forbidden: Insufficient privileges', 403);
        }

        return $payload;
    }
}
