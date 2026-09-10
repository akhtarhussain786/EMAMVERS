<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

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

        $limit = isset($_GET['limit']) ? max(1, min(25, intval($_GET['limit']))) : 10;

        $stmt = $db->prepare("
            SELECT l.id as location_id, l.name, l.state, l.country, l.latitude, l.longitude, l.short_description,
                   l.category_id, c.name as category_name
            FROM map_locations l
            JOIN map_categories c ON l.category_id = c.id
            WHERE l.status = 'active'
            ORDER BY RAND() LIMIT :lim
        ");
        $stmt->bindValue('lim', $limit, PDO::PARAM_INT);
        $stmt->execute();
        $locations = $stmt->fetchAll();

        if (empty($locations)) {
            Response::json(['quiz_questions' => []], 'No map locations available yet');
        }

        // Distractors come from the real location table so they are plausible
        // and are guaranteed never to duplicate the correct answer.
        $statePool = $db->query("SELECT DISTINCT state FROM map_locations WHERE state IS NOT NULL AND state <> '' AND status = 'active'")
                        ->fetchAll(PDO::FETCH_COLUMN);

        foreach ($locations as &$loc) {
            $answer = $loc['state'];
            $pool = array_values(array_filter($statePool, function ($s) use ($answer) {
                return strcasecmp(trim($s), trim((string)$answer)) !== 0;
            }));
            shuffle($pool);
            $distractors = array_slice($pool, 0, 3);

            $options = array_merge([$answer], $distractors);
            $options = array_values(array_unique(array_filter($options, function ($o) { return $o !== null && $o !== ''; })));
            shuffle($options);

            $loc['question_text'] = 'In which state is "' . $loc['name'] . '" located?';
            $loc['options'] = $options;
            $loc['correct_answer'] = $answer;
        }
        unset($loc);

        Response::json(['quiz_questions' => $locations], 'Map quiz generated successfully');
    }

    /** Records a learned/attempted location so map progress reflects real activity. */
    public static function recordProgress() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $locationId = intval($input['location_id'] ?? 0);
        $isCorrect  = !empty($input['is_correct']) ? 1 : 0;

        if (!$locationId) Response::error('location_id is required', 422);

        $db = Database::getConnection();
        $exists = $db->prepare("SELECT 1 FROM map_locations WHERE id = ?");
        $exists->execute([$locationId]);
        if (!$exists->fetchColumn()) Response::error('Location not found', 404);

        $db->prepare("
            INSERT INTO map_user_progress (user_id, location_id, is_learned, correct_attempts, total_attempts)
            VALUES (:uid, :lid, 1, :correct, 1)
            ON DUPLICATE KEY UPDATE
                is_learned = 1,
                correct_attempts = correct_attempts + VALUES(correct_attempts),
                total_attempts = total_attempts + 1
        ")->execute(['uid' => $userId, 'lid' => $locationId, 'correct' => $isCorrect]);

        Response::json(['recorded' => true], 'Map progress recorded');
    }

    public static function getProgress() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

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
