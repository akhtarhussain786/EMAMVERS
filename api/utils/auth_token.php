<?php
// Simple & Secure Token Generator / Verifier for ExamVerse
class AuthToken {
    private static $secretKey = 'ExamVerse_Secret_Key_2026_Secure_Token!';

    public static function generate($userId, $userType = 'student', $extra = []) {
        $payload = [
            'sub' => $userId,
            'type' => $userType,
            'extra' => $extra,
            'iat' => time(),
            'exp' => time() + (86400 * 30) // 30 days validity
        ];
        $json = json_encode($payload);
        $base64 = base64_encode($json);
        $signature = hash_hmac('sha256', $base64, self::$secretKey);
        return $base64 . '.' . $signature;
    }

    public static function verify($token) {
        if (!$token) return false;
        $parts = explode('.', $token);
        if (count($parts) !== 2) return false;

        list($base64, $signature) = $parts;
        $expectedSignature = hash_hmac('sha256', $base64, self::$secretKey);
        if (!hash_equals($expectedSignature, $signature)) return false;

        $json = base64_decode($base64);
        $payload = json_decode($json, true);
        if (!$payload || !isset($payload['exp']) || $payload['exp'] < time()) {
            return false;
        }
        return $payload;
    }
}
