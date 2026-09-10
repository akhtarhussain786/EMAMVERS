<?php
require_once __DIR__ . '/../config/config.php';

/**
 * Authenticated symmetric encryption for secrets held at rest (AI provider keys).
 * Uses AES-256-GCM with a key derived from APP_KEY.
 */
class Crypto {
    const PREFIX = 'v1.';

    private static function key() {
        return hash_hkdf('sha256', Config::appKey(), 32, 'examverse-secret-at-rest');
    }

    public static function encrypt($plaintext) {
        $iv = random_bytes(12);
        $tag = '';
        $cipher = openssl_encrypt($plaintext, 'aes-256-gcm', self::key(), OPENSSL_RAW_DATA, $iv, $tag);
        if ($cipher === false) {
            throw new RuntimeException('Unable to encrypt secret');
        }
        return self::PREFIX . base64_encode($iv . $tag . $cipher);
    }

    /**
     * Decrypts a stored secret. Values written before encryption was introduced
     * were base64-only; those are still readable so existing rows keep working
     * until they are re-saved.
     */
    public static function decrypt($stored) {
        if ($stored === null || $stored === '') return '';

        if (strncmp($stored, self::PREFIX, strlen(self::PREFIX)) !== 0) {
            return self::legacyDecode($stored);
        }

        $raw = base64_decode(substr($stored, strlen(self::PREFIX)), true);
        if ($raw === false || strlen($raw) < 29) return '';

        $iv     = substr($raw, 0, 12);
        $tag    = substr($raw, 12, 16);
        $cipher = substr($raw, 28);

        $plain = openssl_decrypt($cipher, 'aes-256-gcm', self::key(), OPENSSL_RAW_DATA, $iv, $tag);
        return $plain === false ? '' : $plain;
    }

    /** Legacy (pre-encryption) storage format: plain base64. */
    private static function legacyDecode($stored) {
        $decoded = base64_decode($stored, true);
        return $decoded === false ? '' : $decoded;
    }

    /** Whether a stored value still uses the legacy unencrypted format. */
    public static function isLegacy($stored) {
        return $stored !== null && $stored !== '' && strncmp($stored, self::PREFIX, strlen(self::PREFIX)) !== 0;
    }

    /** Display mask derived from the real key, never from its stored form. */
    public static function mask($plaintext) {
        $len = strlen($plaintext);
        if ($len === 0) return '';
        if ($len <= 8) return str_repeat('*', $len);
        return substr($plaintext, 0, 4) . str_repeat('*', max(4, min(20, $len - 8))) . substr($plaintext, -4);
    }
}
