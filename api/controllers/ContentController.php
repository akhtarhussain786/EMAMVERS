<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../utils/crypto.php';
require_once __DIR__ . '/../utils/rate_limit.php';

class ContentController {

    // ─── LIST CURRENT AFFAIRS (WITH FILTERS) ─────────────────────────

    public static function getCurrentAffairs() {
        $db = Database::getConnection();

        $page     = max(1, intval($_GET['page'] ?? 1));
        $limit    = min(intval($_GET['limit'] ?? 20), 50);
        $offset   = ($page - 1) * $limit;
        $category = trim($_GET['category'] ?? '');
        $date     = trim($_GET['date'] ?? '');
        $search   = trim($_GET['q'] ?? '');

        $where = ["is_published = 1"];
        $params = [];

        if ($category && strtolower($category) !== 'all') {
            $where[] = "category LIKE ?";
            $params[] = "%$category%";
        }

        if ($date) {
            $where[] = "publish_date = ?";
            $params[] = $date;
        }

        if ($search) {
            $where[] = "(title LIKE ? OR summary LIKE ? OR content_body LIKE ? OR tags LIKE ?)";
            $params = array_merge($params, ["%$search%", "%$search%", "%$search%", "%$search%"]);
        }

        $whereStr = implode(' AND ', $where);

        // Count total
        $countStmt = $db->prepare("SELECT COUNT(*) FROM current_affairs WHERE $whereStr");
        $countStmt->execute($params);
        $total = $countStmt->fetchColumn();

        // Fetch articles
        $stmt = $db->prepare("
            SELECT ca.*,
                   (SELECT COUNT(*) FROM current_affairs_quizzes WHERE article_id=ca.id) as quiz_question_count
            FROM current_affairs ca
            WHERE $whereStr
            ORDER BY ca.publish_date DESC, ca.id DESC
            LIMIT $limit OFFSET $offset
        ");
        $stmt->execute($params);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Get distinct categories and latest dates
        $categories = $db->query("SELECT DISTINCT category FROM current_affairs WHERE is_published=1 ORDER BY category ASC")->fetchAll(PDO::FETCH_COLUMN);
        $dates = $db->query("SELECT DISTINCT publish_date FROM current_affairs WHERE is_published=1 ORDER BY publish_date DESC LIMIT 7")->fetchAll(PDO::FETCH_COLUMN);

        Response::json([
            'articles' => $items,
            'categories' => $categories,
            'recent_dates' => $dates,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => ceil($total / $limit)
            ]
        ], 'Current affairs loaded');
    }

    // ─── ARTICLE DETAIL VIEW ──────────────────────────────────────────

    public static function getCurrentAffairsDetail($id) {
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM current_affairs WHERE id=? AND is_published=1");
        $stmt->execute([$id]);
        $article = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$article) {
            Response::json(null, 'Article not found', 'error', 404);
            return;
        }

        // Fetch associated quiz questions
        $quizStmt = $db->prepare("SELECT * FROM current_affairs_quizzes WHERE article_id=? ORDER BY id ASC");
        $quizStmt->execute([$id]);
        $article['quizzes'] = $quizStmt->fetchAll(PDO::FETCH_ASSOC);

