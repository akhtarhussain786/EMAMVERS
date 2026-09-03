<?php
/**
 * AI question bank top-up.
 *
 * Keeps every (exam × subject × difficulty) bucket above its target by
 * generating new questions with the configured AI provider. Runs unattended
 * from cron — this is what makes the bank self-sustaining without a developer
 * adding questions by hand.
 *
 * Usage:
 *   php api/jobs/topup_questions.php [--exam=ID] [--subject=ID] [--limit=N] [--dry-run]
 *
 * Cron (nightly at 2am):
 *   0 2 * * * /usr/bin/php /path/to/api/jobs/topup_questions.php >> /var/log/examverse-topup.log 2>&1
 */
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("This job can only be run from the command line.\n");
}

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../utils/crypto.php';
require_once __DIR__ . '/../utils/question_fingerprint.php';

// ── options ──────────────────────────────────────────────────────────────
$opts       = getopt('', ['exam::', 'subject::', 'limit::', 'dry-run', 'verbose']);
$onlyExam   = isset($opts['exam']) ? (int)$opts['exam'] : null;
$onlySubj   = isset($opts['subject']) ? (int)$opts['subject'] : null;
$maxInserts = isset($opts['limit']) ? max(1, (int)$opts['limit']) : (int)Config::get('AI_TOPUP_NIGHTLY_LIMIT', 100);
$dryRun     = isset($opts['dry-run']);
$verbose    = isset($opts['verbose']);

// Batch size is capped because generation is slow (~16s/question measured);
// a larger request would exceed the provider request timeout.
$batchSize   = max(1, min(15, (int)Config::get('AI_TOPUP_BATCH_SIZE', 10)));
$autoPublish = Config::bool('AI_AUTO_PUBLISH', true);

function out($msg) { echo '[' . date('H:i:s') . '] ' . $msg . "\n"; }

$db = Database::getConnection();
out('Question bank top-up starting' . ($dryRun ? ' (DRY RUN)' : ''));

// ── which buckets are below target? ──────────────────────────────────────
$sql = "
    SELECT t.exam_id, e.title AS exam_title, t.subject_id, s.name AS subject_name,
           t.target_per_difficulty, d.difficulty,
           COALESCE(cnt.total, 0) AS current_total
    FROM exam_bank_targets t
    JOIN exams e ON t.exam_id = e.id
    JOIN subjects s ON t.subject_id = s.id
    CROSS JOIN (SELECT 'easy' AS difficulty UNION SELECT 'medium' UNION SELECT 'hard') d
    LEFT JOIN (
        SELECT qe.exam_id, q.subject_id, q.difficulty, COUNT(*) AS total
        FROM questions q
        JOIN question_exams qe ON qe.question_id = q.id
        WHERE q.status = 'published'
        GROUP BY qe.exam_id, q.subject_id, q.difficulty
    ) cnt ON cnt.exam_id = t.exam_id AND cnt.subject_id = t.subject_id AND cnt.difficulty = d.difficulty
    WHERE t.auto_topup = 1
      AND COALESCE(cnt.total, 0) < t.target_per_difficulty
";
$params = [];
if ($onlyExam) { $sql .= " AND t.exam_id = ?"; $params[] = $onlyExam; }
if ($onlySubj) { $sql .= " AND t.subject_id = ?"; $params[] = $onlySubj; }
// Emptiest buckets first, so a limited run fixes the worst gaps.
$sql .= " ORDER BY (t.target_per_difficulty - COALESCE(cnt.total,0)) DESC";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$buckets = $stmt->fetchAll();

if (!$buckets) {
    out('Every configured bucket is at or above target. Nothing to do.');
    exit(0);
}
out(count($buckets) . ' bucket(s) below target; inserting at most ' . $maxInserts . ' question(s) this run.');

// ── AI key ───────────────────────────────────────────────────────────────
$keyRow = $db->query("SELECT * FROM ai_api_keys WHERE is_active = 1 ORDER BY created_at DESC LIMIT 1")->fetch();
if (!$keyRow) {
    $envKey = Config::get('GEMINI_API_KEY', '');
    if ($envKey === '') { out('ERROR: no active AI key in the database and no GEMINI_API_KEY set.'); exit(1); }
    $keyRow = ['id' => null, 'provider' => 'gemini', 'api_key_encrypted' => null];
    $apiKey = $envKey;
} else {
    $apiKey = Crypto::decrypt($keyRow['api_key_encrypted']);
}
$provider = $keyRow['provider'] ?? 'gemini';

