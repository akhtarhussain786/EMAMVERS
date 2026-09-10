<?php
require_once __DIR__ . '/config.php';

// EXAMVERSE Database Connection (PDO)
class Database {
    private static $pdo = null;

    public static function getConnection() {
        if (self::$pdo === null) {
            $host    = Config::get('DB_HOST', '127.0.0.1');
            $port    = Config::get('DB_PORT', '3306');
            $name    = Config::get('DB_NAME', 'examverse_db');
            $user    = Config::get('DB_USER', 'root');
            $pass    = Config::get('DB_PASS', '');
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
                error_log('EXAMVERSE database connection failed: ' . $e->getMessage());
                http_response_code(500);
                header('Content-Type: application/json; charset=utf-8');
                echo json_encode([
                    'status'  => 'error',
                    'message' => Config::isDebug()
                        ? 'Database connection failed: ' . $e->getMessage()
                        : 'Database unavailable. Please try again later.',
                    'data'    => null,
                ]);
                exit;
            }
        }
        return self::$pdo;
    }
}
