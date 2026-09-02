<?php
require_once __DIR__ . '/response.php';

/**
 * Lightweight file-backed rate limiter for unauthenticated endpoints
 * (login, signup, OTP). Keyed by action + client identifier.
 */
class RateLimit {
    private static function storageDir() {
        $dir = __DIR__ . '/../storage/ratelimit';
        if (!is_dir($dir)) @mkdir($dir, 0770, true);
        return $dir;
    }

    public static function clientIp() {
        return $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    }

    /**
     * Allows $limit attempts per $windowSeconds. Terminates with 429 when the
     * budget is exhausted.
     */
    public static function enforce($action, $identifier, $limit = 10, $windowSeconds = 900) {
        $retryAfter = null;
        if (self::consume($action, $identifier, $limit, $windowSeconds, $retryAfter) === false) {
            header('Retry-After: ' . $retryAfter);
            Response::error('Too many attempts. Please try again in ' . ceil($retryAfter / 60) . ' minute(s).', 429);
        }
    }

    /**
     * Non-terminating variant for HTML pages (the admin panel), which must
     * render an error rather than emit a JSON 429.
     * Sets $limited to true when the budget is exhausted.
     */
    public static function enforceOrFlag(&$limited, $action, $identifier, $limit = 10, $windowSeconds = 900) {
        $limited = self::consume($action, $identifier, $limit, $windowSeconds) === false;
    }

    /**
     * Records an attempt. Returns false when the budget is already exhausted,
     * true otherwise. Shared by enforce() and enforceOrFlag().
     */
    private static function consume($action, $identifier, $limit, $windowSeconds, &$retryAfter = null) {
        $dir = self::storageDir();
        if (!is_dir($dir) || !is_writable($dir)) {
            error_log('EXAMVERSE rate limiter storage not writable: ' . $dir);
            return true;
        }

        $key  = hash('sha256', $action . '|' . strtolower((string)$identifier));
        $file = $dir . '/' . $key . '.json';
        $now  = time();

        $handle = @fopen($file, 'c+');
        if (!$handle) return true;

        flock($handle, LOCK_EX);
        $raw = stream_get_contents($handle);
        $hits = $raw ? (json_decode($raw, true) ?: []) : [];
        if (!is_array($hits)) $hits = [];

        $hits = array_values(array_filter($hits, function ($t) use ($now, $windowSeconds) {
            return is_int($t) && ($now - $t) < $windowSeconds;
        }));

        $exceeded = count($hits) >= $limit;
        if (!$exceeded) $hits[] = $now;

        ftruncate($handle, 0);
        rewind($handle);
        fwrite($handle, json_encode($hits));
        flock($handle, LOCK_UN);
        fclose($handle);

        if ($exceeded) {
            $retryAfter = max(1, $windowSeconds - ($now - $hits[0]));
            return false;
        }
        return true;
    }

    /** Clears the counter after a successful attempt. */
    public static function clear($action, $identifier) {
        $file = self::storageDir() . '/' . hash('sha256', $action . '|' . strtolower((string)$identifier)) . '.json';
        if (is_file($file)) @unlink($file);
    }
}
