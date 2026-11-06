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
 *   php api/jobs/topup_questions.php [--exam=ID] [--subject=ID] [--difficulty=D] [--limit=N] [--dry-run]
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
$opts       = getopt('', ['exam::', 'subject::', 'difficulty::', 'limit::', 'dry-run', 'verbose']);
$onlyExam   = isset($opts['exam']) ? (int)$opts['exam'] : null;
$onlySubj   = isset($opts['subject']) ? (int)$opts['subject'] : null;
$onlyDiff   = isset($opts['difficulty']) && in_array($opts['difficulty'], ['easy','medium','hard'], true)
              ? $opts['difficulty'] : null;
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

// ── which buckets need questions? ────────────────────────────────────────
//
// Two modes. Unattended (cron) walks the configured targets and fills whatever
// has fallen behind. Manual — an admin naming an exam and subject, which is
// what the "Fill now" button does — generates for exactly that bucket, whether
// or not a target row exists and whether or not it is already at target.
// Without this the button reported "top-up started" and then did nothing for
// any bucket the admin had not previously configured.
$manualBucket = ($onlyExam && $onlySubj);

if ($manualBucket) {
    $difficulties = $onlyDiff ? [$onlyDiff] : ['easy', 'medium', 'hard'];
    $placeholders = implode(',', array_fill(0, count($difficulties), '?'));

    $stmt = $db->prepare("
        SELECT e.id AS exam_id, e.title AS exam_title, s.id AS subject_id, s.name AS subject_name,
               COALESCE(t.target_per_difficulty, 0) AS target_per_difficulty,
               d.difficulty,
               COALESCE(cnt.total, 0) AS current_total
        FROM exams e
        JOIN subjects s ON s.id = ?
        CROSS JOIN (
            SELECT 'easy' AS difficulty UNION SELECT 'medium' UNION SELECT 'hard'
        ) d
        LEFT JOIN exam_bank_targets t ON t.exam_id = e.id AND t.subject_id = s.id
        LEFT JOIN (
            SELECT qe.exam_id, q.subject_id, q.difficulty, COUNT(*) AS total
            FROM questions q
            JOIN question_exams qe ON qe.question_id = q.id
            WHERE q.status = 'published'
            GROUP BY qe.exam_id, q.subject_id, q.difficulty
        ) cnt ON cnt.exam_id = e.id AND cnt.subject_id = s.id AND cnt.difficulty = d.difficulty
        WHERE e.id = ?
          AND d.difficulty IN ($placeholders)
        ORDER BY FIELD(d.difficulty, 'easy', 'medium', 'hard')
    ");
    $stmt->execute(array_merge([$onlySubj, $onlyExam], $difficulties));
    $buckets = $stmt->fetchAll();

    if (!$buckets) {
        out("ERROR: exam {$onlyExam} / subject {$onlySubj} does not exist.");
        exit(1);
    }
    out(count($buckets) . ' bucket(s) requested manually; inserting at most ' . $maxInserts . ' question(s) this run.');
} else {
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
    if ($onlyDiff) { $sql .= " AND d.difficulty = ?"; $params[] = $onlyDiff; }
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
}

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

    // A cron run only makes up the shortfall against the configured target. A
    // manual run has no target to work from — the admin asked for questions, so
    // --limit is the quantity, not a ceiling on a shortfall of zero.
    $remaining = $maxInserts - $totalInserted;
    if ($manualBucket) {
        $want = min($batchSize, $remaining);
    } else {
        $shortfall = (int)$b['target_per_difficulty'] - (int)$b['current_total'];
        $want      = min($batchSize, $shortfall, $remaining);
    }
    if ($want < 1) continue;

    $label = sprintf('%s / %s / %s', $b['exam_title'], $b['subject_name'], $b['difficulty']);
    if ($manualBucket) {
        out(sprintf('  %-52s have %3d -> requesting %d (manual)', $label, $b['current_total'], $want));
    } else {
        out(sprintf('  %-52s have %3d, target %3d -> requesting %d', $label, $b['current_total'], $b['target_per_difficulty'], $want));
    }

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

/**
 * Calls Gemini, retrying the failures the provider itself describes as
 * temporary.
 *
 * 503 ("this model is currently experiencing high demand"), 429 and the 5xx
 * family are transient: the request is fine and the same call succeeds later.
 * Without a retry a nightly run was abandoned entirely whenever Gemini happened
 * to be busy, which is how a healthy bucket stayed empty. 4xx other than 429 is
 * our fault (bad model, bad key, malformed body) and is not worth repeating.
 */
function callGemini(string $apiKey, string $prompt): string {
    $model      = Config::get('GEMINI_MODEL', 'gemini-3.6-flash');
    // Configurable so the job can be pointed at a proxy or a stub endpoint
    // without editing code; defaults to Google's own host.
    $baseUrl    = rtrim(Config::get('GEMINI_BASE_URL', 'https://generativelanguage.googleapis.com/v1beta'), '/');
    $maxTries   = max(1, (int)Config::get('AI_HTTP_MAX_ATTEMPTS', 4));
    $backoff    = max(1, (int)Config::get('AI_HTTP_BACKOFF_SECONDS', 5));
    $lastError  = 'no attempt made';

    for ($attempt = 1; $attempt <= $maxTries; $attempt++) {
        $ch = curl_init("{$baseUrl}/models/{$model}:generateContent");
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
        $code     = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err      = curl_error($ch);
        curl_close($ch);

        $transport = ($response === false);
        $retryable = $transport || $code === 429 || $code >= 500;

        if (!$transport && $code === 200) {
            $decoded = json_decode($response, true);
            $text = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';
            if ($text !== '') return $text;

            $reason = $decoded['candidates'][0]['finishReason'] ?? 'unknown';
            // An empty body with a non-terminal reason is worth one more try.
            $lastError = 'Gemini returned no text (finishReason: ' . $reason . ')';
            $retryable = in_array($reason, ['unknown', 'OTHER', 'RECITATION'], true);
        } elseif ($transport) {
            $lastError = 'Gemini request failed: ' . $err;
        } else {
            $lastError = "Gemini HTTP {$code}: " . substr((string)$response, 0, 200);
        }

        if (!$retryable || $attempt === $maxTries) break;

        $wait = $backoff * (2 ** ($attempt - 1));   // 5s, 10s, 20s
        out(sprintf('    %s — retrying in %ds (attempt %d of %d)',
            preg_replace('/\s+/', ' ', substr($lastError, 0, 90)), $wait, $attempt + 1, $maxTries));
        sleep($wait);
    }

    throw new RuntimeException($lastError);
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
