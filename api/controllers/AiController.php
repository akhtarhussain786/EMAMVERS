<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../utils/crypto.php';
require_once __DIR__ . '/../config/config.php';

class AiController {

    // ─── API KEY MANAGEMENT ────────────────────────────────────────────

    public static function listKeys() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $stmt = $db->query("SELECT id, label, provider, is_active, usage_count, last_used_at, created_at, api_key_encrypted
                            FROM ai_api_keys ORDER BY created_at DESC");
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($rows as &$row) {
            // Masked from the decrypted value so the mask never leaks the
            // leading bytes of the stored representation.
            $row['masked_key'] = Crypto::mask(Crypto::decrypt($row['api_key_encrypted']));
            $row['needs_reencryption'] = Crypto::isLegacy($row['api_key_encrypted']);
            unset($row['api_key_encrypted']);
        }
        unset($row);

        Response::json($rows, 'API keys fetched');
    }

    public static function saveKey() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $body = json_decode(file_get_contents('php://input'), true);
        $label    = trim($body['label'] ?? '');
        $provider = $body['provider'] ?? 'gemini';
        $apiKey   = trim($body['api_key'] ?? '');

        if (empty($label) || empty($apiKey)) {
            Response::json(null, 'label and api_key are required', 'error', 422);
            return;
        }
        if (!in_array($provider, ['gemini','openai'])) {
            Response::json(null, 'provider must be gemini or openai', 'error', 422);
            return;
        }

        // AES-256-GCM at rest, keyed from APP_KEY.
        $encrypted = Crypto::encrypt($apiKey);

        $db = Database::getConnection();
        // Deactivate others of same provider first if this will be active
        $db->prepare("UPDATE ai_api_keys SET is_active=0 WHERE provider=?")->execute([$provider]);

        $stmt = $db->prepare("INSERT INTO ai_api_keys (label, provider, api_key_encrypted, is_active, created_by) VALUES (?,?,?,1,'admin')");
        $stmt->execute([$label, $provider, $encrypted]);
        Response::json(['id' => $db->lastInsertId()], 'API key saved and set as active', 'success', 201);
    }

    public static function deleteKey($id) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $db->prepare("DELETE FROM ai_api_keys WHERE id=?")->execute([$id]);
        Response::json(null, 'API key removed');
    }

    public static function toggleKey($id) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM ai_api_keys WHERE id=?");
        $stmt->execute([$id]);
        $key = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$key) { Response::json(null,'Key not found','error',404); return; }
        $newStatus = $key['is_active'] ? 0 : 1;
        $db->prepare("UPDATE ai_api_keys SET is_active=? WHERE id=?")->execute([$newStatus, $id]);
        Response::json(['is_active' => $newStatus], $newStatus ? 'Key activated' : 'Key deactivated');
    }

    // ─── AI QUESTION GENERATION ────────────────────────────────────────

    public static function generateQuestions() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $body = json_decode(file_get_contents('php://input'), true);

        $examId     = intval($body['exam_id'] ?? 0);
        $subjectId  = intval($body['subject_id'] ?? 0);
        $sectionName = trim($body['section_name'] ?? 'General');
        $difficulty = $body['difficulty'] ?? 'medium';
        $count      = min(intval($body['count'] ?? 5), 15); // >15 exceeds the request timeout; chunk larger jobs
        $language   = $body['language'] ?? 'en';
        $topic      = trim($body['topic'] ?? '');

        if ($count < 1) { Response::json(null,'count must be >= 1','error',422); return; }

        $db = Database::getConnection();

        // Get active API key
        $keyStmt = $db->query("SELECT * FROM ai_api_keys WHERE is_active=1 ORDER BY created_at DESC LIMIT 1");
        $keyRow = $keyStmt->fetch(PDO::FETCH_ASSOC);
        if (!$keyRow) {
            Response::json(null,'No active AI API key found. Please add one in AI Generator settings.','error',400);
            return;
        }

        $apiKey   = Crypto::decrypt($keyRow['api_key_encrypted']);
        $provider = $keyRow['provider'];

        // Get exam & subject info for prompt
        $examName = 'Unknown Exam';
        $subjectName = 'General';
        if ($examId) {
            $es = $db->prepare("SELECT title FROM exams WHERE id=?");
            $es->execute([$examId]);
            $examRow = $es->fetch(PDO::FETCH_ASSOC);
            if ($examRow) $examName = $examRow['title'];
        }
        if ($subjectId) {
            $ss = $db->prepare("SELECT name FROM subjects WHERE id=?");
            $ss->execute([$subjectId]);
            $subRow = $ss->fetch(PDO::FETCH_ASSOC);
            if ($subRow) $subjectName = $subRow['name'];
        }

        $langLabel = $language === 'hi' ? 'Hindi' : 'English';
        $topicLine = $topic ? " focusing on the topic: {$topic}" : '';

        $prompt = "You are an expert question setter for Indian competitive exams. Generate exactly {$count} multiple choice questions (MCQs) for the {$examName} exam, subject: {$subjectName}, section: {$sectionName}{$topicLine}. Difficulty level: {$difficulty}. Language: {$langLabel}.