        // Related articles
        $relStmt = $db->prepare("SELECT id, title, category, publish_date, image_url, read_time_minutes FROM current_affairs WHERE category=? AND id != ? AND is_published=1 ORDER BY publish_date DESC LIMIT 3");
        $relStmt->execute([$article['category'], $id]);
        $article['related_articles'] = $relStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json($article, 'Article details loaded');
    }

    // ─── AI QUIZ GENERATION BASED ON ARTICLE CONTENT ──────────────────

    public static function generateArticleQuiz($id) {
        // This endpoint calls a paid AI provider. Left open, anyone could loop
        // it with ?force=1 and burn the operator's API credits.
        $caller = AuthMiddleware::requireUserOrAdminSession();

        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM current_affairs WHERE id=?");
        $stmt->execute([$id]);
        $article = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$article) {
            Response::json(null, 'Article not found', 'error', 404);
            return;
        }

        // Only staff may bypass the cache and force a fresh (billable) generation.
        $forceNew = $caller['is_admin'] && isset($_GET['force']) && $_GET['force'] === '1';

        if ($forceNew) {
            RateLimit::enforce('quiz_force', $caller['user_id'] ?? 'admin-session', 30, 3600);
        }

        // Check if cached questions exist and forceNew is false
        if (!$forceNew) {
            $existing = $db->prepare("SELECT * FROM current_affairs_quizzes WHERE article_id=? ORDER BY id ASC");
            $existing->execute([$id]);
            $cached = $existing->fetchAll(PDO::FETCH_ASSOC);
            if (!empty($cached)) {
                Response::json([
                    'article_id' => $id,
                    'article_title' => $article['title'],
                    'questions' => $cached,
                    'is_cached' => true
                ], 'Quiz loaded from cache');
                return;
            }
        }

        // Fetch active AI key
        $keyRow = $db->query("SELECT * FROM ai_api_keys WHERE is_active=1 LIMIT 1")->fetch(PDO::FETCH_ASSOC);
        if (!$keyRow) {
            Response::json(null, 'No active AI key found. Please add or activate one in Admin Panel.', 'error', 500);
            return;
        }

        // Generation is billable, so cap how often any one caller can trigger it.
        RateLimit::enforce('quiz_generate', $caller['user_id'] ?? 'admin-session', 20, 3600);

        $apiKey   = Crypto::decrypt($keyRow['api_key_encrypted']);
        $provider = $keyRow['provider'];

        $articleText = "TITLE: " . $article['title'] . "\n\n"
                     . "SUMMARY: " . ($article['summary'] ?? '') . "\n\n"
                     . "CONTENT:\n" . $article['content_body'];

        $prompt = "You are a senior question setter for Indian competitive exams (UPSC CSE, SSC CGL, Banking, State PSCs).
Generate exactly 4 high-yield, conceptual multiple-choice questions based STRICTLY on the following current affairs article:

------------------------
{$articleText}
------------------------

RULES:
1. Every question must be directly answerable from the facts, data, organizations, policies, or concepts mentioned in the article.
2. Formulate 4 distinct options (A, B, C, D) for each question.
3. Mark exactly one correct option.
4. Provide an accurate 2-3 sentence explanation citing the fact from the article.
5. Format your entire output as a valid JSON array ONLY (no extra markdown outside the array):

[
  {
    \"question_text\": \"Question sentence here?\",
    \"option_a\": \"First option\",
    \"option_b\": \"Second option\",
    \"option_c\": \"Third option\",
    \"option_d\": \"Fourth option\",
    \"correct_option\": \"A\",
    \"explanation\": \"Explanation referencing the fact.\",
    \"difficulty\": \"medium\"
  }
]

