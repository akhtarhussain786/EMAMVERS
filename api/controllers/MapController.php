<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/auth_token.php';

class MapController {
    public static function getCategories() {
        $db = Database::getConnection();
        $stmt = $db->query("SELECT * FROM map_categories ORDER BY sort_order ASC");
        $categories = $stmt->fetchAll();
        Response::json(['categories' => $categories], 'Map categories loaded successfully');
    }

    public static function getLocations() {
        $db = Database::getConnection();
        $catSlug = isset($_GET['category']) ? trim($_GET['category']) : '';
        $state = isset($_GET['state']) ? trim($_GET['state']) : '';
        $search = isset($_GET['q']) ? trim($_GET['q']) : '';

        $sql = "SELECT l.*, c.name as category_name, c.slug as category_slug, c.icon as category_icon 
                FROM map_locations l
                JOIN map_categories c ON l.category_id = c.id
                WHERE l.status = 'active'";
        $params = [];

        if ($catSlug) {
            $sql .= " AND c.slug = :catSlug";
            $params['catSlug'] = $catSlug;
        }

        if ($state) {
            $sql .= " AND l.state = :state";
            $params['state'] = $state;
        }

        if ($search) {
            $sql .= " AND (l.name LIKE :q OR l.state LIKE :q OR l.country LIKE :q OR l.short_description LIKE :q)";
            $params['q'] = '%' . $search . '%';
        }

        $sql .= " ORDER BY l.id ASC";
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $locations = $stmt->fetchAll();

        Response::json(['locations' => $locations], 'Map locations loaded successfully');
    }

    public static function getLocationDetail($id) {
        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT l.*, c.name as category_name, c.slug as category_slug
            FROM map_locations l
            JOIN map_categories c ON l.category_id = c.id
            WHERE l.id = :id
        ");
        $stmt->execute(['id' => $id]);
        $location = $stmt->fetch();

        if (!$location) {
            Response::error('Location not found', 404);
        }

        // Facts
        $stmtFacts = $db->prepare("SELECT fact FROM map_location_facts WHERE location_id = :id ORDER BY sort_order ASC");
        $stmtFacts->execute(['id' => $id]);
        $facts = $stmtFacts->fetchAll(PDO::FETCH_COLUMN);

        if (empty($facts) && !empty($location['important_facts'])) {
            $facts = array_map('trim', explode('.', $location['important_facts']));
            $facts = array_filter($facts);
        }

        $location['facts'] = $facts;

        Response::json(['location' => $location], 'Location details loaded successfully');
    }

    public static function getMapQuiz() {
        $db = Database::getConnection();
        $stmt = $db->query("
            SELECT l.id as location_id, l.name, l.state, l.country, l.latitude, l.longitude, l.short_description,
                   c.name as category_name
            FROM map_locations l
            JOIN map_categories c ON l.category_id = c.id
            ORDER BY RAND() LIMIT 10
        ");
        $locations = $stmt->fetchAll();

        Response::json(['quiz_questions' => $locations], 'Map quiz generated successfully');
    }

    public static function getProgress() {
        $auth = AuthToken::verify();
        $userId = $auth ? $auth['user_id'] : 1;

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT p.*, l.name as location_name, l.state, c.name as category_name
            FROM map_user_progress p
            JOIN map_locations l ON p.location_id = l.id
            JOIN map_categories c ON l.category_id = c.id
            WHERE p.user_id = :userId
        ");
        $stmt->execute(['userId' => $userId]);
        $progress = $stmt->fetchAll();

        $totalLocations = $db->query("SELECT COUNT(*) FROM map_locations")->fetchColumn();
        $learnedCount = count($progress);

        Response::json([
            'progress' => $progress,
            'learned_count' => $learnedCount,
            'total_locations' => $totalLocations,
            'mastery_percentage' => $totalLocations > 0 ? round(($learnedCount / $totalLocations) * 100, 1) : 0,
        ], 'Map progress fetched successfully');
    }
}
