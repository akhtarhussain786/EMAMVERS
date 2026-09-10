<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$message = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['bulk_import'])) {
    $rawJson = trim($_POST['json_data']);
    if ($rawJson) {
        $questions = json_decode($rawJson, true);
        if (is_array($questions)) {
            $count = 0;
            foreach ($questions as $qData) {
                $stmtQ = $db->prepare("INSERT INTO questions (subject_id, question_type, difficulty, pyq_year, status) VALUES (:sid, 'MCQ', 'medium', :pyq, 'published')");
                $stmtQ->execute(['sid' => intval($qData['subject_id'] ?? 1), 'pyq' => intval($qData['pyq_year'] ?? 2023)]);
                $qId = $db->lastInsertId();

                $stmtTrans = $db->prepare("INSERT INTO question_translations (question_id, language, question_text, solution_text, shortcut_text) VALUES (:qid, 'en', :qtext, :sol, :short)");
                $stmtTrans->execute(['qid' => $qId, 'qtext' => $qData['question_text'], 'sol' => $qData['solution'] ?? '', 'short' => $qData['shortcut'] ?? '']);

                if (isset($qData['options']) && is_array($qData['options'])) {
                    foreach ($qData['options'] as $key => $optText) {
                        $isCorr = (isset($qData['correct_option']) && $qData['correct_option'] === $key) ? 1 : 0;
                        $stmtOpt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (:qid, :k, 'en', :otext, :corr)");
                        $stmtOpt->execute(['qid' => $qId, 'k' => $key, 'otext' => $optText, 'corr' => $isCorr]);
                    }
                }
                $count++;
            }
            $message = "Successfully bulk imported $count questions into Question Bank!";
        }
    }
}

$questions = $db->query("
    SELECT q.id, q.question_type, q.difficulty, q.pyq_year, s.name as subject_name, qt.question_text
    FROM questions q 
    JOIN subjects s ON q.subject_id = s.id 
    LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
    ORDER BY q.id DESC
")->fetchAll();
?>

<?php if ($message): ?>
    <div style="background:rgba(21, 128, 61, 0.2); color:var(--accent-emerald); padding:1rem; border-radius:var(--radius-sm); margin-bottom:1.5rem; font-weight:600;">
        <?php echo htmlspecialchars($message); ?>
    </div>
<?php endif; ?>

<div class="table-card">
    <div class="table-header">
        <div class="table-title">Question Bank & Multi-Language Repository</div>
        <button class="btn btn-primary" onclick="document.getElementById('import-modal').style.display='block'">Bulk Import Questions (JSON/CSV)</button>
    </div>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Subject</th>
                <th>Question Preview</th>
                <th>Type</th>
                <th>Difficulty</th>
                <th>PYQ Tag</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($questions as $q): ?>
                <tr>
                    <td>#Q-<?php echo $q['id']; ?></td>
                    <td><span class="badge badge-info"><?php echo htmlspecialchars($q['subject_name']); ?></span></td>
                    <td style="max-width:400px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; font-weight:500;">
                        <?php echo htmlspecialchars($q['question_text'] ?? 'No text'); ?>
                    </td>
                    <td><?php echo $q['question_type']; ?></td>
                    <td><span class="badge badge-warning"><?php echo ucfirst($q['difficulty']); ?></span></td>
                    <td><?php echo $q['pyq_year'] ? 'PYQ '.$q['pyq_year'] : 'Mock'; ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>

<!-- Bulk Import Modal -->
<div id="import-modal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); z-index:999; backdrop-filter:blur(5px);">
    <div style="width:600px; margin:5% auto; background:var(--bg-main); border:1px solid var(--border-color); padding:2rem; border-radius:var(--radius-md);">
        <div class="table-title" style="margin-bottom:1rem;">Bulk Import Questions (JSON)</div>
        <form method="POST">
            <input type="hidden" name="bulk_import" value="1">
            <div class="form-group">
                <label class="form-label">Paste JSON Array of Questions</label>
                <textarea name="json_data" class="form-control" rows="8" placeholder='[{"subject_id":1, "question_text":"Sample Question?", "options":{"A":"Opt A", "B":"Opt B"}, "correct_option":"B"}]'></textarea>
            </div>
            <div style="display:flex; justify-end; gap:1rem;">
                <button type="button" class="btn" style="background:var(--bg-card);" onclick="document.getElementById('import-modal').style.display='none'">Cancel</button>
                <button type="submit" class="btn btn-primary">Import Questions</button>
            </div>
        </form>
    </div>
</div>
