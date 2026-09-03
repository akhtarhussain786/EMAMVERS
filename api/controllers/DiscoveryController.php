<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

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

        // Optional auth: anonymous visitors simply get no resume card.
        $viewer = AuthMiddleware::getOptionalUser();
        $resume = null;
        if ($viewer) {
            $rStmt = $db->prepare("
                SELECT att.id AS attempt_id, att.started_at, t.title AS test_title,
                       e.title AS exam_title, ep.total_duration_seconds,
                       (SELECT COUNT(*) FROM attempt_answers aa WHERE aa.attempt_id = att.id AND aa.is_answered = 1) AS answered,
                       COALESCE(
                         (SELECT COUNT(*) FROM attempt_questions aq WHERE aq.attempt_id = att.id),
                         (SELECT COUNT(*) FROM test_questions tq WHERE tq.test_id = att.test_id)
                       ) AS total_questions
                FROM test_attempts att
                JOIN tests t ON att.test_id = t.id
                JOIN exams e ON t.exam_id = e.id
                LEFT JOIN exam_patterns ep ON t.pattern_id = ep.id
                WHERE att.user_id = ? AND att.status = 'in_progress'
                ORDER BY att.id DESC LIMIT 1
            ");
            $rStmt->execute([$viewer['sub']]);
            $row = $rStmt->fetch();
            if ($row) {
                $total = max(1, (int)$row['total_questions']);
                $resume = [
                    'attempt_id'      => (int)$row['attempt_id'],
                    'test_title'      => $row['test_title'],
                    'exam_title'      => $row['exam_title'],
                    'answered'        => (int)$row['answered'],
                    'total_questions' => (int)$row['total_questions'],
                    'percent_complete'=> (int)round(((int)$row['answered'] / $total) * 100),
                ];
            }
        }

        Response::json([
            'resume_attempt' => $resume,
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
            WHERE e.id = :val_id OR e.slug = :val_slug
        ");
        $stmt->execute(['val_id' => $idOrSlug, 'val_slug' => $idOrSlug]);
        $exam = $stmt->fetch();

        if (!$exam) Response::error('Exam not found', 404);

        // Get effective pattern snapshot
        $stmtPattern = $db->prepare("
            SELECT ep.*
            FROM exam_patterns ep
            WHERE ep.exam_id = :exam_id AND ep.is_active = 1
            LIMIT 1
        ");
        $stmtPattern->execute(['exam_id' => $exam['id']]);
        $pattern = $stmtPattern->fetch();
        
        if ($pattern) {
            $stmtSec = $db->prepare("
                SELECT ps.id, ps.section_name as name, ps.question_count as count, ps.positive_marks as positive, ps.negative_marks as negative
                FROM pattern_sections ps
                WHERE ps.pattern_id = :pid
                ORDER BY ps.sort_order ASC
            ");
            $stmtSec->execute(['pid' => $pattern['id']]);
            $pattern['sections'] = $stmtSec->fetchAll(PDO::FETCH_ASSOC);
        }

        // Get available test series
        $stmtTests = $db->prepare("
            SELECT t.id, t.title, t.slug, t.test_type, t.is_paid, t.price, t.is_randomised,
                   ep.total_questions, ep.total_marks, ep.total_duration_seconds,
                   -- Real cohort size, so the UI never has to invent one.
                   (SELECT COUNT(*) FROM test_attempts a WHERE a.test_id = t.id AND a.status = 'evaluated') AS total_attempts
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