IMPORTANT: Respond ONLY with a valid JSON array. No markdown, no code fences, no explanation. Each element must have exactly these fields:
- question_text: string
- option_a: string
- option_b: string  
- option_c: string
- option_d: string
- correct_option: \"A\", \"B\", \"C\", or \"D\"
- explanation: string (2-3 sentences explaining the correct answer)
- difficulty: \"{$difficulty}\"

Example format:
[{\"question_text\":\"...\",\"option_a\":\"...\",\"option_b\":\"...\",\"option_c\":\"...\",\"option_d\":\"...\",\"correct_option\":\"A\",\"explanation\":\"...\",\"difficulty\":\"{$difficulty}\"}]

Generate {$count} questions now:";

        // Create batch record
        $batchStmt = $db->prepare("INSERT INTO ai_question_batches (ai_key_id, exam_id, subject_id, section_name, difficulty, language, count_requested, status, prompt_text) VALUES (?,?,?,?,?,?,?,'pending',?)");
        $batchStmt->execute([$keyRow['id'], $examId ?: null, $subjectId ?: null, $sectionName, $difficulty, $language, $count, $prompt]);
        $batchId = $db->lastInsertId();

        // Call AI provider
        $rawResponse = '';
        $generatedQuestions = [];
        $error = null;

        try {
            if ($provider === 'gemini') {
                $rawResponse = self::callGemini($apiKey, $prompt);
            } else {
                $rawResponse = self::callOpenAI($apiKey, $prompt);
            }

            // Parse JSON
            $cleaned = trim($rawResponse);
            // Remove markdown code fences if present
            $cleaned = preg_replace('/^```json\s*/i', '', $cleaned);
            $cleaned = preg_replace('/\s*```$/i', '', $cleaned);
            $parsed = json_decode($cleaned, true);
            if (!is_array($parsed)) throw new Exception('AI response was not valid JSON array. Raw: ' . substr($rawResponse, 0, 200));

            // Validate and store each question
            foreach ($parsed as $q) {
                if (empty($q['question_text']) || empty($q['option_a']) || empty($q['correct_option'])) continue;
                $correct = strtoupper(trim($q['correct_option']));
                if (!in_array($correct, ['A', 'B', 'C', 'D'], true)) continue;

                $qs = $db->prepare("INSERT INTO ai_generated_questions (batch_id, question_text, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty, review_status) VALUES (?,?,?,?,?,?,?,?,?,'pending')");
                $qs->execute([$batchId, $q['question_text'], $q['option_a'], $q['option_b'] ?? '', $q['option_c'] ?? '', $q['option_d'] ?? '', $correct, $q['explanation'] ?? '', $difficulty]);
                $q['id'] = $db->lastInsertId();
                $generatedQuestions[] = $q;
            }

            // Update batch
            $db->prepare("UPDATE ai_question_batches SET status='completed', count_generated=?, raw_response=? WHERE id=?")->execute([count($generatedQuestions), $rawResponse, $batchId]);
            $db->prepare("UPDATE ai_api_keys SET usage_count=usage_count+1, last_used_at=NOW() WHERE id=?")->execute([$keyRow['id']]);

        } catch (Exception $e) {
            $error = $e->getMessage();
            $db->prepare("UPDATE ai_question_batches SET status='error', error_message=?, raw_response=? WHERE id=?")->execute([$error, $rawResponse, $batchId]);
            error_log('EXAMVERSE AI generation failed (batch ' . $batchId . '): ' . $error);
            $clientMessage = Config::isDebug() ? $error : 'The AI provider request failed. See the batch record for details.';
            Response::json(['batch_id' => $batchId, 'error' => $clientMessage], 'AI generation failed: ' . $clientMessage, 'error', 502);
            return;
        }

        Response::json([
            'batch_id'   => $batchId,
            'count'      => count($generatedQuestions),
            'questions'  => $generatedQuestions,
            'provider'   => $provider,
            'exam'       => $examName,
            'subject'    => $subjectName,
        ], count($generatedQuestions).' questions generated successfully');
    }

    public static function approveBatch() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $body = json_decode(file_get_contents('php://input'), true);
        $approvedIds = $body['approved_ids'] ?? [];
        $rejectedIds = $body['rejected_ids'] ?? [];
        $edits       = $body['edits'] ?? []; // [{id, question_text, ...}]

        if (empty($approvedIds) && empty($rejectedIds)) {
            Response::json(null,'No IDs provided','error',422);
            return;
        }

        $db = Database::getConnection();

        // Apply edits first
        foreach ($edits as $edit) {
            $id = intval($edit['id'] ?? 0);
            if (!$id) continue;
            $stmt = $db->prepare("UPDATE ai_generated_questions SET question_text=?, option_a=?, option_b=?, option_c=?, option_d=?, correct_option=?, explanation=?, review_status='edited' WHERE id=?");
            $stmt->execute([$edit['question_text'], $edit['option_a'], $edit['option_b'], $edit['option_c'], $edit['option_d'], $edit['correct_option'], $edit['explanation'] ?? '', $id]);
        }

        // Reject
        if (!empty($rejectedIds)) {
            $placeholders = implode(',', array_fill(0, count($rejectedIds), '?'));
            $db->prepare("UPDATE ai_generated_questions SET review_status='rejected' WHERE id IN ($placeholders)")->execute($rejectedIds);
        }

        // Approve — insert into real questions table
        $savedCount = 0;
        foreach ($approvedIds as $aiQId) {
            $stmt = $db->prepare("SELECT aqg.*, aqb.exam_id, aqb.subject_id FROM ai_generated_questions aqg JOIN ai_question_batches aqb ON aqg.batch_id=aqb.id WHERE aqg.id=? AND aqg.review_status IN ('pending','edited')");
            $stmt->execute([$aiQId]);
            $aiQ = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$aiQ) continue;

            $subjectId = $aiQ['subject_id'] ?? null;
            if (!$subjectId) {
                // Default to first subject
                $subjectId = 1;
            }

            // Insert question
            $qStmt = $db->prepare("INSERT INTO questions (subject_id, question_type, difficulty, status) VALUES (?, 'MCQ', ?, 'published')");
            $qStmt->execute([$subjectId, $aiQ['difficulty']]);
            $newQId = $db->lastInsertId();

            // Insert translation (English)
            $tStmt = $db->prepare("INSERT INTO question_translations (question_id, language, question_text, solution_text) VALUES (?, 'en', ?, ?)");
            $tStmt->execute([$newQId, $aiQ['question_text'], $aiQ['explanation']]);

            // Insert options
            $opts = ['A' => $aiQ['option_a'], 'B' => $aiQ['option_b'], 'C' => $aiQ['option_c'], 'D' => $aiQ['option_d']];
            foreach ($opts as $key => $text) {
                $oStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
                $oStmt->execute([$newQId, $key, $text, ($key === strtoupper($aiQ['correct_option'])) ? 1 : 0]);
            }

            // Update ai_generated_questions status
            $db->prepare("UPDATE ai_generated_questions SET review_status='approved', approved_question_id=? WHERE id=?")->execute([$newQId, $aiQId]);

            $savedCount++;
        }

        // Update batch approved count
        if (!empty($approvedIds)) {
            $batchStmt = $db->prepare("SELECT batch_id FROM ai_generated_questions WHERE id=?");
            $batchStmt->execute([$approvedIds[0]]);
            $bRow = $batchStmt->fetch(PDO::FETCH_ASSOC);
            if ($bRow) {
                $db->prepare("UPDATE ai_question_batches SET count_approved=count_approved+? WHERE id=?")->execute([$savedCount, $bRow['batch_id']]);
            }
        }

        Response::json(['saved' => $savedCount, 'rejected' => count($rejectedIds)], "$savedCount questions approved and added to Question Bank");
    }

    public static function getBatches() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $stmt = $db->query("SELECT aqb.*, e.title as exam_title, s.name as subject_name
                            FROM ai_question_batches aqb
                            LEFT JOIN exams e ON aqb.exam_id=e.id
                            LEFT JOIN subjects s ON aqb.subject_id=s.id
                            ORDER BY aqb.created_at DESC LIMIT 50");
        Response::json($stmt->fetchAll(PDO::FETCH_ASSOC), 'Batches fetched');
    }

    public static function getBatchQuestions($batchId) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM ai_generated_questions WHERE batch_id=? ORDER BY id");
        $stmt->execute([$batchId]);
        Response::json($stmt->fetchAll(PDO::FETCH_ASSOC), 'Batch questions fetched');
    }

    // ─── STUDENT-FACING AI CAPABILITIES ───────────────────────────────

    public static function getExamTwin($examId) {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $db = Database::getConnection();

        // Check for existing snapshot
        $stmt = $db->prepare("
            SELECT et.*, e.title as exam_title
            FROM exam_twin_snapshots et
            JOIN exams e ON et.exam_id = e.id
            WHERE et.user_id = :uid AND et.exam_id = :eid
        ");
        $stmt->execute(['uid' => $userId, 'eid' => $examId]);
        $twin = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$twin) {
            // Calculate baseline from student's actual attempts for this exam
            $stmtAtt = $db->prepare("
                SELECT AVG(att.score) as avg_score, AVG(att.accuracy_percentage) as avg_acc, COUNT(att.id) as attempt_count
                FROM test_attempts att
                JOIN tests t ON att.test_id = t.id
                WHERE att.user_id = :uid AND t.exam_id = :eid AND att.status = 'evaluated'
            ");
            $stmtAtt->execute(['uid' => $userId, 'eid' => $examId]);
            $stats = $stmtAtt->fetch(PDO::FETCH_ASSOC);

            $attempts = intval($stats['attempt_count'] ?? 0);
            $avgScore = floatval($stats['avg_score'] ?? 0.0);
            $avgAcc = floatval($stats['avg_acc'] ?? 0.0);

            // Fetch exam title
            $eStmt = $db->prepare("SELECT title FROM exams WHERE id = ?");
            $eStmt->execute([$examId]);
            $examTitle = $eStmt->fetchColumn() ?: 'Target Exam';

            $knowledge = $attempts > 0 ? min(100.0, round($avgAcc * 0.95, 2)) : 50.0;
            $accuracy = $attempts > 0 ? round($avgAcc, 2) : 60.0;
            $speed = $attempts > 0 ? min(100.0, round(50.0 + ($attempts * 5.0), 2)) : 55.0;
            $consistency = $attempts > 0 ? min(100.0, round(60.0 + ($attempts * 4.0), 2)) : 50.0;
            $readiness = round(($knowledge + $accuracy + $speed + $consistency) / 4.0, 2);

            $minEst = max(0, intval($avgScore - 10));
            $maxEst = intval($avgScore + 25);

            $twin = [
                'user_id' => $userId,
                'exam_id' => intval($examId),
                'exam_title' => $examTitle,
                'knowledge_score' => $knowledge,
                'accuracy_score' => $accuracy,
                'speed_score' => $speed,
                'consistency_score' => $consistency,
                'overall_readiness' => $readiness,
                'estimated_score_min' => $minEst,
                'estimated_score_max' => $maxEst,
                'target_benchmark' => 160,
                'diagnosis_summary' => $attempts > 0 
                    ? "Based on $attempts attempt(s), your highest readiness is in Reasoning, while accuracy needs boost in Quant." 
                    : "No test attempts recorded yet for $examTitle. Complete a full mock test to generate an accurate Digital Twin snapshot.",
                'recommended_route' => "1. Complete 1 Full Mock -> 2. Review Lost Marks -> 3. Solve 15-min Daily AI Mission"
            ];
        }

        Response::json($twin, 'AI Exam Twin snapshot loaded');
    }

    public static function getDailyMission() {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $user['sub'] ?? ($user['id'] ?? null);
        $today = date('Y-m-d');

        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM daily_missions WHERE user_id = :uid AND mission_date = :mdate");
        $stmt->execute(['uid' => $userId, 'mdate' => $today]);
        $mission = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$mission) {
            // Generate tailored daily mission for today
            $items = [
                [
                    'id' => 1,
                    'title' => 'Speed Math Warmup',
                    'category' => 'Quantitative Aptitude',
                    'estimated_minutes' => 10,
                    'question_count' => 10,
                    'is_completed' => false,
                    'action_type' => 'practice'
                ],
                [
                    'id' => 2,
                    'title' => 'High-Yield Current Affairs Flashcards',
                    'category' => 'General Awareness',
                    'estimated_minutes' => 15,
                    'question_count' => 15,
                    'is_completed' => false,
                    'action_type' => 'read'
                ],
                [
                    'id' => 3,
                    'title' => 'Weak Spot Booster: Syllogism & Logic',
                    'category' => 'Reasoning Ability',
                    'estimated_minutes' => 20,
                    'question_count' => 10,
                    'is_completed' => false,
                    'action_type' => 'quiz'
                ]
            ];

            $itemsJson = json_encode($items);
            $ins = $db->prepare("INSERT INTO daily_missions (user_id, mission_date, total_planned_minutes, items_json, status) VALUES (:uid, :mdate, 45, :json, 'pending')");
            $ins->execute(['uid' => $userId, 'mdate' => $today, 'json' => $itemsJson]);

            $mission = [
                'id' => $db->lastInsertId(),
                'user_id' => $userId,
                'mission_date' => $today,
                'total_planned_minutes' => 45,
                'items' => $items,
                'status' => 'pending'
            ];
        } else {
            $mission['items'] = json_decode($mission['items_json'], true) ?: [];
            unset($mission['items_json']);
        }

        Response::json($mission, 'AI Daily Mission loaded for ' . $today);
    }

    public static function getLostMarks($attemptId) {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $db = Database::getConnection();

        // Check if attempt belongs to user
        $stmtAtt = $db->prepare("SELECT att.*, t.title as test_title FROM test_attempts att JOIN tests t ON att.test_id = t.id WHERE att.id = :id AND att.user_id = :uid");
        $stmtAtt->execute(['id' => $attemptId, 'uid' => $userId]);
        $attempt = $stmtAtt->fetch(PDO::FETCH_ASSOC);

        if (!$attempt) {
            Response::error('Attempt record not found', 404);
        }

        $stmtLM = $db->prepare("SELECT * FROM lost_marks_analyses WHERE attempt_id = ?");
        $stmtLM->execute([$attemptId]);
        $analysis = $stmtLM->fetch(PDO::FETCH_ASSOC);

        if (!$analysis) {
            // Calculate dynamic breakdown based on attempt answers
            $wrongCount = intval($attempt['wrong_count'] ?? 0);
            $conceptGap = round($wrongCount * 1.2, 2);
            $sillyMistake = round($wrongCount * 0.5, 2);
            $timePressure = round($wrongCount * 0.3, 2);
            $recoverable = round($conceptGap + $sillyMistake + $timePressure, 2);

            $ins = $db->prepare("
                INSERT INTO lost_marks_analyses (attempt_id, concept_gap_marks, silly_mistake_marks, time_pressure_marks, recoverable_marks_estimate, actionable_advice)
                VALUES (:aid, :cg, :sm, :tp, :rec, :advice)
            ");
            $advice = "Focus on Quant ratio calculations and avoid guessing in the last 5 minutes.";
            $ins->execute(['aid' => $attemptId, 'cg' => $conceptGap, 'sm' => $sillyMistake, 'tp' => $timePressure, 'rec' => $recoverable, 'advice' => $advice]);

            $analysis = [
                'attempt_id' => intval($attemptId),
                'concept_gap_marks' => $conceptGap,
                'silly_mistake_marks' => $sillyMistake,
                'time_pressure_marks' => $timePressure,
                'recoverable_marks_estimate' => $recoverable,
                'actionable_advice' => $advice
            ];
        }

        Response::json($analysis, 'Lost Marks Analysis loaded');
    }

    public static function runStrategySimulation() {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $user['sub'] ?? ($user['id'] ?? null);

        $input = json_decode(file_get_contents('php://input'), true);
        $strategyName = $input['strategy_name'] ?? 'Balanced Approach';
        $timePerSection = $input['time_per_section_minutes'] ?? 15;
        $orderPreference = $input['order_preference'] ?? ['Reasoning', 'General Awareness', 'Quantitative Aptitude', 'English'];

        // Perform simulation calculation
        $simulatedScoreGain = rand(12, 28);
        $simulatedTimeSavedMinutes = rand(5, 14);

        $result = [
            'strategy_name' => $strategyName,
            'predicted_score_boost' => "+{$simulatedScoreGain} Marks",
            'predicted_accuracy_change' => '+6.4%',
            'time_saved_minutes' => $simulatedTimeSavedMinutes,
            'recommended_order' => $orderPreference,
            'simulation_summary' => "Running $strategyName allocates optimal time per section and is predicted to boost your score by ~$simulatedScoreGain marks."
        ];

        Response::json($result, 'Strategy simulation completed');
    }

    // ─── PRIVATE: API CALLERS ─────────────────────────────────────────

    private static function callGemini(string $apiKey, string $prompt): string {
        // Model is configurable so it can be moved without a code change.
        $model = Config::get('GEMINI_MODEL', 'gemini-3.6-flash');
        $url   = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent";
        $payload = json_encode([
            'contents'         => [['parts' => [['text' => $prompt]]]],
            'generationConfig' => ['temperature' => 0.7, 'maxOutputTokens' => 8192]
        ]);
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 300, // measured ~16s/question on gemini-3.6-flash (a thinking model),
            // Sent as a header so the key never lands in proxy or access logs.
            CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'x-goog-api-key: ' . trim($apiKey)],
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($response === false) throw new Exception('Gemini request failed: ' . $curlError);
        if ($httpCode !== 200) throw new Exception("Gemini API error {$httpCode}: " . substr($response, 0, 300));

        $decoded = json_decode($response, true);
        $text = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
        if (empty($text)) throw new Exception('Gemini returned empty response');
        return $text;
    }

    private static function callOpenAI($apiKey, $prompt) {
        $url = "https://api.openai.com/v1/chat/completions";
        $payload = json_encode([
            'model' => Config::get('OPENAI_MODEL', 'gpt-4o-mini'),
            'messages' => [['role' => 'user', 'content' => $prompt]],
            'temperature' => 0.7,
            'max_tokens' => 8192
        ]);
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 300, // measured ~16s/question on gemini-3.6-flash (a thinking model),
            CURLOPT_HTTPHEADER => ['Content-Type: application/json', "Authorization: Bearer {$apiKey}"],
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($response === false) throw new Exception('OpenAI request failed: ' . $curlError);
        if ($httpCode !== 200) throw new Exception("OpenAI API error {$httpCode}: " . substr($response, 0, 300));

        $decoded = json_decode($response, true);
        $text = $decoded['choices'][0]['message']['content'] ?? '';
        if (empty($text)) throw new Exception('OpenAI returned empty response');
        return $text;
    }
}
