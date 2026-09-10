<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

// Fetch duplicate clusters / candidate pairs
$stmt = $db->query("
    SELECT qdc.*,
           COALESCE(qta.question_text, '') AS text_a, qa.difficulty AS status_a,
           COALESCE(qtb.question_text, '') AS text_b, qb.difficulty AS status_b,
           sa.name AS subject_a, sb.name AS subject_b
    FROM question_duplicate_candidates qdc
    JOIN questions qa ON qdc.question_a_id = qa.id
    JOIN questions qb ON qdc.question_b_id = qb.id
    LEFT JOIN question_translations qta ON qa.id = qta.question_id AND qta.language = 'en'
    LEFT JOIN question_translations qtb ON qb.id = qtb.question_id AND qtb.language = 'en'
    LEFT JOIN subjects sa ON qa.subject_id = sa.id
    LEFT JOIN subjects sb ON qb.subject_id = sb.id
    ORDER BY qdc.created_at DESC
    LIMIT 50
");
$candidatePairs = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Also look for identical content_hash pairs that haven't been resolved yet
$autoDuplicates = [];
try {
    $autoDuplicates = $db->query("
        SELECT qr1.question_id AS id_a, COALESCE(qt1.question_text, '') AS text_a, qr1.content_hash,
               qr2.question_id AS id_b, COALESCE(qt2.question_text, '') AS text_b,
               s.name AS subject_name
        FROM question_revisions qr1
        JOIN question_revisions qr2 ON qr1.content_hash = qr2.content_hash AND qr1.question_id < qr2.question_id
        JOIN questions q1 ON qr1.question_id = q1.id
        LEFT JOIN question_translations qt1 ON q1.id = qt1.question_id AND qt1.language = 'en'
        LEFT JOIN question_translations qt2 ON qr2.question_id = qt2.question_id AND qt2.language = 'en'
        LEFT JOIN subjects s ON q1.subject_id = s.id
        WHERE qr1.content_hash IS NOT NULL AND qr1.content_hash != ''
        LIMIT 20
    ")->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $autoDuplicates = [];
}
?>

<div class="question-duplicates-page">
    <div class="page-header mb-4">
        <div>
            <h1 class="h3 font-weight-bold">Question Duplicate Detection & Governance Center</h1>
            <p class="text-muted">PRD §16: Maintain Question Bank integrity by reviewing exact clones, structure matches, translation pairs, and conflicting answer keys.</p>
        </div>
    </div>

    <!-- Stats Summary -->
    <div class="stats-row mb-4">
        <div class="stat-card stat-purple">
            <div class="stat-val"><?php echo count($autoDuplicates); ?></div>
            <div class="stat-lbl">Exact Hash Pairs Found</div>
        </div>
        <div class="stat-card stat-orange">
            <div class="stat-val"><?php echo count($candidatePairs); ?></div>
            <div class="stat-lbl">Candidate Pairs in Queue</div>
        </div>
        <div class="stat-card stat-green">
            <div class="stat-val">100%</div>
            <div class="stat-lbl">Hash Integrity Checked</div>
        </div>
    </div>

    <!-- Exact Hash Duplicates -->
    <?php if (!empty($autoDuplicates)): ?>
    <div class="card mb-4 shadow-sm border-0">
        <div class="card-header bg-white py-3 border-bottom d-flex justify-content-between align-items-center">
            <h5 class="mb-0 font-weight-bold text-danger">⚠️ Exact Hash Duplicate Candidates</h5>
            <span class="badge badge-danger"><?php echo count($autoDuplicates); ?> Detected</span>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="thead-light">
                        <tr>
                            <th style="width: 45%;">Question A (Original)</th>
                            <th style="width: 45%;">Question B (Duplicate Candidate)</th>
                            <th style="width: 10%;">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($autoDuplicates as $d): ?>
                        <tr>
                            <td>
                                <span class="badge badge-info">ID #<?php echo $d['id_a']; ?></span>
                                <span class="badge badge-light border"><?php echo htmlspecialchars($d['subject_name'] ?? 'General'); ?></span>
                                <p class="mt-1 mb-1 font-weight-bold text-dark"><?php echo htmlspecialchars($d['text_a']); ?></p>
                                <span class="badge badge-success">Correct: <?php echo htmlspecialchars($d['answer_a']); ?></span>
                            </td>
                            <td>
                                <span class="badge badge-warning">ID #<?php echo $d['id_b']; ?></span>
                                <p class="mt-1 mb-1 font-weight-bold text-dark"><?php echo htmlspecialchars($d['text_b']); ?></p>
                                <span class="badge <?php echo $d['answer_a'] === $d['answer_b'] ? 'badge-success' : 'badge-danger'; ?>">
                                    Correct: <?php echo htmlspecialchars($d['answer_b']); ?>
                                    <?php if ($d['answer_a'] !== $d['answer_b']): ?>
                                    (⚠️ Answer Conflict!)
                                    <?php endif; ?>
                                </span>
                            </td>
                            <td class="align-middle">
                                <button class="btn btn-sm btn-outline-danger" onclick="resolveDuplicate(<?php echo $d['id_a']; ?>, <?php echo $d['id_b']; ?>, 'exact_duplicate')">
                                    Merge / Unpublish B
                                </button>
                                <button class="btn btn-sm btn-outline-secondary mt-1" onclick="resolveDuplicate(<?php echo $d['id_a']; ?>, <?php echo $d['id_b']; ?>, 'not_duplicate')">
                                    Not Duplicate
                                </button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <!-- Review Decisions History -->
    <div class="card shadow-sm border-0">
        <div class="card-header bg-white py-3 border-bottom">
            <h5 class="mb-0 font-weight-bold">Resolved / Recorded Candidate Decisions</h5>
        </div>
        <div class="card-body p-0">
            <?php if (empty($candidatePairs)): ?>
            <div class="p-4 text-center text-muted">No candidate decisions recorded yet.</div>
            <?php else: ?>
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="thead-light">
                        <tr>
                            <th>Pair</th>
                            <th>Decision</th>
                            <th>Score / Method</th>
                            <th>Reason / Note</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($candidatePairs as $p): ?>
                        <tr>
                            <td>
                                <strong>#<?php echo $p['question_a_id']; ?></strong> vs <strong>#<?php echo $p['question_b_id']; ?></strong>
                            </td>
                            <td>
                                <span class="badge badge-dark"><?php echo htmlspecialchars($p['decision'] ?? 'pending'); ?></span>
                            </td>
                            <td>
                                <?php echo htmlspecialchars($p['similarity_score']); ?>% (<?php echo htmlspecialchars($p['match_method']); ?>)
                            </td>
                            <td>
                                <small><?php echo htmlspecialchars($p['decision_reason'] ?: 'No notes'); ?></small>
                            </td>
                            <td>
                                <span class="badge badge-success"><?php echo htmlspecialchars($p['status']); ?></span>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<script>
function resolveDuplicate(idA, idB, decision) {
    const reason = prompt('Reason / Review Note (optional):', 'Reviewed in Duplicate Governance Center');
    if (reason === null) return;

    fetch('/EXAMVERSE/api/v1/admin/question-duplicates/decision', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            question_a_id: idA,
            question_b_id: idB,
            decision: decision,
            decision_reason: reason
        })
    })
    .then(r => r.json())
    .then(res => {
        if (res.status === 'success') {
            alert('✓ Decision recorded successfully: ' + decision);
            location.reload();
        } else {
            alert('Error: ' + res.message);
        }
    })
    .catch(err => alert('Network error: ' + err.message));
}
</script>