$totalInserted = 0;
$totalDupes    = 0;

foreach ($buckets as $b) {
    if ($totalInserted >= $maxInserts) { out('Insert limit reached; stopping.'); break; }

    $shortfall = (int)$b['target_per_difficulty'] - (int)$b['current_total'];
    $want      = min($batchSize, $shortfall, $maxInserts - $totalInserted);
    if ($want < 1) continue;

    $label = sprintf('%s / %s / %s', $b['exam_title'], $b['subject_name'], $b['difficulty']);
    out(sprintf('  %-52s have %3d, target %3d -> requesting %d', $label, $b['current_total'], $b['target_per_difficulty'], $want));

    if ($dryRun) { $totalInserted += $want; continue; }

    $runStmt = $db->prepare("INSERT INTO question_topup_runs (exam_id, subject_id, difficulty, requested, status) VALUES (?,?,?,?,'running')");
    $runStmt->execute([$b['exam_id'], $b['subject_id'], $b['difficulty'], $want]);
    $runId = $db->lastInsertId();

    try {
        $questions = generateQuestions($apiKey, $provider, $b, $want);
        $inserted = 0; $dupes = 0;

        foreach ($questions as $q) {
            $optionTexts = [$q['option_a'], $q['option_b'], $q['option_c'], $q['option_d']];
            $contentHash = QuestionFingerprint::contentHash($q['question_text'], $optionTexts);

            // Dedup is what stops the bank filling with near-identical items.
            if (QuestionFingerprint::findDuplicate($db, $contentHash)) { $dupes++; continue; }

            $structureHash = QuestionFingerprint::structureHash($q['question_text'], $optionTexts);
            // Cap variants of one template so a single pattern cannot dominate.
            if (QuestionFingerprint::countSameStructure($db, $structureHash) >= (int)Config::get('AI_MAX_STRUCTURE_VARIANTS', 8)) {
                $dupes++; continue;
            }

            $db->beginTransaction();
            try {
                $status = $autoPublish ? 'published' : 'review';
                $db->prepare("INSERT INTO questions (subject_id, question_type, difficulty, status, content_hash, structure_hash) VALUES (?, 'MCQ', ?, ?, ?, ?)")
                   ->execute([$b['subject_id'], $b['difficulty'], $status, $contentHash, $structureHash]);
                $qId = $db->lastInsertId();

                $db->prepare("INSERT INTO question_translations (question_id, language, question_text, solution_text) VALUES (?, 'en', ?, ?)")
                   ->execute([$qId, $q['question_text'], $q['explanation']]);

                $optStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
                foreach (['A','B','C','D'] as $i => $key) {
                    $optStmt->execute([$qId, $key, $optionTexts[$i], $key === $q['correct_option'] ? 1 : 0]);
                }

                $db->prepare("INSERT IGNORE INTO question_exams (question_id, exam_id) VALUES (?, ?)")
                   ->execute([$qId, $b['exam_id']]);

                $db->commit();
                $inserted++;
            } catch (Throwable $e) {
                $db->rollBack();
                out('    insert failed: ' . $e->getMessage());
            }
        }

        $db->prepare("UPDATE question_topup_runs SET generated_count=?, duplicates_rejected=?, inserted=?, status='completed', finished_at=NOW() WHERE id=?")
           ->execute([count($questions), $dupes, $inserted, $runId]);
        if ($keyRow['id']) {
            $db->prepare("UPDATE ai_api_keys SET usage_count=usage_count+1, last_used_at=NOW() WHERE id=?")->execute([$keyRow['id']]);
        }

        out(sprintf('    generated %d, rejected %d duplicate(s), inserted %d', count($questions), $dupes, $inserted));
        $totalInserted += $inserted;
        $totalDupes    += $dupes;

    } catch (Throwable $e) {
        $db->prepare("UPDATE question_topup_runs SET status='error', error_message=?, finished_at=NOW() WHERE id=?")
           ->execute([$e->getMessage(), $runId]);
        out('    ERROR: ' . $e->getMessage());
    }
}

out(sprintf('Done. Inserted %d question(s), rejected %d duplicate(s).', $totalInserted, $totalDupes));
exit(0);


