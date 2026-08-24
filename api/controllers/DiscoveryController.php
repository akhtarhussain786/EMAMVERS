<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';

class DiscoveryController {
    public static function getHomeData() {
        $db = Database::getConnection();

        // 1. Categories
        $categories = $db->query("SELECT id, name, slug, type, description, icon_url FROM exam_categories WHERE status = 'active' ORDER BY sort_order ASC")->fetchAll();

        // 2. Active Exams
        $exams = $db->query("
            SELECT e.id, e.title, e.slug, e.short_description, e.banner_url, c.name as category_name, o.short_name as org_name
            FROM exams e
            JOIN exam_categories c ON e.category_id = c.id
            LEFT JOIN organizations o ON e.organization_id = o.id
            WHERE e.status = 'active'
            LIMIT 6
        ")->fetchAll();

        // 3. Featured Monthly Challenge
        $challenge = $db->query("
            SELECT mc.id, mc.title, mc.month_year, mc.start_window, mc.end_window, mc.status, e.title as exam_title, t.id as test_id
            FROM monthly_challenges mc
            JOIN exams e ON mc.exam_id = e.id
            JOIN tests t ON mc.test_id = t.id
            WHERE mc.status = 'live'
            ORDER BY mc.id DESC LIMIT 1
        ")->fetch();

        // 4. Latest Current Affairs
        $currentAffairs = $db->query("SELECT id, title, category, publish_date FROM current_affairs WHERE is_published = 1 ORDER BY publish_date DESC LIMIT 3")->fetchAll();

        // 5. Featured Jobs
        $jobs = $db->query("SELECT id, title, organization_name, job_type, total_vacancies, last_date_to_apply FROM jobs ORDER BY id DESC LIMIT 3")->fetchAll();

        // 6. Topper Story
        $topper = $db->query("SELECT id, student_name, photo_url, exam_name, year, verified_rank, story_text FROM topper_stories WHERE is_verified = 1 ORDER BY id DESC LIMIT 1")->fetch();

        Response::json([
            'categories' => $categories,
            'featured_exams' => $exams,
            'monthly_challenge' => $challenge,
            'current_affairs' => $currentAffairs,
            'job_alerts' => $jobs,
            'featured_topper' => $topper
        ], 'Home discovery data loaded successfully');
    }

    public static function getCategories() {
        $db = Database::getConnection();
        $categories = $db->query("SELECT * FROM exam_categories WHERE status = 'active' ORDER BY sort_order ASC")->fetchAll();
        Response::json($categories, 'Exam categories loaded');
    }

    public static function getExamDetail($idOrSlug) {
        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT e.*, c.name as category_name, o.name as org_name, o.short_name as org_short_name
            FROM exams e
            JOIN exam_categories c ON e.category_id = c.id
            LEFT JOIN organizations o ON e.organization_id = o.id
            WHERE e.id = :val OR e.slug = :val
        ");
        $stmt->execute(['val' => $idOrSlug]);
        $exam = $stmt->fetch();

        if (!$exam) Response::error('Exam not found', 404);

        // Get effective pattern snapshot
        $stmtPattern = $db->prepare("
            SELECT ep.*, 
            (SELECT JSON_ARRAYAGG(JSON_OBJECT('id', ps.id, 'name', ps.section_name, 'count', ps.question_count, 'positive', ps.positive_marks, 'negative', ps.negative_marks))
             FROM pattern_sections ps WHERE ps.pattern_id = ep.id) as sections_json
            FROM exam_patterns ep
            WHERE ep.exam_id = :exam_id AND ep.is_active = 1
            LIMIT 1
        ");
        $stmtPattern->execute(['exam_id' => $exam['id']]);
        $pattern = $stmtPattern->fetch();
        if ($pattern && isset($pattern['sections_json'])) {
            $pattern['sections'] = json_decode($pattern['sections_json'], true);
            unset($pattern['sections_json']);
        }

        // Get available test series
        $stmtTests = $db->prepare("
            SELECT t.id, t.title, t.slug, t.test_type, t.is_paid, t.price, ep.total_questions, ep.total_marks, ep.total_duration_seconds
            FROM tests t
            JOIN exam_patterns ep ON t.pattern_id = ep.id
            WHERE t.exam_id = :exam_id AND t.status = 'published'
            ORDER BY t.id ASC
        ");
        $stmtTests->execute(['exam_id' => $exam['id']]);
        $tests = $stmtTests->fetchAll();

        Response::json([
            'exam' => $exam,
            'pattern' => $pattern,
            'tests' => $tests
        ], 'Exam details loaded successfully');
    }

    public static function searchExams() {
        $db = Database::getConnection();
        $q = trim($_GET['q'] ?? '');
        $catSlug = trim($_GET['category'] ?? '');
        $limit = min(intval($_GET['limit'] ?? 20), 50);

        $where = ["e.status='active'"];
        $params = [];

        if ($q) {
            $where[] = "(e.title LIKE ? OR e.short_description LIKE ? OR ec.keywords LIKE ?)";
            $params = array_merge($params, ["%$q%", "%$q%", "%$q%"]);
        }
        if ($catSlug) {
            $where[] = "ec.slug=?";
            $params[] = $catSlug;
        }

        $whereStr = implode(' AND ', $where);

        $stmt = $db->prepare("
            SELECT e.id, e.title, e.slug, e.short_description, e.exam_level, e.banner_url,
                   ec.name as category_name, ec.slug as category_slug,
                   o.short_name as org_name
            FROM exams e
            JOIN exam_categories ec ON e.category_id=ec.id
            LEFT JOIN organizations o ON e.organization_id=o.id
            WHERE $whereStr
            ORDER BY e.exam_level='main' DESC, e.title ASC
            LIMIT $limit
        ");
        $stmt->execute($params);
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Also get matching categories
        $cats = [];
        if ($q) {
            $catStmt = $db->prepare("SELECT id, name, slug, type FROM exam_categories WHERE (name LIKE ? OR keywords LIKE ?) AND status='active' LIMIT 5");
            $catStmt->execute(["%$q%", "%$q%"]);
            $cats = $catStmt->fetchAll(PDO::FETCH_ASSOC);
        }

        Response::json(['exams' => $results, 'categories' => $cats, 'total' => count($results)], 'Search results');
    }
}
