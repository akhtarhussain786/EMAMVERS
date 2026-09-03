<?php
/**
 * Admin AJAX: AI Question Generation
 * URL: /EXAMVERSE/admin/ajax/ai_generate.php?action=generate|approve|batches|batch_questions
 * Auth: PHP Session
 */
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';
require_once __DIR__ . '/../../api/utils/crypto.php';
require_once __DIR__ . '/../../api/config/config.php';

$db     = Database::getConnection();
$action = $_GET['action'] ?? 'generate';

switch ($action) {

    // ── GENERATE QUESTIONS ─────────────────────────────────────────────
    case 'generate':
        $body       = getBody();
        $examId     = intval($body['exam_id'] ?? 0);
        $subjectId  = intval($body['subject_id'] ?? 0);
        $section    = trim($body['section_name'] ?? 'General');
        $difficulty = in_array($body['difficulty'] ?? '', ['easy','medium','hard']) ? $body['difficulty'] : 'medium';
        $count      = min(max(1, intval($body['count'] ?? 5)), 30);
        $language   = $body['language'] ?? 'en';

        // Get active API key
        $keyRow = $db->query("SELECT * FROM ai_api_keys WHERE is_active=1 ORDER BY created_at DESC LIMIT 1")->fetch(PDO::FETCH_ASSOC);
        if (!$keyRow) {
            ajaxErr('No active AI API key found. Please add one in the API Key Manager above.', 400);
        }

        $apiKey   = Crypto::decrypt($keyRow['api_key_encrypted']);
        $provider = $keyRow['provider'];

        // Resolve exam/subject names
        $examName    = 'Indian Competitive Exam';
        $subjectName = $section;
        if ($examId) {
            $r = $db->prepare("SELECT title FROM exams WHERE id=?");
            $r->execute([$examId]);
            $examName = $r->fetchColumn() ?: $examName;
        }
        if ($subjectId) {
            $r = $db->prepare("SELECT name FROM subjects WHERE id=?");
            $r->execute([$subjectId]);
            $subjectName = $r->fetchColumn() ?: $subjectName;
        }

        $langLabel = $language === 'hi' ? 'Hindi' : 'English';

        $prompt = "You are an expert MCQ question setter for Indian competitive exams. Generate exactly {$count} multiple choice questions for:
- Exam: {$examName}
- Subject/Section: {$subjectName}
- Difficulty: {$difficulty}
- Language: {$langLabel}

RULES:
1. Questions must be relevant, accurate, and exam-appropriate
2. Each question must have exactly 4 options (A, B, C, D)
3. Only one correct answer per question
4. Include a clear 2-3 sentence explanation

Respond with ONLY a valid JSON array (no markdown, no text outside the array):
[
  {
    \"question_text\": \"Question here?\",
    \"option_a\": \"First option\",
    \"option_b\": \"Second option\",
    \"option_c\": \"Third option\",
    \"option_d\": \"Fourth option\",
    \"correct_option\": \"A\",
    \"explanation\": \"Explanation here.\",
    \"difficulty\": \"{$difficulty}\"
  }
]

Generate {$count} questions now:";

        // Create batch
        $bs = $db->prepare("INSERT INTO ai_question_batches (ai_key_id, exam_id, subject_id, section_name, difficulty, language, count_requested, status, prompt_text) VALUES (?,?,?,?,?,?,?,'pending',?)");
        $bs->execute([$keyRow['id'], $examId ?: null, $subjectId ?: null, $section, $difficulty, $language, $count, $prompt]);
        $batchId = $db->lastInsertId();

        // Call AI
        $rawResponse = '';
        $questions   = [];

        try {
            $rawResponse = ($provider === 'gemini')
                ? callGemini($apiKey, $prompt)
                : callOpenAI($apiKey, $prompt);

            // Strip markdown fences if present
            $clean = trim($rawResponse);
            $clean = preg_replace('/^```(?:json)?\s*/i', '', $clean);
            $clean = preg_replace('/\s*```\s*$/i', '', $clean);

            $parsed = json_decode($clean, true);
            if (!is_array($parsed) || empty($parsed)) {
                throw new Exception('AI returned invalid JSON. Raw: ' . substr($rawResponse, 0, 300));
            }

            foreach ($parsed as $q) {
                if (empty($q['question_text'])) continue;
                $correct = strtoupper(trim($q['correct_option'] ?? 'A'));
                if (!in_array($correct, ['A','B','C','D'])) $correct = 'A';

                $ins = $db->prepare("INSERT INTO ai_generated_questions (batch_id, question_text, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty) VALUES (?,?,?,?,?,?,?,?,?)");
                $ins->execute([
                    $batchId,
                    $q['question_text'],
                    $q['option_a'] ?? '',
                    $q['option_b'] ?? '',
                    $q['option_c'] ?? '',
                    $q['option_d'] ?? '',
                    $correct,
                    $q['explanation'] ?? '',
                    $difficulty
                ]);
                $q['id'] = $db->lastInsertId();
                $questions[] = $q;
            }

            $db->prepare("UPDATE ai_question_batches SET status='completed', count_generated=?, raw_response=? WHERE id=?")->execute([count($questions), $rawResponse, $batchId]);
            $db->prepare("UPDATE ai_api_keys SET usage_count=usage_count+1, last_used_at=NOW() WHERE id=?")->execute([$keyRow['id']]);

            ajaxOk([
                'batch_id'  => $batchId,
                'count'     => count($questions),
                'questions' => $questions,
                'exam'      => $examName,
                'subject'   => $subjectName,
                'provider'  => $provider,
            ], count($questions) . ' questions generated successfully!');

        } catch (Exception $e) {
            $db->prepare("UPDATE ai_question_batches SET status='error', error_message=?, raw_response=? WHERE id=?")->execute([$e->getMessage(), $rawResponse, $batchId]);
            error_log('EXAMVERSE admin AI generation failed (batch ' . $batchId . '): ' . $e->getMessage());
            ajaxErr('AI Generation failed: ' . (Config::isDebug() ? $e->getMessage() : 'see server log for details'), 502);
        }
        break;

    // ── APPROVE / REJECT BATCH ─────────────────────────────────────────
    case 'approve':
        $body        = getBody();
        $approvedIds = array_map('intval', $body['approved_ids'] ?? []);
        $rejectedIds = array_map('intval', $body['rejected_ids'] ?? []);

        if (empty($approvedIds) && empty($rejectedIds)) ajaxErr('No IDs provided', 422);

        $saved = 0;

        // Reject
        if (!empty($rejectedIds)) {
            $ph = implode(',', array_fill(0, count($rejectedIds), '?'));
            $db->prepare("UPDATE ai_generated_questions SET review_status='rejected' WHERE id IN ($ph)")->execute($rejectedIds);
        }

        // Approve → insert into real question bank
        foreach ($approvedIds as $aiQId) {
            $s = $db->prepare("SELECT aqg.*, aqb.subject_id FROM ai_generated_questions aqg JOIN ai_question_batches aqb ON aqg.batch_id=aqb.id WHERE aqg.id=? AND aqg.review_status IN ('pending','edited')");
            $s->execute([$aiQId]);
            $aiQ = $s->fetch(PDO::FETCH_ASSOC);
            if (!$aiQ) continue;

            $subjectId = $aiQ['subject_id'] ?: 1;

            // Without a rollback path a failure mid-loop leaves the
            // transaction open and the connection unusable for later requests.
            $db->beginTransaction();
            try {
                $db->prepare("INSERT INTO questions (subject_id, question_type, difficulty, status) VALUES (?,'MCQ',?,'published')")->execute([$subjectId, $aiQ['difficulty']]);
                $newQId = $db->lastInsertId();

                $db->prepare("INSERT INTO question_translations (question_id, language, question_text, solution_text) VALUES (?,'en',?,?)")->execute([$newQId, $aiQ['question_text'], $aiQ['explanation']]);

                $optStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?,?,'en',?,?)");
                foreach (['A' => 'option_a', 'B' => 'option_b', 'C' => 'option_c', 'D' => 'option_d'] as $key => $col) {
                    $optStmt->execute([$newQId, $key, $aiQ[$col], ($key === strtoupper($aiQ['correct_option'])) ? 1 : 0]);
                }

                $db->prepare("UPDATE ai_generated_questions SET review_status='approved', approved_question_id=? WHERE id=?")->execute([$newQId, $aiQId]);
                $db->commit();
                $saved++;
            } catch (Throwable $e) {
                $db->rollBack();
                error_log('EXAMVERSE AI approve failed for generated question ' . $aiQId . ': ' . $e->getMessage());
            }
        }

        // Update batch count
        if (!empty($approvedIds)) {
            $b = $db->prepare("SELECT batch_id FROM ai_generated_questions WHERE id=?");
            $b->execute([$approvedIds[0]]);
            $bRow = $b->fetch(PDO::FETCH_ASSOC);
            if ($bRow) $db->prepare("UPDATE ai_question_batches SET count_approved=count_approved+? WHERE id=?")->execute([$saved, $bRow['batch_id']]);
        }

        ajaxOk(['saved' => $saved, 'rejected' => count($rejectedIds)], "$saved questions saved to Question Bank!");
        break;

    // ── LIST BATCHES ───────────────────────────────────────────────────
    case 'batches':
        $rows = $db->query("SELECT aqb.*, e.title as exam_title, s.name as subject_name
                            FROM ai_question_batches aqb
                            LEFT JOIN exams e ON aqb.exam_id=e.id
                            LEFT JOIN subjects s ON aqb.subject_id=s.id
                            ORDER BY aqb.created_at DESC LIMIT 20")->fetchAll(PDO::FETCH_ASSOC);
        ajaxOk($rows, 'Batches fetched');
        break;

    // ── GET BATCH QUESTIONS ────────────────────────────────────────────
    case 'batch_questions':
        $bid = intval($_GET['batch_id'] ?? 0);
        if (!$bid) ajaxErr('batch_id required', 422);
        $rows = $db->prepare("SELECT * FROM ai_generated_questions WHERE batch_id=? ORDER BY id");
        $rows->execute([$bid]);
        ajaxOk($rows->fetchAll(PDO::FETCH_ASSOC), 'Questions fetched');
        break;

    default:
        ajaxErr("Unknown action: $action", 400);
}

// ─── AI CALLER FUNCTIONS ───────────────────────────────────────────────────

function callGemini(string $apiKey, string $prompt): string {
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
        CURLOPT_SSL_VERIFYPEER => false, // for localhost dev
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr  = curl_error($ch);
    curl_close($ch);

    if ($curlErr) throw new Exception("cURL error: $curlErr");
    if ($httpCode !== 200) throw new Exception("Gemini API error HTTP $httpCode: " . substr($response, 0, 400));

    $decoded = json_decode($response, true);
    $text    = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
    if (empty($text)) throw new Exception('Gemini returned empty content. Response: ' . substr($response, 0, 300));
    return $text;
}

function callOpenAI(string $apiKey, string $prompt): string {
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
    if ($httpCode !== 200) throw new Exception("OpenAI API error HTTP $httpCode: " . substr($response, 0, 400));

    $decoded = json_decode($response, true);
    $text    = $decoded['choices'][0]['message']['content'] ?? '';
    if (empty($text)) throw new Exception('OpenAI returned empty content');
    return $text;
}
