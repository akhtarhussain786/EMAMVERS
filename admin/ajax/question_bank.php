<?php
/**
 * Admin AJAX: question bank health and top-up controls.
 * URL: /EXAMVERSE/admin/ajax/question_bank.php?action=...
 */
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';

$db      = Database::getConnection();
$action  = $_GET['action'] ?? 'levels';
$adminId = $_SESSION['admin_user']['id'] ?? null;

switch ($action) {

    // ── BANK DEPTH PER EXAM / SUBJECT / DIFFICULTY ─────────────────────
    case 'levels':
        $examId = intval($_GET['exam_id'] ?? 0);

        $sql = "
            SELECT t.exam_id, e.title AS exam_title, t.subject_id, s.name AS subject_name,
                   t.target_per_difficulty, t.auto_topup, d.difficulty,
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
        ";
        $params = [];
        if ($examId) { $sql .= " WHERE t.exam_id = ?"; $params[] = $examId; }
        $sql .= " ORDER BY e.title, s.name, FIELD(d.difficulty,'easy','medium','hard')";

        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $totals = $db->query("
            SELECT
              (SELECT COUNT(*) FROM questions WHERE status='published') AS published,
              (SELECT COUNT(*) FROM questions WHERE status='review')    AS awaiting_review,
              (SELECT COUNT(*) FROM questions WHERE author_user_id IS NOT NULL AND status='published') AS from_teachers,
              (SELECT COUNT(*) FROM question_exams) AS bank_links
        ")->fetch(PDO::FETCH_ASSOC);

        $runs = $db->query("
            SELECT r.*, e.title AS exam_title, s.name AS subject_name
            FROM question_topup_runs r
            LEFT JOIN exams e ON r.exam_id = e.id
            LEFT JOIN subjects s ON r.subject_id = s.id
            ORDER BY r.id DESC LIMIT 10
        ")->fetchAll(PDO::FETCH_ASSOC);

        ajaxOk(['levels' => $rows, 'totals' => $totals, 'recent_runs' => $runs], 'Bank levels loaded');
        break;

    // ── EXAMS + SUBJECTS FOR THE TARGET EDITOR ─────────────────────────
    case 'meta':
        ajaxOk([
            'exams'    => $db->query("SELECT id, title FROM exams WHERE status='active' ORDER BY title")->fetchAll(PDO::FETCH_ASSOC),
            'subjects' => $db->query("SELECT id, name FROM subjects ORDER BY name")->fetchAll(PDO::FETCH_ASSOC),
        ], 'Meta loaded');
        break;

    // ── SET A TARGET ───────────────────────────────────────────────────
    case 'set_target':
        $body      = getBody();
        $examId    = intval($body['exam_id'] ?? 0);
        $subjectId = intval($body['subject_id'] ?? 0);
        $target    = intval($body['target_per_difficulty'] ?? 0);
        $auto      = !empty($body['auto_topup']) ? 1 : 0;

        if (!$examId || !$subjectId) ajaxErr('exam_id and subject_id are required', 422);
        if ($target < 0 || $target > 5000) ajaxErr('Target must be between 0 and 5000', 422);

        $db->prepare("
            INSERT INTO exam_bank_targets (exam_id, subject_id, target_per_difficulty, auto_topup)
            VALUES (?,?,?,?)
            ON DUPLICATE KEY UPDATE target_per_difficulty = VALUES(target_per_difficulty), auto_topup = VALUES(auto_topup)
        ")->execute([$examId, $subjectId, $target, $auto]);

        ajaxOk(null, 'Target saved ✓');
        break;

    case 'delete_target':
        $id = intval($_GET['id'] ?? 0);
        $examId = intval($_GET['exam_id'] ?? 0);
        $subjectId = intval($_GET['subject_id'] ?? 0);
        if (!$examId || !$subjectId) ajaxErr('exam_id and subject_id are required', 422);
        $db->prepare("DELETE FROM exam_bank_targets WHERE exam_id=? AND subject_id=?")->execute([$examId, $subjectId]);
        ajaxOk(null, 'Target removed');
        break;

    // ── FILL ONE BUCKET NOW ────────────────────────────────────────────
    // Generation takes minutes, so the CLI job is spawned detached and the
    // page polls run status rather than holding the request open.
    case 'fill_bucket':
        $body       = getBody();
        $examId     = intval($body['exam_id'] ?? 0);
        $subjectId  = intval($body['subject_id'] ?? 0);
        $difficulty = $body['difficulty'] ?? '';
        $limit      = max(1, min(50, intval($body['limit'] ?? 10)));

        if (!$examId || !$subjectId) ajaxErr('exam_id and subject_id are required', 422);
        if ($difficulty !== '' && !in_array($difficulty, ['easy','medium','hard'], true)) {
            ajaxErr('difficulty must be easy, medium or hard', 422);
        }

        // Refuse to stack runs on the same bucket.
        $busy = $db->prepare("
            SELECT COUNT(*) FROM question_topup_runs
            WHERE status = 'running' AND exam_id = ? AND subject_id = ?
              AND started_at > (NOW() - INTERVAL 1 HOUR)
        ");
        $busy->execute([$examId, $subjectId]);
        if ($busy->fetchColumn() > 0) ajaxErr('A top-up is already running for this bucket.', 409);

        $php = PHP_BINARY ?: 'php';
        $job = realpath(__DIR__ . '/../../api/jobs/topup_questions.php');
        if (!$job) ajaxErr('Top-up job not found on disk', 500);

        $cmd = escapeshellcmd($php) . ' ' . escapeshellarg($job)
             . ' --exam=' . escapeshellarg((string)$examId)
             . ' --subject=' . escapeshellarg((string)$subjectId)
             . ' --limit=' . escapeshellarg((string)$limit);
        if ($difficulty !== '') $cmd .= ' --difficulty=' . escapeshellarg($difficulty);

        $logDir = __DIR__ . '/../../api/storage/logs';
        if (!is_dir($logDir)) @mkdir($logDir, 0770, true);
        $logFile = $logDir . '/topup-' . date('Ymd') . '.log';

        // Detach so the HTTP request returns immediately.
        @exec($cmd . ' >> ' . escapeshellarg($logFile) . ' 2>&1 &');

        auditLog($db, $adminId, 'BANK_TOPUP', $examId, sprintf(
            'Manual top-up: exam %d, subject %d, difficulty %s, limit %d',
            $examId, $subjectId, $difficulty ?: 'all', $limit
        ));

        ajaxOk(['started' => true], 'Top-up started in the background. Refresh in a minute to see new questions.', 202);
        break;

    // ── POLL RUN STATUS ────────────────────────────────────────────────
    case 'run_status':
        $rows = $db->query("
            SELECT r.id, r.difficulty, r.requested, r.generated_count, r.duplicates_rejected,
                   r.inserted, r.status, r.started_at, r.finished_at,
                   LEFT(COALESCE(r.error_message,''), 160) AS error_message,
                   e.title AS exam_title, s.name AS subject_name
            FROM question_topup_runs r
            LEFT JOIN exams e ON r.exam_id = e.id
            LEFT JOIN subjects s ON r.subject_id = s.id
            ORDER BY r.id DESC LIMIT 12
        ")->fetchAll(PDO::FETCH_ASSOC);
        ajaxOk($rows, 'Run status');
        break;

    default:
        ajaxErr("Unknown action: $action", 400);
}
