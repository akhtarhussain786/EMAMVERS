<?php
/**
 * EXAMVERSE central configuration.
 *
 * Values are read from the project-root .env file (see .env.example), falling
 * back to environment variables and finally to safe defaults. Nothing secret is
 * hard-coded here — a missing APP_KEY in a non-debug environment is fatal.
 */
class Config {
    private static $values = null;

    private static function load() {
        if (self::$values !== null) return;

        $values = [];
        $envFile = __DIR__ . '/../../.env';
        if (is_readable($envFile)) {
            foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                $line = trim($line);
                if ($line === '' || $line[0] === '#') continue;
                $pos = strpos($line, '=');
                if ($pos === false) continue;
                $key = trim(substr($line, 0, $pos));
                $val = trim(substr($line, $pos + 1));
                // Strip optional surrounding quotes
                if (strlen($val) >= 2 && ($val[0] === '"' || $val[0] === "'") && substr($val, -1) === $val[0]) {
                    $val = substr($val, 1, -1);
                }
                $values[$key] = $val;
            }
        }
        self::$values = $values;
    }

    public static function get($key, $default = null) {
        self::load();
        if (array_key_exists($key, self::$values)) return self::$values[$key];
        $fromEnv = getenv($key);
        if ($fromEnv !== false && $fromEnv !== '') return $fromEnv;
        return $default;
    }

    public static function bool($key, $default = false) {
        $raw = self::get($key, null);
        if ($raw === null) return $default;
        return in_array(strtolower((string)$raw), ['1', 'true', 'yes', 'on'], true);
    }

    public static function isDebug() {
        return self::bool('APP_DEBUG', false);
    }

    /**
     * Secret used to sign auth tokens and derive the AI-key encryption key.
     * Refuses to fall back to a shared default outside debug mode.
     */
    public static function appKey() {
        $key = self::get('APP_KEY', '');
        if ($key === '' || strlen($key) < 32) {
            if (self::isDebug()) {
                // Deterministic per-checkout dev key so tokens survive a restart.
                return hash('sha256', 'examverse-local-dev-' . __DIR__);
            }
            http_response_code(500);
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode([
                'status'  => 'error',
                'message' => 'Server misconfigured: APP_KEY is missing or shorter than 32 characters. Copy .env.example to .env and set it.',
                'data'    => null,
            ]);
            exit;
        }
        return $key;
    }

    /** Origins permitted to call the API. '*' is only honoured in debug mode. */
    public static function allowedOrigins() {
        $raw = trim((string)self::get('CORS_ALLOWED_ORIGINS', ''));
        if ($raw === '') return self::isDebug() ? ['*'] : [];
        return array_values(array_filter(array_map('trim', explode(',', $raw))));
    }
}