// ─────────────────────────────────────────────────────────────────────────
function generateQuestions($apiKey, $provider, array $bucket, int $count): array {
    $prompt = "You are an expert question setter for Indian competitive exams.\n"
        . "Generate exactly {$count} multiple choice questions for:\n"
        . "- Exam: {$bucket['exam_title']}\n"
        . "- Subject: {$bucket['subject_name']}\n"
        . "- Difficulty: {$bucket['difficulty']}\n\n"
        . "RULES:\n"
        . "1. Questions must be accurate and appropriate for this exam.\n"
        . "2. Exactly 4 options; exactly one correct.\n"
        . "3. Vary the topics — do not produce variations of a single template.\n"
        . "4. Include a 2-3 sentence explanation of the correct answer.\n\n"
        . "Respond with ONLY a valid JSON array, no markdown fences:\n"
        . '[{"question_text":"...","option_a":"...","option_b":"...","option_c":"...","option_d":"...","correct_option":"A","explanation":"..."}]';

    $raw = $provider === 'openai' ? callOpenAI($apiKey, $prompt) : callGemini($apiKey, $prompt);

    $clean = trim($raw);
    $clean = preg_replace('/^```(?:json)?\s*/i', '', $clean);
    $clean = preg_replace('/\s*```\s*$/', '', $clean);

    $parsed = json_decode($clean, true);
    if (!is_array($parsed)) {
        throw new RuntimeException('AI response was not a JSON array: ' . substr($raw, 0, 160));
    }

    $valid = [];
    foreach ($parsed as $q) {
        if (empty($q['question_text']) || empty($q['option_a']) || empty($q['correct_option'])) continue;
        $correct = strtoupper(trim($q['correct_option']));
        if (!in_array($correct, ['A','B','C','D'], true)) continue;

        $valid[] = [
            'question_text'  => trim($q['question_text']),
            'option_a'       => trim($q['option_a']),
            'option_b'       => trim($q['option_b'] ?? ''),
            'option_c'       => trim($q['option_c'] ?? ''),
            'option_d'       => trim($q['option_d'] ?? ''),
            'correct_option' => $correct,
            'explanation'    => trim($q['explanation'] ?? ''),
        ];
    }
    return $valid;
}

function callGemini(string $apiKey, string $prompt): string {
    $model = Config::get('GEMINI_MODEL', 'gemini-3.6-flash');
    $ch = curl_init("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent");
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode([
            'contents' => [['parts' => [['text' => $prompt]]]],
            'generationConfig' => ['temperature' => 0.9, 'maxOutputTokens' => 32000],
        ]),
        CURLOPT_RETURNTRANSFER => true,
        // Generous: a thinking model spends ~16s per question.
        CURLOPT_TIMEOUT => 600,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'x-goog-api-key: ' . trim($apiKey)],
    ]);
    $response = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err  = curl_error($ch);
    curl_close($ch);

    if ($response === false) throw new RuntimeException('Gemini request failed: ' . $err);
    if ($code !== 200) throw new RuntimeException("Gemini HTTP {$code}: " . substr($response, 0, 200));

    $decoded = json_decode($response, true);
    $text = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
    if ($text === '') {
        $reason = $decoded['candidates'][0]['finishReason'] ?? 'unknown';
        throw new RuntimeException('Gemini returned no text (finishReason: ' . $reason . ')');
    }
    return $text;
}

function callOpenAI(string $apiKey, string $prompt): string {
    $ch = curl_init('https://api.openai.com/v1/chat/completions');
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode([
            'model' => Config::get('OPENAI_MODEL', 'gpt-4o-mini'),
            'messages' => [['role' => 'user', 'content' => $prompt]],
            'temperature' => 0.9,
        ]),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 600,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', "Authorization: Bearer {$apiKey}"],
    ]);
    $response = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err  = curl_error($ch);
    curl_close($ch);

    if ($response === false) throw new RuntimeException('OpenAI request failed: ' . $err);
    if ($code !== 200) throw new RuntimeException("OpenAI HTTP {$code}: " . substr($response, 0, 200));

    $decoded = json_decode($response, true);
    $text = $decoded['choices'][0]['message']['content'] ?? '';
    if ($text === '') throw new RuntimeException('OpenAI returned an empty response');
    return $text;
}
