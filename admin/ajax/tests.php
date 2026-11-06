<?php
/**
 * Admin AJAX: AI-Powered Test Management System
 * URL: /EXAMVERSE/admin/ajax/tests.php?action=...
 * Auth: PHP session + CSRF (_guard.php)
 */
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';
require_once __DIR__ . '/../../api/utils/crypto.php';

$db      = Database::getConnection();
$action  = $_GET['action'] ?? '';
$adminId = $_SESSION['admin_user']['id'] ?? 1;

switch ($action) {

    // ── TAXONOMY FOR DROPDOWNS ────────────────────────────────────────────
    case 'taxonomy':
        $exams    = $db->query("SELECT id, title FROM exams WHERE status='active' ORDER BY title ASC")->fetchAll(PDO::FETCH_ASSOC);
        $subjects = $db->query("SELECT id, name FROM subjects ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $chapters = $db->query("SELECT id, subject_id, name FROM chapters ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $topics   = $db->query("SELECT id, chapter_id, name FROM topics ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $categories = $db->query("SELECT id, name, slug FROM exam_categories WHERE status='active' ORDER BY sort_order ASC, name ASC")->fetchAll(PDO::FETCH_ASSOC);
        ajaxOk([
            'exams'      => $exams,
            'subjects'   => $subjects,
            'chapters'   => $chapters,
            'topics'     => $topics,
            'categories' => $categories,
        ], 'Taxonomy loaded');
        break;

    // ── LIST TESTS ────────────────────────────────────────────────────────
    case 'list':
        $search   = trim($_GET['search'] ?? '');
        $status   = trim($_GET['status'] ?? '');
        $subjectId = intval($_GET['subject_id'] ?? 0);
        $difficulty = trim($_GET['difficulty'] ?? '');
        $page     = max(1, intval($_GET['page'] ?? 1));
        $limit    = min(50, max(5, intval($_GET['limit'] ?? 15)));
        $offset   = ($page - 1) * $limit;

        $where  = ['1=1'];
        $params = [];

        if ($search !== '') {
            $where[] = 't.title LIKE ?';
            $params[] = '%' . $search . '%';
        }
        if ($status !== '' && in_array($status, ['draft','ready_to_publish','published','active','completed','archived'], true)) {
            $where[] = 't.status = ?';
            $params[] = $status;
        }
        if ($subjectId > 0) {
            $where[] = 't.subject_id = ?';
            $params[] = $subjectId;
        }
        if ($difficulty !== '' && in_array($difficulty, ['easy','medium','hard'], true)) {
            $where[] = 't.difficulty = ?';
            $params[] = $difficulty;
        }

        $whereSQL = implode(' AND ', $where);

        $countStmt = $db->prepare("SELECT COUNT(*) FROM tests t WHERE $whereSQL");
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $stmt = $db->prepare("
            SELECT t.*,
                   e.title AS exam_title,
                   ep.name AS pattern_name,
                   s.name  AS subject_name,
                   COALESCE(t.total_questions, ep.total_questions, 0)  AS q_count,
                   COALESCE(t.total_marks, ep.total_marks, 0.00)        AS marks,
                   COALESCE(t.duration_minutes, CEIL(ep.total_duration_seconds/60), 60) AS duration_mins,
                   (SELECT COUNT(*) FROM test_questions tq WHERE tq.test_id = t.id) AS actual_q_count,
                   (SELECT COUNT(*) FROM test_attempts ta WHERE ta.test_id = t.id) AS attempt_count,
                   a.name  AS creator_name
            FROM tests t
            LEFT JOIN exams e           ON t.exam_id = e.id
            LEFT JOIN exam_patterns ep  ON t.pattern_id = ep.id
            LEFT JOIN subjects s        ON t.subject_id = s.id
            LEFT JOIN admins a          ON t.created_by_admin_id = a.id
            WHERE $whereSQL
            ORDER BY t.id DESC
            LIMIT $limit OFFSET $offset
        ");
        $stmt->execute($params);
        $tests = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Status stats
        $statsStmt = $db->query("SELECT status, COUNT(*) AS cnt FROM tests GROUP BY status");
        $statsRaw  = $statsStmt->fetchAll(PDO::FETCH_ASSOC);
        $stats = ['total' => 0, 'draft' => 0, 'ready_to_publish' => 0, 'published' => 0, 'active' => 0, 'completed' => 0, 'archived' => 0];
        foreach ($statsRaw as $r) {
            $stats[$r['status']] = (int)$r['cnt'];
            $stats['total'] += (int)$r['cnt'];
        }

        ajaxOk([
            'tests'      => $tests,
            'total'      => $total,
            'page'       => $page,
            'limit'      => $limit,
            'pages'      => ceil($total / $limit),
            'stats'      => $stats,
        ], 'Tests loaded');
        break;

    // ── GET SINGLE TEST ───────────────────────────────────────────────────
    case 'get_test':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('Test ID required', 400);

        $stmt = $db->prepare("
            SELECT t.*, e.title AS exam_title, s.name AS subject_name
            FROM tests t
            LEFT JOIN exams e    ON t.exam_id = e.id
            LEFT JOIN subjects s ON t.subject_id = s.id
            WHERE t.id = ?
        ");
        $stmt->execute([$id]);
        $test = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$test) ajaxErr('Test not found', 404);

        ajaxOk($test, 'Test fetched');
        break;

    // ── GET TEST QUESTIONS ────────────────────────────────────────────────
    case 'test_questions':
        $testId = intval($_GET['test_id'] ?? 0);
        if (!$testId) ajaxErr('test_id required', 400);

        $stmt = $db->prepare("
            SELECT tq.id AS tq_id, tq.question_order, tq.marks AS tq_marks, tq.negative_marks AS tq_neg,
                   q.id, q.question_text, q.question_type, q.option_a, q.option_b, q.option_c, q.option_d,
                   q.correct_option, q.explanation, q.difficulty, q.marks AS q_marks,
                   q.negative_marks AS q_neg, q.image_url
            FROM test_questions tq
            JOIN questions q ON tq.question_id = q.id
            WHERE tq.test_id = ?
            ORDER BY tq.question_order ASC
        ");
        $stmt->execute([$testId]);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

        ajaxOk(['questions' => $questions, 'count' => count($questions)], 'Questions fetched');
        break;

    // ── SAVE / UPDATE TEST ────────────────────────────────────────────────
    case 'save_test':
        $body    = getBody();
        $testId  = intval($body['id'] ?? 0);
        $title   = trim($body['title'] ?? '');
        if (empty($title)) ajaxErr('Test title is required');

        $fields = [
            'title'           => $title,
            'description'     => trim($body['description'] ?? ''),
            'exam_id'         => ($body['exam_id'] ?? null) ? (int)$body['exam_id'] : null,
            'subject_id'      => ($body['subject_id'] ?? null) ? (int)$body['subject_id'] : null,
            'chapter_id'      => ($body['chapter_id'] ?? null) ? (int)$body['chapter_id'] : null,
            'topic_id'        => ($body['topic_id'] ?? null) ? (int)$body['topic_id'] : null,
            'course_class'    => trim($body['course_class'] ?? ''),
            'test_category'   => trim($body['test_category'] ?? ''),
            'difficulty'      => in_array($body['difficulty'] ?? 'medium', ['easy','medium','hard']) ? $body['difficulty'] : 'medium',
            'total_questions' => max(0, (int)($body['total_questions'] ?? 0)),
            'total_marks'     => max(0, (float)($body['total_marks'] ?? 0)),
            'duration_minutes'=> max(1, (int)($body['duration_minutes'] ?? 60)),
            'negative_marking'=> max(0, (float)($body['negative_marking'] ?? 0)),
            'passing_marks'   => max(0, (float)($body['passing_marks'] ?? 0)),
            'start_time'      => !empty($body['start_time']) ? $body['start_time'] : null,
            'end_time'        => !empty($body['end_time']) ? $body['end_time'] : null,
            'instructions'    => trim($body['instructions'] ?? ''),
            'test_type'       => in_array($body['test_type'] ?? 'free', ['free','paid']) ? $body['test_type'] : 'free',
            'is_paid'         => !empty($body['is_paid']) ? 1 : 0,
            'price'           => max(0, (float)($body['price'] ?? 0)),
        ];

        if ($testId > 0) {
            // UPDATE
            $stmt = $db->prepare("SELECT id FROM tests WHERE id=?");
            $stmt->execute([$testId]);
            if (!$stmt->fetch()) ajaxErr('Test not found', 404);

            $sets = implode(', ', array_map(fn($k) => "`$k`=?", array_keys($fields)));
            $vals = array_values($fields);
            $vals[] = $testId;
            $db->prepare("UPDATE tests SET $sets, updated_at=NOW() WHERE id=?")->execute($vals);

            auditLog($db, $adminId, 'UPDATE_TEST', $testId, "Updated test: $title");
            ajaxOk(['id' => $testId], 'Test updated');
        } else {
            // INSERT
            $fields['status']             = 'draft';
            $fields['created_by_admin_id'] = $adminId;
            $fields['results_published']  = 0;

            $cols = implode(', ', array_map(fn($k) => "`$k`", array_keys($fields)));
            $phs  = implode(', ', array_fill(0, count($fields), '?'));
            $db->prepare("INSERT INTO tests ($cols, created_at, updated_at) VALUES ($phs, NOW(), NOW())")->execute(array_values($fields));
            $newId = (int)$db->lastInsertId();

            auditLog($db, $adminId, 'CREATE_TEST', $newId, "Created test: $title");
            ajaxOk(['id' => $newId], 'Test created as draft');
        }
        break;

    // ── AI GENERATE QUESTIONS ─────────────────────────────────────────────
    case 'ai_generate':
        $body      = getBody();
        $testId    = intval($body['test_id'] ?? 0);
        $subjectId = intval($body['subject_id'] ?? 0);
        $topic     = trim($body['topic'] ?? '');
        $count     = min(15, max(1, intval($body['count'] ?? 5)));
        $difficulty = in_array($body['difficulty'] ?? 'medium', ['easy','medium','hard']) ? $body['difficulty'] : 'medium';
        $qType     = $body['question_type'] ?? 'MCQ';
        $language  = $body['language'] ?? 'en';

        // Get active AI key
        $keyRow = $db->query("SELECT * FROM ai_api_keys WHERE is_active=1 ORDER BY created_at DESC LIMIT 1")->fetch(PDO::FETCH_ASSOC);

        // Get subject/topic names for prompt
        $subjectName = 'General';
        $examName    = 'Competitive Exam';
        if ($subjectId) {
            $r = $db->prepare("SELECT name FROM subjects WHERE id=?");
            $r->execute([$subjectId]);
            $row = $r->fetch(PDO::FETCH_ASSOC);
            if ($row) $subjectName = $row['name'];
        }
        if ($testId) {
            $r2 = $db->prepare("SELECT t.title, e.title as etitle FROM tests t LEFT JOIN exams e ON t.exam_id=e.id WHERE t.id=?");
            $r2->execute([$testId]);
            $trow = $r2->fetch(PDO::FETCH_ASSOC);
            if ($trow) $examName = $trow['etitle'] ?? $trow['title'];
        }

        $langLabel  = $language === 'hi' ? 'Hindi' : 'English';
        $topicLine  = $topic ? " on the topic: $topic" : '';
        $qTypeLabel = ($qType === 'TRUE_FALSE') ? 'True/False questions (only 2 options: True and False)' : 'Multiple Choice Questions (MCQs) with 4 options (A,B,C,D)';

        $prompt = "You are an expert question setter for Indian competitive exams.
Generate exactly {$count} {$qTypeLabel} for:
- Exam: {$examName}
- Subject: {$subjectName}{$topicLine}
- Difficulty: {$difficulty}
- Language: {$langLabel}

CRITICAL: Respond ONLY with a valid JSON array. No markdown, no code fences, no explanation text before or after.
Each element must have exactly these fields:
- question_text: string
- option_a: string
- option_b: string
- option_c: string (use empty string for True/False type)
- option_d: string (use empty string for True/False type)
- correct_option: \"A\", \"B\", \"C\", or \"D\"
- explanation: string (2-3 sentences)
- difficulty: \"{$difficulty}\"
- marks: 1

Generate {$count} questions now:";

        $generatedQuestions = [];
        $fallback = false;

        if ($keyRow) {
            try {
                $apiKey  = Crypto::decrypt($keyRow['api_key_encrypted']);
                $provider = $keyRow['provider'];

                if ($provider === 'gemini') {
                    $url     = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=' . $apiKey;
                    $payload = json_encode(['contents' => [['parts' => [['text' => $prompt]]]]]);
                    $ch = curl_init($url);
                    curl_setopt_array($ch, [
                        CURLOPT_POST => 1, CURLOPT_POSTFIELDS => $payload,
                        CURLOPT_RETURNTRANSFER => 1, CURLOPT_TIMEOUT => 45,
                        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                    ]);
                    $resp = curl_exec($ch);
                    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                    curl_close($ch);

                    if ($httpCode === 200) {
                        $decoded = json_decode($resp, true);
                        $text = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
                        $text = preg_replace('/^```json\s*/i', '', trim($text));
                        $text = preg_replace('/\s*```$/i', '', $text);
                        $parsed = json_decode($text, true);
                        if (is_array($parsed)) $generatedQuestions = $parsed;
                    }
                } elseif ($provider === 'openai') {
                    $url     = 'https://api.openai.com/v1/chat/completions';
                    $payload = json_encode(['model' => 'gpt-4o-mini', 'messages' => [['role' => 'user', 'content' => $prompt]], 'temperature' => 0.7]);
                    $ch = curl_init($url);
                    curl_setopt_array($ch, [
                        CURLOPT_POST => 1, CURLOPT_POSTFIELDS => $payload,
                        CURLOPT_RETURNTRANSFER => 1, CURLOPT_TIMEOUT => 45,
                        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Authorization: Bearer ' . $apiKey],
                    ]);
                    $resp = curl_exec($ch);
                    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                    curl_close($ch);

                    if ($httpCode === 200) {
                        $decoded = json_decode($resp, true);
                        $text = $decoded['choices'][0]['message']['content'] ?? '';
                        $text = preg_replace('/^```json\s*/i', '', trim($text));
                        $text = preg_replace('/\s*```$/i', '', $text);
                        $parsed = json_decode($text, true);
                        if (is_array($parsed)) $generatedQuestions = $parsed;
                    }
                }
            } catch (Exception $e) {
                error_log('AI Generate error: ' . $e->getMessage());
                $fallback = true;
            }
        } else {
            $fallback = true;
        }

        // Fallback: generate sample questions if no AI key
        if ($fallback || empty($generatedQuestions)) {
            $sampleTopics = [
                ['q' => "Which is the capital of India?", 'a' => "Mumbai", 'b' => "New Delhi", 'c' => "Kolkata", 'd' => "Chennai", 'correct' => 'B', 'exp' => "New Delhi is the capital of India."],
                ['q' => "Who is the author of the Indian Constitution?", 'a' => "Mahatma Gandhi", 'b' => "Jawaharlal Nehru", 'c' => "B.R. Ambedkar", 'd' => "Sardar Patel", 'correct' => 'C', 'exp' => "Dr. B.R. Ambedkar was the chief architect of the Indian Constitution."],
                ['q' => "Which river is the longest in India?", 'a' => "Yamuna", 'b' => "Ganga", 'c' => "Godavari", 'd' => "Brahmaputra", 'correct' => 'B', 'exp' => "The Ganga is the longest river in India."],
                ['q' => "India got Independence in which year?", 'a' => "1945", 'b' => "1947", 'c' => "1950", 'd' => "1948", 'correct' => 'B', 'exp' => "India got independence from British rule on 15 August 1947."],
                ['q' => "What is the full form of GST?", 'a' => "General Sales Tax", 'b' => "Goods and Services Tax", 'c' => "Government Supply Tax", 'd' => "Gross State Tax", 'correct' => 'B', 'exp' => "GST stands for Goods and Services Tax, a comprehensive indirect tax levied on supply of goods and services."],
                ['q' => "Which planet is closest to the Sun?", 'a' => "Venus", 'b' => "Earth", 'c' => "Mercury", 'd' => "Mars", 'correct' => 'C', 'exp' => "Mercury is the closest planet to the Sun in our solar system."],
                ['q' => "The speed of light is approximately?", 'a' => "3 × 10⁶ m/s", 'b' => "3 × 10⁸ m/s", 'c' => "3 × 10¹⁰ m/s", 'd' => "3 × 10⁴ m/s", 'correct' => 'B', 'exp' => "The speed of light in vacuum is approximately 3 × 10⁸ metres per second."],
                ['q' => "Which of the following is a prime number?", 'a' => "9", 'b' => "15", 'c' => "17", 'd' => "21", 'correct' => 'C', 'exp' => "17 is a prime number as it has no divisors other than 1 and itself."],
            ];
            for ($i = 0; $i < $count; $i++) {
                $t = $sampleTopics[$i % count($sampleTopics)];
                $generatedQuestions[] = [
                    'question_text' => $t['q'] . " (Sample — configure AI key for real AI generation)",
                    'option_a'      => $t['a'],
                    'option_b'      => $t['b'],
                    'option_c'      => $t['c'],
                    'option_d'      => $t['d'],
                    'correct_option'=> $t['correct'],
                    'explanation'   => $t['exp'],
                    'difficulty'    => $difficulty,
                    'marks'         => 1,
                ];
            }
        }

        // Add temp IDs for frontend tracking
        foreach ($generatedQuestions as $i => &$q) {
            $q['temp_id']       = 'ai_' . uniqid() . '_' . $i;
            $q['marks']         = (float)($q['marks'] ?? 1);
            $q['question_type'] = $qType;
            $q['is_fallback']   = $fallback;
        }
        unset($q);

        ajaxOk([
            'questions' => $generatedQuestions,
            'count'     => count($generatedQuestions),
            'is_fallback' => $fallback,
        ], $fallback ? 'Sample questions generated (configure AI key for real AI generation)' : 'AI questions generated successfully');
        break;

    // ── ADD AI/MANUAL QUESTIONS TO TEST ──────────────────────────────────
    case 'add_questions':
        $body      = getBody();
        $testId    = intval($body['test_id'] ?? 0);
        $questions = $body['questions'] ?? [];

        if (!$testId) ajaxErr('test_id required');
        if (empty($questions)) ajaxErr('No questions provided');

        // Get current max order
        $maxOrder = (int)$db->prepare("SELECT COALESCE(MAX(question_order),0) FROM test_questions WHERE test_id=?")->execute([$testId]) && true
            ? $db->query("SELECT COALESCE(MAX(question_order),0) FROM test_questions WHERE test_id=$testId")->fetchColumn()
            : 0;

        $added = 0;
        $db->beginTransaction();
        try {
            foreach ($questions as $q) {
                $text = trim($q['question_text'] ?? '');
                if (empty($text)) continue;

                $correct = strtoupper(trim($q['correct_option'] ?? 'A'));
                if (!in_array($correct, ['A','B','C','D'])) $correct = 'A';

                $qType = in_array($q['question_type'] ?? 'MCQ', ['MCQ','TRUE_FALSE','DESCRIPTIVE','NUMERICAL']) ? $q['question_type'] : 'MCQ';

                // Insert into questions table
                $qStmt = $db->prepare("
                    INSERT INTO questions (question_text, question_type, option_a, option_b, option_c, option_d,
                        correct_option, explanation, difficulty, marks, negative_marks, subject_id,
                        source, status, created_by, created_at, updated_at)
                    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'admin','published',?,NOW(),NOW())
                ");
                $qStmt->execute([
                    $text,
                    $qType,
                    trim($q['option_a'] ?? ''),
                    trim($q['option_b'] ?? ''),
                    trim($q['option_c'] ?? ''),
                    trim($q['option_d'] ?? ''),
                    $correct,
                    trim($q['explanation'] ?? ''),
                    in_array($q['difficulty'] ?? 'medium', ['easy','medium','hard']) ? $q['difficulty'] : 'medium',
                    max(0, (float)($q['marks'] ?? 1)),
                    max(0, (float)($q['negative_marks'] ?? 0)),
                    ($q['subject_id'] ?? null) ? (int)$q['subject_id'] : null,
                    $adminId,
                ]);
                $qId = (int)$db->lastInsertId();

                $maxOrder++;
                $db->prepare("
                    INSERT INTO test_questions (test_id, question_id, question_order, marks, negative_marks)
                    VALUES (?,?,?,?,?)
                ")->execute([
                    $testId, $qId, $maxOrder,
                    max(0, (float)($q['marks'] ?? 1)),
                    max(0, (float)($q['negative_marks'] ?? 0)),
                ]);

                $added++;
            }

            // Update total_questions on tests
            $db->prepare("UPDATE tests SET total_questions=(SELECT COUNT(*) FROM test_questions WHERE test_id=?), updated_at=NOW() WHERE id=?")->execute([$testId, $testId]);
            $db->commit();
        } catch (Exception $e) {
            $db->rollBack();
            ajaxErr('DB error: ' . $e->getMessage(), 500);
        }

        auditLog($db, $adminId, 'ADD_QUESTIONS', $testId, "Added $added questions to test #$testId");
        ajaxOk(['added' => $added], "$added questions added to test");
        break;

    // ── ADD SINGLE MANUAL QUESTION ────────────────────────────────────────
    case 'add_manual_question':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        if (!$testId) ajaxErr('test_id required');

        $text = trim($body['question_text'] ?? '');
        if (empty($text)) ajaxErr('question_text required');

        $correct = strtoupper(trim($body['correct_option'] ?? 'A'));
        if (!in_array($correct, ['A','B','C','D'])) $correct = 'A';
        $qType = in_array($body['question_type'] ?? 'MCQ', ['MCQ','TRUE_FALSE','DESCRIPTIVE','NUMERICAL']) ? $body['question_type'] : 'MCQ';

        $db->beginTransaction();
        try {
            $db->prepare("
                INSERT INTO questions (question_text, question_type, option_a, option_b, option_c, option_d,
                    correct_option, explanation, difficulty, marks, negative_marks, subject_id,
                    source, status, created_by, created_at, updated_at)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'admin','published',?,NOW(),NOW())
            ")->execute([
                $text, $qType,
                trim($body['option_a'] ?? ''),
                trim($body['option_b'] ?? ''),
                trim($body['option_c'] ?? ''),
                trim($body['option_d'] ?? ''),
                $correct,
                trim($body['explanation'] ?? ''),
                in_array($body['difficulty'] ?? 'medium', ['easy','medium','hard']) ? $body['difficulty'] : 'medium',
                max(0, (float)($body['marks'] ?? 1)),
                max(0, (float)($body['negative_marks'] ?? 0)),
                ($body['subject_id'] ?? null) ? (int)$body['subject_id'] : null,
                $adminId,
            ]);
            $qId = (int)$db->lastInsertId();

            $maxOrder = (int)$db->query("SELECT COALESCE(MAX(question_order),0) FROM test_questions WHERE test_id=$testId")->fetchColumn() + 1;
            $db->prepare("INSERT INTO test_questions (test_id, question_id, question_order, marks, negative_marks) VALUES (?,?,?,?,?)")
               ->execute([$testId, $qId, $maxOrder, max(0, (float)($body['marks'] ?? 1)), max(0, (float)($body['negative_marks'] ?? 0))]);

            $db->prepare("UPDATE tests SET total_questions=(SELECT COUNT(*) FROM test_questions WHERE test_id=?), updated_at=NOW() WHERE id=?")->execute([$testId, $testId]);
            $db->commit();
        } catch (Exception $e) {
            $db->rollBack();
            ajaxErr('DB error: ' . $e->getMessage(), 500);
        }

        ajaxOk(['question_id' => $qId], 'Question added to test');
        break;

    // ── UPDATE QUESTION IN TEST ───────────────────────────────────────────
    case 'update_question':
        $body = getBody();
        $qId  = intval($body['question_id'] ?? 0);
        if (!$qId) ajaxErr('question_id required');

        $text = trim($body['question_text'] ?? '');
        if (empty($text)) ajaxErr('question_text required');

        $correct = strtoupper(trim($body['correct_option'] ?? 'A'));
        if (!in_array($correct, ['A','B','C','D'])) $correct = 'A';

        $db->prepare("
            UPDATE questions SET question_text=?, option_a=?, option_b=?, option_c=?, option_d=?,
                correct_option=?, explanation=?, difficulty=?, marks=?, negative_marks=?, updated_at=NOW()
            WHERE id=?
        ")->execute([
            $text,
            trim($body['option_a'] ?? ''),
            trim($body['option_b'] ?? ''),
            trim($body['option_c'] ?? ''),
            trim($body['option_d'] ?? ''),
            $correct,
            trim($body['explanation'] ?? ''),
            in_array($body['difficulty'] ?? 'medium', ['easy','medium','hard']) ? $body['difficulty'] : 'medium',
            max(0, (float)($body['marks'] ?? 1)),
            max(0, (float)($body['negative_marks'] ?? 0)),
            $qId,
        ]);

        // Update marks in test_questions if test_id provided
        if (!empty($body['test_id'])) {
            $db->prepare("UPDATE test_questions SET marks=?, negative_marks=? WHERE test_id=? AND question_id=?")
               ->execute([max(0, (float)($body['marks'] ?? 1)), max(0, (float)($body['negative_marks'] ?? 0)), (int)$body['test_id'], $qId]);
        }

        ajaxOk(null, 'Question updated');
        break;

    // ── DELETE QUESTION FROM TEST ─────────────────────────────────────────
    case 'delete_question':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        $qId    = intval($body['question_id'] ?? 0);
        if (!$testId || !$qId) ajaxErr('test_id and question_id required');

        $db->prepare("DELETE FROM test_questions WHERE test_id=? AND question_id=?")->execute([$testId, $qId]);
        // Re-index order
        $rows = $db->query("SELECT id FROM test_questions WHERE test_id=$testId ORDER BY question_order ASC")->fetchAll(PDO::FETCH_COLUMN);
        foreach ($rows as $i => $rowId) {
            $db->prepare("UPDATE test_questions SET question_order=? WHERE id=?")->execute([$i + 1, $rowId]);
        }
        $db->prepare("UPDATE tests SET total_questions=(SELECT COUNT(*) FROM test_questions WHERE test_id=?), updated_at=NOW() WHERE id=?")->execute([$testId, $testId]);

        ajaxOk(null, 'Question removed from test');
        break;

    // ── DUPLICATE QUESTION IN TEST ────────────────────────────────────────
    case 'duplicate_question':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        $qId    = intval($body['question_id'] ?? 0);
        if (!$testId || !$qId) ajaxErr('test_id and question_id required');

        $q = $db->prepare("SELECT * FROM questions WHERE id=?");
        $q->execute([$qId]);
        $orig = $q->fetch(PDO::FETCH_ASSOC);
        if (!$orig) ajaxErr('Question not found');

        $db->prepare("
            INSERT INTO questions (question_text, question_type, option_a, option_b, option_c, option_d,
                correct_option, explanation, difficulty, marks, negative_marks, subject_id, source, status, created_by, created_at, updated_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'admin','published',?,NOW(),NOW())
        ")->execute([
            '[Copy] ' . $orig['question_text'],
            $orig['question_type'], $orig['option_a'], $orig['option_b'], $orig['option_c'], $orig['option_d'],
            $orig['correct_option'], $orig['explanation'], $orig['difficulty'],
            $orig['marks'], $orig['negative_marks'], $orig['subject_id'], $adminId,
        ]);
        $newQId = (int)$db->lastInsertId();

        $maxOrder = (int)$db->query("SELECT COALESCE(MAX(question_order),0) FROM test_questions WHERE test_id=$testId")->fetchColumn() + 1;
        $tqOrig   = $db->prepare("SELECT marks, negative_marks FROM test_questions WHERE test_id=? AND question_id=?");
        $tqOrig->execute([$testId, $qId]);
        $tqRow = $tqOrig->fetch(PDO::FETCH_ASSOC) ?? ['marks' => 1, 'negative_marks' => 0];
        $db->prepare("INSERT INTO test_questions (test_id, question_id, question_order, marks, negative_marks) VALUES (?,?,?,?,?)")
           ->execute([$testId, $newQId, $maxOrder, $tqRow['marks'], $tqRow['negative_marks']]);

        $db->prepare("UPDATE tests SET total_questions=(SELECT COUNT(*) FROM test_questions WHERE test_id=?), updated_at=NOW() WHERE id=?")->execute([$testId, $testId]);

        ajaxOk(['new_question_id' => $newQId], 'Question duplicated');
        break;

    // ── REORDER QUESTIONS ─────────────────────────────────────────────────
    case 'reorder_questions':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        $order  = $body['order'] ?? []; // array of question_ids in new order
        if (!$testId || empty($order)) ajaxErr('test_id and order[] required');

        foreach ($order as $i => $qId) {
            $db->prepare("UPDATE test_questions SET question_order=? WHERE test_id=? AND question_id=?")
               ->execute([$i + 1, $testId, (int)$qId]);
        }
        ajaxOk(null, 'Questions reordered');
        break;

    // ── PUBLISH TEST ──────────────────────────────────────────────────────
    case 'publish':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        if (!$testId) ajaxErr('test_id required');

        $stmt = $db->prepare("SELECT * FROM tests WHERE id=?");
        $stmt->execute([$testId]);
        $test = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$test) ajaxErr('Test not found', 404);

        $qCount = (int)$db->query("SELECT COUNT(*) FROM test_questions WHERE test_id=$testId")->fetchColumn();
        if ($qCount === 0) ajaxErr('Cannot publish: test has no questions. Add at least 1 question first.');

        if (!$test['title']) ajaxErr('Test title is required before publishing.');

        $db->prepare("UPDATE tests SET status='published', published_at=NOW(), updated_at=NOW() WHERE id=?")->execute([$testId]);

        // Notify all active students
        try {
            $db->prepare("
                INSERT INTO user_notifications (user_id, title, message, type)
                SELECT id, ?, ?, 'exam'
                FROM users WHERE status='active' AND role='student'
            ")->execute([
                'New Test Available: ' . $test['title'],
                'A new test "' . $test['title'] . '" is now available. Attempt it now!',
            ]);
        } catch (Exception $e) {
            // Notification table might not exist — not critical
            error_log('Test publish notification failed: ' . $e->getMessage());
        }

        auditLog($db, $adminId, 'PUBLISH_TEST', $testId, "Published test: " . $test['title']);
        ajaxOk(['status' => 'published'], 'Test published successfully! Students can now see it.');
        break;

    // ── UNPUBLISH / REVERT TO DRAFT ───────────────────────────────────────
    case 'unpublish':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        if (!$testId) ajaxErr('test_id required');

        $db->prepare("UPDATE tests SET status='draft', updated_at=NOW() WHERE id=?")->execute([$testId]);
        auditLog($db, $adminId, 'UNPUBLISH_TEST', $testId, "Unpublished test #$testId");
        ajaxOk(['status' => 'draft'], 'Test unpublished. Students can no longer see it.');
        break;

    // ── DELETE TEST ───────────────────────────────────────────────────────
    case 'delete_test':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        if (!$testId) ajaxErr('test_id required');

        $stmt = $db->prepare("SELECT title, status FROM tests WHERE id=?");
        $stmt->execute([$testId]);
        $test = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$test) ajaxErr('Test not found', 404);

        if ($test['status'] === 'published' || $test['status'] === 'active') {
            ajaxErr('Cannot delete a published/active test. Unpublish it first.');
        }

        $db->prepare("DELETE FROM test_questions WHERE test_id=?")->execute([$testId]);
        $db->prepare("DELETE FROM tests WHERE id=?")->execute([$testId]);

        auditLog($db, $adminId, 'DELETE_TEST', $testId, "Deleted test: " . $test['title']);
        ajaxOk(null, 'Test deleted');
        break;

    // ── GET ATTEMPTS / RESULTS ────────────────────────────────────────────
    case 'attempts':
        $testId = intval($_GET['test_id'] ?? 0);
        if (!$testId) ajaxErr('test_id required');

        $stmt = $db->prepare("
            SELECT ta.*, u.name AS student_name, u.email AS student_email,
                   ROUND(ta.marks_obtained / GREATEST(ta.max_marks, 1) * 100, 1) AS percentage
            FROM test_attempts ta
            JOIN users u ON ta.user_id = u.id
            WHERE ta.test_id = ? AND ta.status = 'submitted'
            ORDER BY ta.marks_obtained DESC, ta.submitted_at ASC
        ");
        $stmt->execute([$testId]);
        $attempts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $testStmt = $db->prepare("SELECT title, results_published, passing_marks FROM tests WHERE id=?");
        $testStmt->execute([$testId]);
        $testInfo = $testStmt->fetch(PDO::FETCH_ASSOC);

        ajaxOk([
            'attempts'          => $attempts,
            'count'             => count($attempts),
            'results_published' => (bool)($testInfo['results_published'] ?? false),
            'passing_marks'     => $testInfo['passing_marks'] ?? 0,
            'test_title'        => $testInfo['title'] ?? '',
        ], 'Attempts fetched');
        break;

    // ── TOGGLE RESULTS PUBLISHED ──────────────────────────────────────────
    case 'toggle_results':
        $body   = getBody();
        $testId = intval($body['test_id'] ?? 0);
        if (!$testId) ajaxErr('test_id required');

        $cur = (int)$db->query("SELECT results_published FROM tests WHERE id=$testId")->fetchColumn();
        $new = $cur ? 0 : 1;
        $db->prepare("UPDATE tests SET results_published=?, updated_at=NOW() WHERE id=?")->execute([$new, $testId]);

        ajaxOk(['results_published' => $new], $new ? 'Results are now visible to students.' : 'Results hidden from students.');
        break;

    default:
        ajaxErr("Unknown action: $action", 400);
}
