<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/crypto.php';

class SystemSettings {
    private static array $cache = [];
    private static bool $loaded = false;

    /**
     * Preload all settings from DB into memory cache.
     */
    private static function load(): void {
        if (self::$loaded) return;
        try {
            $db = Database::getConnection();
            $stmt = $db->query("SELECT setting_key, setting_value, is_encrypted, category, description FROM system_settings");
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $row) {
                $val = $row['setting_value'];
                if ($row['is_encrypted'] && !empty($val)) {
                    $val = Crypto::decrypt($val);
                }
                self::$cache[$row['setting_key']] = [
                    'value' => $val,
                    'is_encrypted' => (bool)$row['is_encrypted'],
                    'category' => $row['category'],
                    'description' => $row['description']
                ];
            }
            self::$loaded = true;
        } catch (Throwable $e) {
            // If table doesn't exist or DB issue, proceed with empty cache
            self::$loaded = false;
        }
    }

    /**
     * Get single setting value by key, with fallback to .env / Config.
     */
    public static function get(string $key, $default = null) {
        self::load();
        if (isset(self::$cache[$key])) {
            $val = self::$cache[$key]['value'];
            if ($val !== '' && $val !== null) return $val;
        }
        return Config::get($key, $default);
    }

    /**
     * Set / Update single setting.
     */
    public static function set(string $key, $value, bool $isEncrypted = false, string $category = 'general', ?string $description = null): bool {
        $db = Database::getConnection();
        $storedValue = $value;
        if ($isEncrypted && !empty($value)) {
            $storedValue = Crypto::encrypt($value);
        }

        $stmt = $db->prepare("
            INSERT INTO system_settings (setting_key, setting_value, is_encrypted, category, description)
            VALUES (:k, :v, :enc, :cat, :desc)
            ON DUPLICATE KEY UPDATE
                setting_value = VALUES(setting_value),
                is_encrypted = VALUES(is_encrypted),
                category = VALUES(category),
                description = COALESCE(VALUES(description), description)
        ");
        $success = $stmt->execute([
            'k' => $key,
            'v' => $storedValue,
            'enc' => $isEncrypted ? 1 : 0,
            'cat' => $category,
            'desc' => $description
        ]);

        if ($success) {
            self::$cache[$key] = [
                'value' => $value,
                'is_encrypted' => $isEncrypted,
                'category' => $category,
                'description' => $description
            ];
        }
        return $success;
    }

    /**
     * Get all settings grouped by category for Admin UI.
     * Mask encrypted values by default so secrets aren't exposed in plain HTML.
     */
    public static function getAll(bool $maskSecrets = true): array {
        self::$loaded = false; // Fresh load from DB
        self::load();

        $output = [];
        foreach (self::$cache as $k => $item) {
            $cat = $item['category'] ?? 'general';
            $val = $item['value'];
            $masked = false;
            if ($item['is_encrypted'] && !empty($val) && $maskSecrets) {
                $val = Crypto::mask($val);
                $masked = true;
            }
            $output[$cat][$k] = [
                'value' => $val,
                'is_encrypted' => $item['is_encrypted'],
                'is_masked' => $masked,
                'has_value' => !empty($item['value']),
                'description' => $item['description']
            ];
        }
        return $output;
    }
}
