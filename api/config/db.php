<?php
require_once __DIR__ . '/config.php';

// EXAMVERSE Database Connection (PDO)
class Database {
    private static $pdo = null;

    public static function getConnection() {
        if (self::$pdo === null) {
            $host    = Config::get('DB_HOST', 'localhost');
            $port    = Config::get('DB_PORT', '3306');
            $name    = Config::get('DB_NAME', 'yatharth_staging');
            $user    = Config::get('DB_USER', 'yatharth_staging');
            $pass    = Config::get('DB_PASS', 'staging@1122');
            $charset = Config::get('DB_CHARSET', 'utf8mb4');

            $dsn = "mysql:host={$host};port={$port};dbname={$name};charset={$charset}";
            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];
            try {
                self::$pdo = new PDO($dsn, $user, $pass, $options);
            } catch (PDOException $e) {
                // Try 127.0.0.1 if localhost failed or vice versa
                try {
                    $altHost = ($host === 'localhost') ? '127.0.0.1' : 'localhost';
                    $altDsn = "mysql:host={$altHost};port={$port};dbname={$name};charset={$charset}";
                    self::$pdo = new PDO($altDsn, $user, $pass, $options);
                } catch (PDOException $e2) {
                    error_log('EXAMVERSE database connection failed: ' . $e2->getMessage());
                    http_response_code(500);
                    header('Content-Type: application/json; charset=utf-8');
                    echo json_encode([
                        'status'  => 'error',
                        'message' => 'Database connection failed: ' . $e2->getMessage() . ' (Host: ' . $host . ', DB: ' . $name . ', User: ' . $user . ')',
                        'data'    => null,
                    ]);
                    exit;
                }
            }
        }
        return self::$pdo;
    }
}
