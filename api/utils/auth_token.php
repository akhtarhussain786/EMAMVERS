<?php
require_once __DIR__ . '/../config/config.php';

/**
 * Signed, self-contained bearer token for ExamVerse.
 *
 * Format: base64url(payload) . base64url(hmac_sha256(payload, APP_KEY))
 */
class AuthToken {
    private static function secret() {
        return Config::appKey();
    }

    private static function b64UrlEncode($raw) {
        return rtrim(strtr(base64_encode($raw), '+/', '-_'), '=');
    }

    private static function b64UrlDecode($encoded) {
        $padded = strtr($encoded, '-_', '+/');
        $remainder = strlen($padded) % 4;
        if ($remainder) $padded .= str_repeat('=', 4 - $remainder);
        return base64_decode($padded, true);
    }

    public static function generate($userId, $userType = 'student', $extra = []) {
        $payload = [
            'sub'   => (int)$userId,
            'type'  => $userType,
            'extra' => $extra,
            'iat'   => time(),
            'exp'   => time() + (86400 * 30) // 30 days validity
        ];
        $body = self::b64UrlEncode(json_encode($payload));
        $signature = self::b64UrlEncode(hash_hmac('sha256', $body, self::secret(), true));
        return $body . '.' . $signature;
    }

    /**
     * Verifies a token and returns a normalised claim set, or false.
     *
     * The returned array exposes the user id under 'sub', 'id' and 'user_id'
     * because callers across the codebase reach for all three.
     */
    public static function verify($token = null) {
        if (!$token) {
            $token = self::tokenFromRequest();
        }
        if (!$token) return false;

        $parts = explode('.', $token);
        if (count($parts) !== 2) return false;

        list($body, $signature) = $parts;
        $expected = self::b64UrlEncode(hash_hmac('sha256', $body, self::secret(), true));
        if (!hash_equals($expected, $signature)) return false;

        $json = self::b64UrlDecode($body);
        if ($json === false) return false;

        $payload = json_decode($json, true);
        if (!is_array($payload) || !isset($payload['exp'], $payload['sub'])) return false;
        if ($payload['exp'] < time()) return false;

        $userId = (int)$payload['sub'];
        if ($userId <= 0) return false;

        return [
            'sub'     => $userId,
            'id'      => $userId,
            'user_id' => $userId,
            'type'    => $payload['type'] ?? 'student',
            'extra'   => $payload['extra'] ?? [],
            'payload' => $payload,
        ];
    }

    public static function tokenFromRequest() {
        $authHeader = '';
        if (function_exists('getallheaders')) {
            $headers = getallheaders() ?: [];
            foreach ($headers as $name => $value) {
                if (strcasecmp($name, 'Authorization') === 0) { $authHeader = $value; break; }
            }
        }
        if (!$authHeader && isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        }
        if (!$authHeader && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        if (preg_match('/Bearer\s+(\S+)/i', $authHeader, $m)) return $m[1];
        return null;
    }
}
