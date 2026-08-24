<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$currentAffairs = $db->query("
    SELECT ca.*,
           (SELECT COUNT(*) FROM current_affairs_quizzes WHERE article_id=ca.id) as quiz_count
    FROM current_affairs ca
    ORDER BY ca.publish_date DESC, ca.id DESC
")->fetchAll(PDO::FETCH_ASSOC);

$jobs = $db->query("SELECT * FROM jobs ORDER BY id DESC")->fetchAll(PDO::FETCH_ASSOC);
$toppers = $db->query("SELECT * FROM topper_stories ORDER BY id DESC")->fetchAll(PDO::FETCH_ASSOC);
?>

<div style="display:flex; flex-direction:column; gap:2rem;">

    <!-- Current Affairs CMS -->
    <div class="table-card">
        <div class="table-header" style="display:flex; justify-content:space-between; align-items:center;">
            <div>
                <div class="table-title">🌍 Daily World & National Current Affairs</div>
                <div style="font-size:12px; color:var(--text-secondary); margin-top:2px;">
                    Articles linked to AI Question Generator for students
                </div>
            </div>
            <button class="btn btn-primary" onclick="showAddArticleModal()" style="font-size:12px; padding:6px 14px;">
                + Add Current Affairs Article
            </button>
        </div>

        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Capsule Title</th>
                    <th>Category</th>
                    <th>Exam Relevance</th>
                    <th>AI Quiz Status</th>
                    <th>Publish Date</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($currentAffairs as $ca): ?>
                    <tr id="ca-row-<?php echo $ca['id']; ?>">
                        <td>#CA-<?php echo $ca['id']; ?></td>
                        <td>
                            <div style="font-weight:600; color:#fff; font-size:13px;"><?php echo htmlspecialchars($ca['title']); ?></div>
                            <?php if ($ca['summary']): ?>
                                <div style="font-size:11px; color:var(--text-secondary); margin-top:3px; max-width:400px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
                                    <?php echo htmlspecialchars($ca['summary']); ?>
                                </div>
                            <?php endif; ?>
                        </td>
                        <td><span class="badge badge-info"><?php echo htmlspecialchars($ca['category']); ?></span></td>
                        <td>
                            <span style="font-size:11px; color:var(--accent-blue);">
                                <?php echo htmlspecialchars($ca['exam_relevance'] ?: 'General Awareness'); ?>
                            </span>
                        </td>
                        <td>
                            <?php if ($ca['quiz_count'] > 0): ?>
                                <span class="badge badge-success" style="cursor:pointer;" onclick="viewQuizQuestions(<?php echo $ca['id']; ?>)">
                                    ✓ <?php echo $ca['quiz_count']; ?> AI MCQs
                                </span>
                            <?php else: ?>
                                <button class="btn btn-sm" onclick="generateQuizForArticle(<?php echo $ca['id']; ?>)" style="background:rgba(99,102,241,0.15); color:#818cf8; border:none; padding:4px 8px; border-radius:6px; font-size:11px; cursor:pointer;">
                                    🤖 Generate AI Quiz
                                </button>
                            <?php endif; ?>
                        </td>
                        <td><?php echo $ca['publish_date']; ?></td>
                        <td>
                            <div style="display:flex; gap:6px;">
                                <button class="btn btn-sm" onclick="generateQuizForArticle(<?php echo $ca['id']; ?>)" title="Regenerate AI Quiz" style="background:rgba(255,255,255,0.05); color:#fff; border:none; padding:4px 8px; border-radius:6px; font-size:11px; cursor:pointer;">
                                    ⚡ AI Quiz
                                </button>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <!-- Job Notification Center -->
    <div class="table-card">
        <div class="table-header">
            <div class="table-title">💼 Job Notification Center</div>
        </div>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Job Title</th>
                    <th>Organization</th>
                    <th>Type</th>
                    <th>Vacancies</th>
                    <th>Last Date</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($jobs as $job): ?>
                    <tr>
                        <td>#JOB-<?php echo $job['id']; ?></td>
                        <td style="font-weight:600;"><?php echo htmlspecialchars($job['title']); ?></td>
                        <td><?php echo htmlspecialchars($job['organization_name']); ?></td>
                        <td><span class="badge badge-warning"><?php echo strtoupper($job['job_type']); ?></span></td>
                        <td style="font-weight:700; color:var(--accent-emerald);"><?php echo number_format($job['total_vacancies']); ?></td>
                        <td><?php echo $job['last_date_to_apply']; ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>

<script>
async function generateQuizForArticle(articleId) {
    if (!confirm('Generate 4 AI competitive exam questions based on this article using Gemini AI?')) return;

    showToast('Analyzing article and generating AI quiz questions...', 'success');

    try {
        const res = await fetch(`/EXAMVERSE/api/v1/current-affairs/${articleId}/generate-quiz?force=1`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        const data = await res.json();

        if (data.status === 'success') {
            showToast(`✓ Generated ${data.data?.count || 4} AI questions successfully!`, 'success');
            setTimeout(() => location.reload(), 1200);
        } else {
            showToast('Error: ' + (data.message || 'Generation failed'), 'error');
        }
    } catch (e) {
        showToast('Network error: ' + e.message, 'error');
    }
}

async function viewQuizQuestions(articleId) {
    try {
        const res = await fetch(`/EXAMVERSE/api/v1/current-affairs/${articleId}/quiz`);
        const data = await res.json();
        const questions = data.data || [];
        if (!questions.length) { alert('No questions found'); return; }

        let text = `AI Quiz Questions for Article #${articleId}:\n\n`;
        questions.forEach((q, i) => {
            text += `Q${i+1}: ${q.question_text}\n`;
            text += `A) ${q.option_a}\nB) ${q.option_b}\nC) ${q.option_c}\nD) ${q.option_d}\n`;
            text += `Correct: ${q.correct_option}\n`;
            text += `Explanation: ${q.explanation}\n\n`;
        });
        alert(text);
    } catch (e) {
        alert('Error: ' + e.message);
    }
}

function showToast(msg, type = 'success') {
    const existing = document.getElementById('ev-toast');
    if (existing) existing.remove();
    const t = document.createElement('div');
    t.id = 'ev-toast';
    t.textContent = msg;
    Object.assign(t.style, {
        position: 'fixed', bottom: '28px', right: '28px', zIndex: '9999',
        background: type === 'success' ? 'rgba(34,197,94,0.95)' : 'rgba(239,68,68,0.95)',
        color: 'white', padding: '14px 22px', borderRadius: '12px',
        fontWeight: '600', fontSize: '14px', maxWidth: '420px',
        boxShadow: '0 8px 32px rgba(0,0,0,0.4)'
    });
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 4000);
}
</script>