Generate 4 questions now:";

        try {
            $rawResponse = ($provider === 'gemini')
                ? self::callGemini($apiKey, $prompt)
                : self::callOpenAI($apiKey, $prompt);

            $clean = trim($rawResponse);
            $clean = preg_replace('/^```(?:json)?\s*/i', '', $clean);
            $clean = preg_replace('/\s*```\s*$/i', '', $clean);

            $parsed = json_decode($clean, true);
            if (!is_array($parsed) || empty($parsed)) {
                throw new Exception('AI returned invalid JSON: ' . substr($rawResponse, 0, 300));
            }

            // Clear old if forceNew
            if ($forceNew) {
                $db->prepare("DELETE FROM current_affairs_quizzes WHERE article_id=?")->execute([$id]);
            }

            $savedQuestions = [];
            foreach ($parsed as $q) {
                if (empty($q['question_text'])) continue;
                $correct = strtoupper(trim($q['correct_option'] ?? 'A'));
                if (!in_array($correct, ['A','B','C','D'])) $correct = 'A';

                $ins = $db->prepare("INSERT INTO current_affairs_quizzes (article_id, question_text, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty) VALUES (?,?,?,?,?,?,?,?,?)");
                $ins->execute([
                    $id,
                    $q['question_text'],
                    $q['option_a'] ?? '',
                    $q['option_b'] ?? '',
                    $q['option_c'] ?? '',
                    $q['option_d'] ?? '',
                    $correct,
                    $q['explanation'] ?? '',
                    $q['difficulty'] ?? 'medium'
                ]);
                $q['id'] = $db->lastInsertId();
                $q['article_id'] = $id;
                $savedQuestions[] = $q;
            }

            $db->prepare("UPDATE ai_api_keys SET usage_count=usage_count+1, last_used_at=NOW() WHERE id=?")->execute([$keyRow['id']]);

            Response::json([
                'article_id' => $id,
                'article_title' => $article['title'],
                'questions' => $savedQuestions,
                'count' => count($savedQuestions),
                'is_cached' => false
            ], count($savedQuestions) . ' AI quiz questions generated successfully!');

        } catch (Exception $e) {
            Response::json(null, 'AI Quiz Generation failed: ' . $e->getMessage(), 'error', 500);
        }
    }

    // ─── GET QUIZ QUESTIONS ───────────────────────────────────────────

    public static function getArticleQuiz($id) {
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM current_affairs_quizzes WHERE article_id=? ORDER BY id ASC");
        $stmt->execute([$id]);
        $quizzes = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json($quizzes, 'Quiz questions loaded');
    }

    // ─── JOBS, TOPPERS & PASSPORT ─────────────────────────────────────

    public static function getJobs() {
        $db = Database::getConnection();
        $jobs = $db->query("SELECT * FROM jobs ORDER BY id DESC")->fetchAll();
        Response::json($jobs, 'Job notifications loaded');
    }

    public static function getTopperWall() {
        $db = Database::getConnection();
        $toppers = $db->query("SELECT * FROM topper_stories WHERE is_verified = 1 ORDER BY id DESC")->fetchAll();
        Response::json($toppers, 'Topper and Success wall loaded');
    }

    public static function getPreparationPassport() {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();

        // Best evaluated attempt per exam, in one pass instead of a query per exam.
        $stmt = $db->prepare("
            SELECT e.id   AS exam_id,
                   e.title AS exam_title,
                   best.score, best.accuracy_percentage, best.central_rank,
                   best.state_rank, best.percentile, best.submitted_at
            FROM exams e
            LEFT JOIN (
                SELECT t.exam_id,
                       att.score, att.accuracy_percentage, att.central_rank,
                       att.state_rank, att.percentile, att.submitted_at,
                       ROW_NUMBER() OVER (PARTITION BY t.exam_id ORDER BY att.score DESC, att.submitted_at DESC) AS rn
                FROM test_attempts att
                JOIN tests t ON att.test_id = t.id
                WHERE att.user_id = :uid AND att.status = 'evaluated'
            ) best ON best.exam_id = e.id AND best.rn = 1
            WHERE e.status = 'active'
            ORDER BY e.id ASC
        ");
        $stmt->execute(['uid' => $userId]);

        $passportEntries = [];
        foreach ($stmt->fetchAll() as $row) {
            $hasAttempt = $row['submitted_at'] !== null;
            $passportEntries[] = [
                'exam_id'      => intval($row['exam_id']),
                'exam_title'   => $row['exam_title'],
                'best_score'   => $hasAttempt ? floatval($row['score']) : 0.00,
                'accuracy'     => $hasAttempt ? floatval($row['accuracy_percentage']) : 0.00,
                'central_rank' => $hasAttempt ? $row['central_rank'] : null,
                'state_rank'   => $hasAttempt ? $row['state_rank'] : null,
                'percentile'   => $hasAttempt ? floatval($row['percentile']) : null,
                'status'       => $hasAttempt ? 'Verified Attempt' : 'In Progress',
            ];
        }

        // Recent attempt history — the Test History screen reads this key.
        $histStmt = $db->prepare("
            SELECT att.id AS attempt_id, att.score, att.accuracy_percentage, att.central_rank,
                   att.correct_count, att.wrong_count, att.unattempted_count,
                   att.started_at, att.submitted_at,
                   t.title AS test_title, e.title AS exam_title
            FROM test_attempts att
            JOIN tests t ON att.test_id = t.id
            JOIN exams e ON t.exam_id = e.id
            WHERE att.user_id = :uid AND att.status = 'evaluated'
            ORDER BY att.submitted_at DESC
            LIMIT 25
        ");
        $histStmt->execute(['uid' => $userId]);
        $recentAttempts = $histStmt->fetchAll();

        // Aggregate XP figures used by the passport/profile screens.
        $sumStmt = $db->prepare("
            SELECT COUNT(*) AS tests_taken,
                   COALESCE(SUM(att.score), 0) AS total_score,
                   COALESCE(SUM(att.correct_count), 0) AS total_correct,
                   COALESCE(SUM(att.correct_count + att.wrong_count), 0) AS total_attempted
            FROM test_attempts att
            WHERE att.user_id = :uid AND att.status = 'evaluated'
        ");
        $sumStmt->execute(['uid' => $userId]);
        $totals = $sumStmt->fetch() ?: ['tests_taken' => 0, 'total_score' => 0, 'total_correct' => 0, 'total_attempted' => 0];

        $nameStmt = $db->prepare("SELECT full_name FROM users WHERE id = ?");
        $nameStmt->execute([$userId]);
        $holderName = $nameStmt->fetchColumn();

        Response::json([
            'passport_holder' => $holderName ?: ($authUser['extra']['name'] ?? 'Candidate'),
            'passport_id'     => 'EXAMVERSE-PASS-' . str_pad($userId, 6, '0', STR_PAD_LEFT),
            'entries'         => $passportEntries,
            'recent_attempts' => $recentAttempts,
            'summary'         => [
                'tests_taken'      => intval($totals['tests_taken']),
                'total_score'      => round(floatval($totals['total_score']), 2),
                'questions_solved' => intval($totals['total_correct']),
                'overall_accuracy' => intval($totals['total_attempted']) > 0
                    ? round((intval($totals['total_correct']) / intval($totals['total_attempted'])) * 100, 2)
                    : 0.0,
                'tests_xp'         => intval($totals['tests_taken']) * 50,
                'accuracy_xp'      => intval($totals['total_correct']) * 5,
            ],
        ], 'Preparation Passport loaded');
    }

    // ─── PRIVATE AI CALLERS ───────────────────────────────────────────

    private static function callGemini(string $apiKey, string $prompt): string {
        $cleanKey = urlencode(trim($apiKey));
        $url     = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key={$cleanKey}";
        $payload = json_encode([
            'contents'         => [['parts' => [['text' => $prompt]]]],
            'generationConfig' => ['temperature' => 0.7, 'maxOutputTokens' => 8192]
        ]);

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 90,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
            CURLOPT_SSL_VERIFYPEER => false,
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlErr  = curl_error($ch);
        curl_close($ch);

        if ($curlErr) throw new Exception("cURL error: $curlErr");
        if ($httpCode !== 200) throw new Exception("Gemini API HTTP $httpCode: " . substr($response, 0, 400));

        $decoded = json_decode($response, true);
        $text    = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
        if (empty($text)) throw new Exception('Gemini returned empty content');
        return $text;
    }

    private static function callOpenAI(string $apiKey, string $prompt): string {
        $url     = "https://api.openai.com/v1/chat/completions";
        $payload = json_encode([
            'model'       => 'gpt-4o-mini',
            'messages'    => [['role' => 'user', 'content' => $prompt]],
            'temperature' => 0.7,
            'max_tokens'  => 8192
        ]);

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 90,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json', "Authorization: Bearer {$apiKey}"],
            CURLOPT_SSL_VERIFYPEER => false,
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlErr  = curl_error($ch);
        curl_close($ch);

        if ($curlErr) throw new Exception("cURL error: $curlErr");
        if ($httpCode !== 200) throw new Exception("OpenAI API HTTP $httpCode: " . substr($response, 0, 400));

        $decoded = json_decode($response, true);
        $text    = $decoded['choices'][0]['message']['content'] ?? '';
        if (empty($text)) throw new Exception('OpenAI returned empty content');
        return $text;
    }
}
