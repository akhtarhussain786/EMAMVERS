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

        if (!$admin || !password_verify($password, $admin['password_hash'])) {
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

    // ─── ADMIN TEST BUILDER ─────────────────────────────────────────────

    public static function createTest() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $input = json_decode(file_get_contents('php://input'), true);

        $examId    = intval($input['exam_id'] ?? 0);
        $patternId = intval($input['pattern_id'] ?? 0);
        $title     = trim($input['title'] ?? '');
        $testType  = $input['test_type'] ?? 'full_mock';
        $isPaid    = !empty($input['is_paid']) ? 1 : 0;
        $price     = floatval($input['price'] ?? 0.00);
        $instructions = trim($input['instructions'] ?? 'Read each question carefully.');

        if (!$examId || !$patternId || empty($title)) {
            Response::error('exam_id, pattern_id, and title are required', 422);
        }

        $slug = preg_replace('/[^a-z0-9]+/', '-', strtolower($title)) . '-' . uniqid();

        $db = Database::getConnection();
        $stmt = $db->prepare("
            INSERT INTO tests (exam_id, pattern_id, title, slug, test_type, is_paid, price, instructions, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'published')
        ");
        $stmt->execute([$examId, $patternId, $title, $slug, $testType, $isPaid, $price, $instructions]);
        $testId = $db->lastInsertId();

        Response::json(['test_id' => $testId, 'slug' => $slug], 'Test created successfully', 'success', 201);
    }

    public static function assignQuestionsToTest() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $input = json_decode(file_get_contents('php://input'), true);

        $testId = intval($input['test_id'] ?? 0);
        $questionAssignments = $input['assignments'] ?? []; // [{question_id, section_id, question_order, positive_marks, negative_marks}]

        if (!$testId || empty($questionAssignments)) {
            Response::error('test_id and assignments array are required', 422);
        }

        $db = Database::getConnection();

        // Clear existing assignments for test
        $db->prepare("DELETE FROM test_questions WHERE test_id = ?")->execute([$testId]);

        $assignedCount = 0;
        foreach ($questionAssignments as $idx => $assign) {
            $qId = intval($assign['question_id'] ?? 0);
            $secId = isset($assign['section_id']) ? intval($assign['section_id']) : null;
            $order = intval($assign['question_order'] ?? ($idx + 1));
            $pos = floatval($assign['positive_marks'] ?? 2.00);
            $neg = floatval($assign['negative_marks'] ?? 0.50);

            if (!$qId) continue;

            $stmt = $db->prepare("
                INSERT INTO test_questions (test_id, question_id, section_id, question_order, positive_marks, negative_marks)
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$testId, $qId, $secId, $order, $pos, $neg]);
            $assignedCount++;
        }

        Response::json(['test_id' => $testId, 'assigned_count' => $assignedCount], "$assignedCount questions assigned to test");
    }

    // ─── TAXONOMY MANAGEMENT ──────────────────────────────────────────

    public static function createCategory() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $input = json_decode(file_get_contents('php://input'), true);

        $name = trim($input['name'] ?? '');
        $type = $input['type'] ?? 'government';
        $description = trim($input['description'] ?? '');
        $iconUrl = trim($input['icon_url'] ?? '');
        $keywords = trim($input['keywords'] ?? '');

        if (empty($name)) Response::error('Category name is required', 422);

        $slug = preg_replace('/[^a-z0-9]+/', '-', strtolower($name));
        $db = Database::getConnection();

        $stmt = $db->prepare("
            INSERT INTO exam_categories (name, slug, type, description, icon_url, keywords, status)
            VALUES (?, ?, ?, ?, ?, ?, 'active')
        ");
        $stmt->execute([$name, $slug, $type, $description, $iconUrl, $keywords]);

        Response::json(['category_id' => $db->lastInsertId()], 'Category created successfully', 'success', 201);
    }

    public static function createSubject() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $input = json_decode(file_get_contents('php://input'), true);

        $name = trim($input['name'] ?? '');
        $code = trim($input['code'] ?? strtolower(str_replace(' ', '_', $name)));

        if (empty($name)) Response::error('Subject name is required', 422);

        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT INTO subjects (name, code) VALUES (?, ?)");
        $stmt->execute([$name, $code]);

        Response::json(['subject_id' => $db->lastInsertId()], 'Subject created successfully', 'success', 201);
    }

    // ─── QUESTION CRUD ────────────────────────────────────────────────

    public static function createQuestion() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $input = json_decode(file_get_contents('php://input'), true);

        $subjectId = intval($input['subject_id'] ?? 1);
        $chapterId = isset($input['chapter_id']) ? intval($input['chapter_id']) : null;
        $topicId = isset($input['topic_id']) ? intval($input['topic_id']) : null;
        $type = $input['question_type'] ?? 'MCQ';
        $difficulty = $input['difficulty'] ?? 'medium';
        $questionText = trim($input['question_text'] ?? '');
        $solutionText = trim($input['solution_text'] ?? '');
        $options = $input['options'] ?? []; // [{option_key, option_text, is_correct}]

        if (empty($questionText)) Response::error('question_text is required', 422);

        $db = Database::getConnection();

        $qStmt = $db->prepare("INSERT INTO questions (subject_id, chapter_id, topic_id, question_type, difficulty, status) VALUES (?, ?, ?, ?, ?, 'published')");
        $qStmt->execute([$subjectId, $chapterId, $topicId, $type, $difficulty]);
        $qId = $db->lastInsertId();

        $tStmt = $db->prepare("INSERT INTO question_translations (question_id, language, question_text, solution_text) VALUES (?, 'en', ?, ?)");
        $tStmt->execute([$qId, $questionText, $solutionText]);

        foreach ($options as $opt) {
            $oStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
            $oStmt->execute([$qId, $opt['option_key'], $opt['option_text'], !empty($opt['is_correct']) ? 1 : 0]);
        }

        Response::json(['question_id' => $qId], 'Question created successfully', 'success', 201);
    }

    public static function deleteQuestion($id) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $db->prepare("DELETE FROM questions WHERE id = ?")->execute([$id]);
        Response::json(['deleted' => true], 'Question deleted from bank');
    }

    // ─── CHALLENGE MANAGER ────────────────────────────────────────────

    public static function createChallenge() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $input = json_decode(file_get_contents('php://input'), true);

        $examId = intval($input['exam_id'] ?? 0);
        $testId = intval($input['test_id'] ?? 0);
        $title = trim($input['title'] ?? '');
        $monthYear = trim($input['month_year'] ?? date('F Y'));
        $startWindow = $input['start_window'] ?? date('Y-m-01 00:00:00');
        $endWindow = $input['end_window'] ?? date('Y-m-t 23:59:59');

        if (!$examId || !$testId || empty($title)) {
            Response::error('exam_id, test_id, and title are required', 422);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("
            INSERT INTO monthly_challenges (exam_id, test_id, title, month_year, start_window, end_window, status)
            VALUES (?, ?, ?, ?, ?, ?, 'live')
        ");
        $stmt->execute([$examId, $testId, $title, $monthYear, $startWindow, $endWindow]);

        Response::json(['challenge_id' => $db->lastInsertId()], 'Monthly challenge created and live!', 'success', 201);
    }
}
