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
                // Auto-discovery: connect to MySQL server and discover visible databases
                try {
                    $bareDsn = "mysql:host={$host};port={$port};charset={$charset}";
                    $barePdo = new PDO($bareDsn, $user, $pass, $options);
                    $stmt = $barePdo->query("SHOW DATABASES");
                    $allDbs = $stmt->fetchAll(PDO::FETCH_COLUMN);

                    // Check if requested db or any staging/examverse db exists
                    $matchedDb = null;
                    foreach ($allDbs as $dbItem) {
                        $cleaned = trim($dbItem);
                        if ($cleaned === $name || $cleaned === trim($name) || strpos($cleaned, 'staging') !== false || strpos($cleaned, 'examverse') !== false) {
                            $matchedDb = $dbItem;
                            break;
                        }
                    }

                    if ($matchedDb !== null) {
                        $barePdo->exec("USE `" . str_replace("`", "``", $matchedDb) . "`");
                        self::$pdo = $barePdo;
                        return self::$pdo;
                    }

                    // If user is connected but no matching database is assigned
                    http_response_code(500);
                    header('Content-Type: application/json; charset=utf-8');
                    echo json_encode([
                        'status'  => 'error',
                        'message' => "User '{$user}' is connected, but has no privileges on database '{$name}'. Available databases for this user: [" . implode(', ', $allDbs) . "]. Please go to cPanel -> MySQL Databases -> 'Add User To Database' -> select user '{$user}' & database '{$name}' -> tick 'ALL PRIVILEGES' -> save.",
                        'data'    => null,
                    ]);
                    exit;
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
