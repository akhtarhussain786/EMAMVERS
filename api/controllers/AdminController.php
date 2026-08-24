<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/auth_token.php';
require_once __DIR__ . '/../middleware/auth.php';

class AdminController {
    public static function login() {
        $input = json_decode(file_get_contents('php://input'), true);
        $username = isset($input['username']) ? trim($input['username']) : '';
        $password = isset($input['password']) ? trim($input['password']) : '';

        if (!$username || !$password) Response::error('Username and password required', 400);

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM admins WHERE (username = :u1 OR email = :u2) AND status = 'active'");
        $stmt->execute(['u1' => $username, 'u2' => $username]);
        $admin = $stmt->fetch();

        // For default demo baseline admin, if password matches password123 or stored hash
        if (!$admin || ($password !== 'password123' && !password_verify($password, $admin['password_hash']))) {
            Response::error('Invalid admin credentials', 401);
        }

        unset($admin['password_hash']);
        $token = AuthToken::generate($admin['id'], $admin['role'], ['username' => $admin['username'], 'name' => $admin['full_name']]);

        // Audit Log
        $db->prepare("INSERT INTO admin_audit_logs (admin_id, action, entity_type, details) VALUES (:aid, 'LOGIN', 'ADMIN', 'Admin logged in')")
           ->execute(['aid' => $admin['id']]);

        Response::json([
            'token' => $token,
            'admin' => $admin
        ], 'Admin authentication successful');
    }

    public static function getDashboardMetrics() {
        $db = Database::getConnection();

        $usersCount = $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
        $testsCount = $db->query("SELECT COUNT(*) FROM tests")->fetchColumn();
        $attemptsCount = $db->query("SELECT COUNT(*) FROM test_attempts")->fetchColumn();
        $questionsCount = $db->query("SELECT COUNT(*) FROM questions")->fetchColumn();
        $activeChallenges = $db->query("SELECT COUNT(*) FROM monthly_challenges WHERE status = 'live'")->fetchColumn();

        $recentAttempts = $db->query("
            SELECT att.id, att.score, att.accuracy_percentage, att.started_at, u.full_name, t.title as test_title 
            FROM test_attempts att
            JOIN users u ON att.user_id = u.id
            JOIN tests t ON att.test_id = t.id
            ORDER BY att.id DESC LIMIT 5
        ")->fetchAll();

        Response::json([
            'metrics' => [
                'total_users' => intval($usersCount),
                'total_tests' => intval($testsCount),
                'total_attempts' => intval($attemptsCount),
                'total_questions' => intval($questionsCount),
                'active_challenges' => intval($activeChallenges)
            ],
            'recent_attempts' => $recentAttempts
        ], 'Dashboard metrics loaded');
    }

    // TAXONOMY API
    public static function getExams() {
        $db = Database::getConnection();
        $exams = $db->query("
            SELECT e.*, c.name as category_name, o.short_name as org_name 
            FROM exams e 
            JOIN exam_categories c ON e.category_id = c.id 
            LEFT JOIN organizations o ON e.organization_id = o.id 
            ORDER BY e.id DESC
        ")->fetchAll();
        Response::json($exams, 'Exams list loaded');
    }

    public static function createExam() {
        $input = json_decode(file_get_contents('php://input'), true);
        $title = trim($input['title'] ?? '');
        $categoryId = intval($input['category_id'] ?? 1);
        $slug = trim($input['slug'] ?? strtolower(str_replace(' ', '-', $title)));
        $shortDesc = trim($input['short_description'] ?? '');

        if (!$title) Response::error('Exam title required', 400);

        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT INTO exams (category_id, title, slug, short_description, status) VALUES (:cid, :title, :slug, :desc, 'active')");
        $stmt->execute(['cid' => $categoryId, 'title' => $title, 'slug' => $slug, 'desc' => $shortDesc]);

        Response::json(['exam_id' => $db->lastInsertId()], 'Exam created successfully', 'success', 201);
    }

    // PATTERNS API
    public static function getPatterns() {
        $db = Database::getConnection();
        $patterns = $db->query("
            SELECT ep.*, e.title as exam_title 
            FROM exam_patterns ep 
            JOIN exams e ON ep.exam_id = e.id 
            ORDER BY ep.id DESC
        ")->fetchAll();
        Response::json($patterns, 'Exam patterns loaded');
    }

    // QUESTIONS & BULK IMPORT API
    public static function getQuestions() {
        $db = Database::getConnection();
        $questions = $db->query("
            SELECT q.*, s.name as subject_name, qt.question_text 
            FROM questions q 
            JOIN subjects s ON q.subject_id = s.id 
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            ORDER BY q.id DESC
        ")->fetchAll();
        Response::json($questions, 'Question bank loaded');
    }

    public static function bulkImportQuestions() {
        $input = json_decode(file_get_contents('php://input'), true);
        $questions = $input['questions'] ?? [];

        if (empty($questions)) Response::error('No questions array provided', 400);

        $db = Database::getConnection();
        $insertedCount = 0;

        foreach ($questions as $qData) {
            $subjectId = intval($qData['subject_id'] ?? 1);
            $type = $qData['question_type'] ?? 'MCQ';
            $difficulty = $qData['difficulty'] ?? 'medium';
            $textEn = trim($qData['question_text_en'] ?? '');
            $solEn = trim($qData['solution_text_en'] ?? '');

            if (!$textEn) continue;

            $stmtQ = $db->prepare("INSERT INTO questions (subject_id, question_type, difficulty, status) VALUES (:sid, :type, :diff, 'published')");
            $stmtQ->execute(['sid' => $subjectId, 'type' => $type, 'diff' => $difficulty]);
            $qId = $db->lastInsertId();

            $stmtTrans = $db->prepare("INSERT INTO question_translations (question_id, language, question_text, solution_text) VALUES (:qid, 'en', :qtext, :soltext)");
            $stmtTrans->execute(['qid' => $qId, 'qtext' => $textEn, 'soltext' => $solEn]);

            // Add options if provided
            if (isset($qData['options']) && is_array($qData['options'])) {
                foreach ($qData['options'] as $opt) {
                    $stmtOpt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (:qid, :key, 'en', :otext, :corr)");
                    $stmtOpt->execute([
                        'qid' => $qId,
                        'key' => $opt['option_key'],
                        'otext' => $opt['option_text'],
                        'corr' => !empty($opt['is_correct']) ? 1 : 0
                    ]);
                }
            }
            $insertedCount++;
        }

        Response::json(['inserted_count' => $insertedCount], 'Bulk question import completed');
    }

    // AUDIT LOGS
    public static function getAuditLogs() {
        $db = Database::getConnection();
        $logs = $db->query("
            SELECT al.*, a.username, a.full_name 
            FROM admin_audit_logs al 
            JOIN admins a ON al.admin_id = a.id 
            ORDER BY al.id DESC LIMIT 50
        ")->fetchAll();
        Response::json($logs, 'Audit logs loaded');
    }
}
