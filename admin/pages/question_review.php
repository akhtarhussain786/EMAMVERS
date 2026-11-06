<?php
require_once __DIR__ . '/../includes/page_guard.php';
/**
 * Admin page: Teacher Questions Approval & Review Center
 */
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();
$subjects = $db->query("SELECT id, name FROM subjects ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
?>
<style>
    .qr-tabs { display:flex; gap:.5rem; margin-bottom:1.25rem; flex-wrap:wrap; }
    .qr-tab { padding:.5rem 1rem; border-radius:var(--radius-sm); background:rgba(148,163,184,.08);
              border:1px solid rgba(148,163,184,.15); color:var(--text-secondary); cursor:pointer;
              font-size:.85rem; font-weight:600; display:flex; align-items:center; }
    .qr-tab.active { background:rgba(56,189,248,.15); border-color:rgba(56,189,248,.45); color:var(--accent-blue); }
    .qr-tab .cnt { display:inline-block; margin-left:.5rem; padding:1px 6px; border-radius:99px;
                   background:rgba(255,255,255,.12); font-size:.72rem; }

    .sub-card { background:var(--bg-card); border:1px solid rgba(148,163,184,.15);
                border-radius:var(--radius-md,12px); padding:1.25rem; margin-bottom:1.1rem; }
    .sub-meta { display:flex; gap:.5rem; flex-wrap:wrap; align-items:center; margin-bottom:.85rem; font-size:.78rem; }
    .pill { padding:.15rem .55rem; border-radius:99px; background:rgba(148,163,184,.12);
            color:var(--text-secondary); font-weight:600; }
    .pill.subj { background:rgba(139,92,246,.15); color:#c4b5fd; }
    .pill.diff { background:rgba(245,158,11,.15); color:#fcd34d; }
    .pill.author { background:rgba(21,128,61,.12); color:#86efac; }
    .pill.date { background:rgba(148,163,184,.1); color:var(--text-muted); }

    .q-text { color:#fff; font-size:.95rem; font-weight:600; line-height:1.5; margin-bottom:.85rem; }
    .opt-row { display:flex; gap:.6rem; align-items:flex-start; padding:.45rem .65rem; border-radius:8px;
               margin-bottom:.3rem; background:rgba(148,163,184,.05); font-size:.85rem; color:var(--text-secondary); }
    .opt-row.correct { background:rgba(21,128,61,.12); border:1px solid rgba(21,128,61,.35); color:#bbf7d0; font-weight:600; }
    .opt-key { font-weight:800; min-width:1.2rem; }

    .expl { margin-top:.75rem; padding:.65rem .8rem; border-radius:8px; background:rgba(56,189,248,.07);
            border-left:3px solid rgba(56,189,248,.5); font-size:.82rem; color:var(--text-secondary); line-height:1.5; }
    .feedback-box { margin-top:.75rem; padding:.65rem .8rem; border-radius:8px; background:rgba(239,68,68,.08);
                    border-left:3px solid rgba(239,68,68,.6); font-size:.82rem; color:#fca5a5; line-height:1.5; }

    .qr-actions { display:flex; gap:.5rem; margin-top:1rem; flex-wrap:wrap; border-top:1px solid rgba(148,163,184,.1); padding-top:.85rem; }
    .empty { text-align:center; padding:3rem 1rem; color:var(--text-muted); }
    .q-img { max-height:140px; max-width:240px; border-radius:6px; border:1px solid rgba(148,163,184,.2); margin-bottom:.85rem; display:block; }
</style>

<div class="qr-tabs" id="qrTabs">
    <div class="qr-tab active" data-status="review">Awaiting Review <span class="cnt" id="c-review">0</span></div>
    <div class="qr-tab" data-status="changes_requested">Changes Requested <span class="cnt" id="c-changes_requested">0</span></div>
    <div class="qr-tab" data-status="published">Approved (Live) <span class="cnt" id="c-published">0</span></div>
    <div class="qr-tab" data-status="rejected">Rejected <span class="cnt" id="c-rejected">0</span></div>
    <div class="qr-tab" data-status="__teachers">Registered Faculty</div>
</div>

<div style="margin-bottom:1.25rem; display:flex; gap:.6rem; align-items:center; flex-wrap:wrap;" id="filterBar">
    <select id="subjFilter" class="form-control" style="max-width:260px;" onchange="loadSubmissions()">
        <option value="">All subjects</option>
        <?php foreach ($subjects as $s): ?>
            <option value="<?php echo (int)$s['id']; ?>"><?php echo htmlspecialchars($s['name']); ?></option>
        <?php endforeach; ?>
    </select>
    <button class="btn" onclick="loadSubmissions()">↻ Refresh Queue</button>
</div>

<div id="qrBody"><div class="empty">Loading submissions...</div></div>

<script>
const QR_AJAX = '/EXAMVERSE/admin/ajax/question_review.php';
let currentStatus = 'review';

function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g,
        c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]));
}

document.getElementById('qrTabs').addEventListener('click', e => {
    const tab = e.target.closest('.qr-tab');
    if (!tab) return;
    document.querySelectorAll('.qr-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    currentStatus = tab.dataset.status;
    document.getElementById('filterBar').style.display = currentStatus === '__teachers' ? 'none' : 'flex';
    currentStatus === '__teachers' ? loadTeachers() : loadSubmissions();
});

async function loadSubmissions() {
    const body = document.getElementById('qrBody');
    body.innerHTML = '<div class="empty">Loading submissions...</div>';
    const subj = document.getElementById('subjFilter').value;
    try {
        const res = await fetch(`${QR_AJAX}?action=list&status=${currentStatus}&subject_id=${subj}`);
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message || 'Failed to load');

        const c = json.data.counts || {};
        document.getElementById('c-review').textContent = c.review ?? 0;
        document.getElementById('c-changes_requested').textContent = c.changes_requested ?? 0;
        document.getElementById('c-published').textContent = c.published ?? 0;
        document.getElementById('c-rejected').textContent = c.rejected ?? 0;

        const rows = json.data.submissions || [];
        if (!rows.length) {
            body.innerHTML = `<div class="empty">No questions currently in this state.</div>`;
            return;
        }
        body.innerHTML = rows.map(renderCard).join('');
    } catch (err) {
        body.innerHTML = `<div class="empty" style="color:var(--accent-rose);">${esc(err.message)}</div>`;
    }
}

function renderCard(q) {
    const opts = (q.options || []).map(o => {
        const isCorr = o.is_correct == 1 || o.is_correct === true;
        return `
            <div class="opt-row ${isCorr ? 'correct' : ''}">
                <span class="opt-key">${esc(o.option_key)}.</span>
                <span style="flex:1;">${esc(o.option_text)}</span>
                ${isCorr ? '<span style="color:#22c55e; font-weight:700;">✓ Correct</span>' : ''}
            </div>
        `;
    }).join('');

    const imgHtml = q.image_url ? `<a href="${esc(q.image_url)}" target="_blank"><img src="${esc(q.image_url)}" class="q-img" alt="Attached Diagram"></a>` : '';

    let actions = '';
    if (q.status === 'review' || q.status === 'changes_requested') {
        actions = `
            <button class="btn btn-primary" style="padding:.45rem .85rem;" onclick="approveQuestion(${q.id})">✓ Approve & Publish</button>
            <button class="btn" style="background:rgba(168,85,247,.15); color:#d8b4fe;" onclick="promptChanges(${q.id})">✎ Request Changes</button>
            <button class="btn" style="background:rgba(239,68,68,.12); color:#fca5a5;" onclick="promptReject(${q.id})">✕ Reject</button>
        `;
    } else if (q.status === 'published') {
        actions = `
            <button class="btn" style="background:rgba(239,68,68,.15); color:#fca5a5;" onclick="unpublishQuestion(${q.id})">⊘ Unpublish (Take Down)</button>
        `;
    } else if (q.status === 'rejected') {
        actions = `
            <button class="btn btn-primary" style="padding:.45rem .85rem;" onclick="approveQuestion(${q.id})">✓ Re-Approve & Publish</button>
        `;
    }

    const feedbackHtml = (q.admin_comment || q.rejection_reason) ? `
        <div class="feedback-box">
            <strong>Admin Feedback / Instructions:</strong> ${esc(q.admin_comment || q.rejection_reason)}
        </div>
    ` : '';

    return `
        <div class="sub-card" id="card-${q.id}">
            <div class="sub-meta">
                <span class="pill" style="font-weight:700; color:#fff;">#Q-${q.id}</span>
                <span class="pill author">👨‍🏫 ${esc(q.author_display_name || q.author_name || 'Faculty')}</span>
                <span class="pill subj">📚 ${esc(q.subject_name || 'Subject')} ${q.chapter_name ? ' &rsaquo; ' + esc(q.chapter_name) : ''}</span>
                ${q.topic_name ? `<span class="pill">Topic: ${esc(q.topic_name)}</span>` : ''}
                <span class="pill diff">Difficulty: ${esc(q.difficulty)}</span>
                <span class="pill date">Submitted: ${esc(q.created_at)}</span>
            </div>

            <div class="q-text">${esc(q.question_text || '(No question text)')}</div>
            ${imgHtml}

            <div style="margin-bottom:.75rem;">${opts}</div>

            ${q.explanation ? `<div class="expl"><strong>Explanation / Solution:</strong> ${esc(q.explanation)}</div>` : ''}
            ${feedbackHtml}

            <div class="qr-actions">${actions}</div>
        </div>
    `;
}

async function approveQuestion(id) {
    if (!confirm(`Are you sure you want to approve Question #${id}? It will be immediately published to students.`)) return;

    try {
        const res = await fetch(`${QR_AJAX}?action=approve&id=${id}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || ''
            },
            body: JSON.stringify({})
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        loadSubmissions();
    } catch (e) {
        alert('Approval failed: ' + e.message);
    }
}

async function promptChanges(id) {
    const comment = prompt('Enter mandatory revision instructions / feedback for the teacher:');
    if (comment === null) return;
    if (!comment.trim()) {
        alert('Feedback instructions are required when requesting changes.');
        return;
    }

    try {
        const res = await fetch(`${QR_AJAX}?action=request_changes&id=${id}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || ''
            },
            body: JSON.stringify({ comment: comment.trim() })
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        loadSubmissions();
    } catch (e) {
        alert('Failed to request changes: ' + e.message);
    }
}

async function promptReject(id) {
    const reason = prompt('Enter mandatory rejection reason:');
    if (reason === null) return;
    if (!reason.trim()) {
        alert('Rejection reason is required.');
        return;
    }

    try {
        const res = await fetch(`${QR_AJAX}?action=reject&id=${id}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || ''
            },
            body: JSON.stringify({ reason: reason.trim() })
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        loadSubmissions();
    } catch (e) {
        alert('Rejection failed: ' + e.message);
    }
}

async function unpublishQuestion(id) {
    if (!confirm(`Unpublish Question #${id}? This will immediately hide it from students in all exams and practice tests.`)) return;

    try {
        const res = await fetch(`${QR_AJAX}?action=unpublish&id=${id}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || ''
            },
            body: JSON.stringify({})
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        loadSubmissions();
    } catch (e) {
        alert('Unpublish failed: ' + e.message);
    }
}

async function loadTeachers() {
    const body = document.getElementById('qrBody');
    body.innerHTML = '<div class="empty">Loading faculty accounts...</div>';
    try {
        const res = await fetch(`${QR_AJAX}?action=teachers`);
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);

        const rows = json.data || [];
        if (!rows.length) {
            body.innerHTML = `<div class="empty">No registered teachers found.</div>`;
            return;
        }

        body.innerHTML = `
            <div class="table-card">
                <table style="width:100%; border-collapse:collapse; font-size:.85rem;">
                    <thead>
                        <tr style="border-bottom:1px solid rgba(148,163,184,.15); text-align:left; color:var(--text-muted); font-size:.72rem;">
                            <th style="padding:.6rem;">Teacher</th>
                            <th style="padding:.6rem;">Email</th>
                            <th style="padding:.6rem;">Specialization</th>
                            <th style="padding:.6rem; text-align:center;">Submitted</th>
                            <th style="padding:.6rem; text-align:center;">Approved</th>
                            <th style="padding:.6rem; text-align:center;">Rejected</th>
                            <th style="padding:.6rem;">Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${rows.map(t => `
                            <tr style="border-bottom:1px solid rgba(148,163,184,.07); color:var(--text-secondary);">
                                <td style="padding:.65rem .6rem; font-weight:600; color:#fff;">${esc(t.display_name || t.full_name)}</td>
                                <td style="padding:.65rem .6rem;">${esc(t.email)}</td>
                                <td style="padding:.65rem .6rem;">${esc(t.specialisation || t.qualification || '-')}</td>
                                <td style="padding:.65rem .6rem; text-align:center; font-weight:700; color:#fff;">${t.questions_submitted}</td>
                                <td style="padding:.65rem .6rem; text-align:center; font-weight:700; color:#86efac;">${t.questions_approved}</td>
                                <td style="padding:.65rem .6rem; text-align:center; font-weight:700; color:#fca5a5;">${t.questions_rejected}</td>
                                <td style="padding:.65rem .6rem;">
                                    <span class="pill" style="background:${t.status==='active'?'rgba(34,197,94,.15)':'rgba(239,68,68,.15)'}; color:${t.status==='active'?'#86efac':'#fca5a5'};">
                                        ${esc(t.status)}
                                    </span>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
    } catch (e) {
        body.innerHTML = `<div class="empty" style="color:var(--accent-rose);">${esc(e.message)}</div>`;
    }
}

window.addEventListener('DOMContentLoaded', loadSubmissions);
</script>
