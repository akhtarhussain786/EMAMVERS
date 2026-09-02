<?php
/**
 * Admin page: review teacher-submitted questions and manage teacher accounts.
 * Included by index.php, which supplies the session and CSRF-aware fetch wrapper.
 */
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();
$subjects = $db->query("SELECT id, name FROM subjects ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
?>
<style>
    .qr-tabs { display:flex; gap:.5rem; margin-bottom:1.25rem; flex-wrap:wrap; }
    .qr-tab { padding:.5rem 1rem; border-radius:var(--radius-sm); background:rgba(148,163,184,.08);
              border:1px solid rgba(148,163,184,.15); color:var(--text-secondary); cursor:pointer;
              font-size:.85rem; font-weight:600; }
    .qr-tab.active { background:rgba(56,189,248,.15); border-color:rgba(56,189,248,.45); color:var(--accent-blue); }
    .qr-tab .cnt { display:inline-block; margin-left:.4rem; padding:0 .4rem; border-radius:99px;
                   background:rgba(255,255,255,.12); font-size:.72rem; }
    .sub-card { background:var(--bg-card,#151F32); border:1px solid rgba(148,163,184,.15);
                border-radius:var(--radius-md,12px); padding:1.1rem; margin-bottom:1rem; }
    .sub-meta { display:flex; gap:.5rem; flex-wrap:wrap; align-items:center; margin-bottom:.75rem; font-size:.75rem; }
    .pill { padding:.15rem .55rem; border-radius:99px; background:rgba(148,163,184,.12);
            color:var(--text-secondary); font-weight:600; }
    .pill.subj { background:rgba(139,92,246,.15); color:#c4b5fd; }
    .pill.diff { background:rgba(245,158,11,.15); color:#fcd34d; }
    .pill.author { background:rgba(34,197,94,.12); color:#86efac; }
    .q-text { color:#fff; font-size:.95rem; font-weight:600; line-height:1.5; margin-bottom:.85rem; }
    .opt-row { display:flex; gap:.6rem; align-items:flex-start; padding:.45rem .65rem; border-radius:8px;
               margin-bottom:.3rem; background:rgba(148,163,184,.05); font-size:.85rem; color:var(--text-secondary); }
    .opt-row.correct { background:rgba(34,197,94,.12); border:1px solid rgba(34,197,94,.35); color:#bbf7d0; }
    .opt-key { font-weight:800; min-width:1.2rem; }
    .expl { margin-top:.75rem; padding:.65rem .8rem; border-radius:8px; background:rgba(56,189,248,.07);
            border-left:3px solid rgba(56,189,248,.5); font-size:.82rem; color:var(--text-secondary); line-height:1.5; }
    .qr-actions { display:flex; gap:.5rem; margin-top:.9rem; flex-wrap:wrap; }
    .empty { text-align:center; padding:3rem 1rem; color:var(--text-muted); }
    .t-grid { width:100%; border-collapse:collapse; font-size:.85rem; }
    .t-grid th { text-align:left; padding:.6rem; color:var(--text-muted); font-size:.72rem;
                 text-transform:uppercase; letter-spacing:.04em; border-bottom:1px solid rgba(148,163,184,.15); }
    .t-grid td { padding:.65rem .6rem; border-bottom:1px solid rgba(148,163,184,.07); color:var(--text-secondary); }
</style>

<div class="qr-tabs" id="qrTabs">
    <div class="qr-tab active" data-status="review">Awaiting Review <span class="cnt" id="c-review">0</span></div>
    <div class="qr-tab" data-status="published">Approved <span class="cnt" id="c-published">0</span></div>
    <div class="qr-tab" data-status="rejected">Rejected <span class="cnt" id="c-rejected">0</span></div>
    <div class="qr-tab" data-status="__teachers">Teachers</div>
</div>

<div style="margin-bottom:1rem; display:flex; gap:.6rem; align-items:center; flex-wrap:wrap;" id="filterBar">
    <select id="subjFilter" class="form-control" style="max-width:260px;">
        <option value="">All subjects</option>
        <?php foreach ($subjects as $s): ?>
            <option value="<?php echo (int)$s['id']; ?>"><?php echo htmlspecialchars($s['name']); ?></option>
        <?php endforeach; ?>
    </select>
    <button class="btn" onclick="loadSubmissions()">Refresh</button>
</div>

<div id="qrBody"><div class="empty">Loading…</div></div>

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
    body.innerHTML = '<div class="empty">Loading…</div>';
    const subj = document.getElementById('subjFilter').value;
    try {
        const res = await fetch(`${QR_AJAX}?action=list&status=${currentStatus}&subject_id=${subj}`);
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message || 'Failed to load');

        const c = json.data.counts || {};
        document.getElementById('c-review').textContent = c.review ?? 0;
        document.getElementById('c-published').textContent = c.published ?? 0;
        document.getElementById('c-rejected').textContent = c.rejected ?? 0;

        const rows = json.data.submissions || [];
        if (!rows.length) {
            body.innerHTML = `<div class="empty">No questions in this state.</div>`;
            return;
        }
        body.innerHTML = rows.map(renderCard).join('');
    } catch (err) {
        body.innerHTML = `<div class="empty">Could not load submissions: ${esc(err.message)}</div>`;
    }
}

function renderCard(q) {
    const opts = (q.options || []).map(o => `
        <div class="opt-row ${Number(o.is_correct) === 1 ? 'correct' : ''}">
            <span class="opt-key">${esc(o.option_key)}.</span>
            <span>${esc(o.option_text)}</span>
            ${Number(o.is_correct) === 1 ? '<span style="margin-left:auto;font-weight:700;">✓ correct</span>' : ''}
        </div>`).join('');

    const author = q.author_display_name || q.author_name || 'Unknown';
    const track = (q.questions_approved != null)
        ? `${q.questions_approved} approved / ${q.questions_rejected} rejected` : '';

    const actions = q.status === 'review' ? `
        <div class="qr-actions">
            <button class="btn btn-primary" onclick="approve(${q.id})">✓ Approve &amp; Publish</button>
            <button class="btn" style="background:rgba(239,68,68,.15);color:#fca5a5;border:1px solid rgba(239,68,68,.3);"
                    onclick="reject(${q.id})">✗ Reject</button>
        </div>` : '';

    const rejected = q.rejection_reason
        ? `<div class="expl" style="background:rgba(239,68,68,.08);border-left-color:rgba(239,68,68,.5);">
             <strong>Rejected:</strong> ${esc(q.rejection_reason)}</div>` : '';

    return `
    <div class="sub-card" id="qcard-${q.id}">
        <div class="sub-meta">
            <span class="pill subj">${esc(q.subject_name || 'No subject')}</span>
            ${q.topic_name ? `<span class="pill">${esc(q.topic_name)}</span>` : ''}
            <span class="pill diff">${esc(q.difficulty)}</span>
            <span class="pill author">${esc(author)}${track ? ' · ' + esc(track) : ''}</span>
            <span style="margin-left:auto;color:var(--text-muted);">#${q.id} · ${esc((q.created_at || '').slice(0, 16))}</span>
        </div>
        <div class="q-text">${esc(q.question_text || '(no text)')}</div>
        ${opts}
        ${q.explanation ? `<div class="expl"><strong>Explanation:</strong> ${esc(q.explanation)}</div>` : ''}
        ${rejected}
        ${actions}
    </div>`;
}

async function approve(id) {
    if (!confirm('Approve this question? It becomes visible to students immediately.')) return;
    try {
        const res = await fetch(`${QR_AJAX}?action=approve&id=${id}`, {
            method: 'POST', headers: {'Content-Type': 'application/json'}, body: '{}'
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        document.getElementById('qcard-' + id)?.remove();
        loadSubmissions();
    } catch (err) { alert('Could not approve: ' + err.message); }
}

async function reject(id) {
    const reason = prompt('Why is this being rejected? The teacher will see this message.');
    if (reason === null) return;
    if (!reason.trim()) { alert('A reason is required.'); return; }
    try {
        const res = await fetch(`${QR_AJAX}?action=reject&id=${id}`, {
            method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({reason: reason.trim()})
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        document.getElementById('qcard-' + id)?.remove();
        loadSubmissions();
    } catch (err) { alert('Could not reject: ' + err.message); }
}

// ── Teacher accounts ──────────────────────────────────────────────────
async function loadTeachers() {
    const body = document.getElementById('qrBody');
    body.innerHTML = '<div class="empty">Loading…</div>';
    try {
        const res = await fetch(`${QR_AJAX}?action=teachers`);
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);

        const rows = (json.data || []).map(t => `
            <tr>
                <td><strong style="color:#fff;">${esc(t.display_name)}</strong><br>
                    <span style="font-size:.75rem;">${esc(t.email)}</span></td>
                <td>${esc(t.specialisation || '—')}</td>
                <td>${t.questions_submitted}</td>
                <td style="color:#86efac;">${t.questions_approved}</td>
                <td style="color:#fca5a5;">${t.questions_rejected}</td>
                <td><span class="pill">${esc(t.status)}</span></td>
                <td><button class="btn btn-xs" onclick="toggleTeacher(${t.id}, '${t.status === 'active' ? 'suspended' : 'active'}')">
                    ${t.status === 'active' ? 'Suspend' : 'Reactivate'}</button></td>
            </tr>`).join('');

        body.innerHTML = `
            <div class="table-card" style="margin-bottom:1.25rem;">
                <h3 style="color:#fff;font-size:.95rem;margin-bottom:.9rem;">Add a teacher</h3>
                <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:.6rem;">
                    <input id="t_name"  class="form-control" placeholder="Full name">
                    <input id="t_email" class="form-control" placeholder="Email" type="email">
                    <input id="t_pass"  class="form-control" placeholder="Password (min 8)" type="text">
                    <input id="t_spec"  class="form-control" placeholder="Specialisation (e.g. Quantitative Aptitude)">
                </div>
                <button class="btn btn-primary" style="margin-top:.75rem;" onclick="createTeacher()">Create teacher account</button>
            </div>
            <div class="table-card">
                <table class="t-grid">
                    <thead><tr><th>Teacher</th><th>Specialisation</th><th>Submitted</th><th>Approved</th><th>Rejected</th><th>Status</th><th></th></tr></thead>
                    <tbody>${rows || '<tr><td colspan="7" style="text-align:center;padding:2rem;">No teachers yet.</td></tr>'}</tbody>
                </table>
            </div>`;
    } catch (err) {
        body.innerHTML = `<div class="empty">Could not load teachers: ${esc(err.message)}</div>`;
    }
}

async function createTeacher() {
    const payload = {
        full_name: document.getElementById('t_name').value.trim(),
        email:     document.getElementById('t_email').value.trim(),
        password:  document.getElementById('t_pass').value,
        specialisation: document.getElementById('t_spec').value.trim(),
    };
    try {
        const res = await fetch(`${QR_AJAX}?action=create_teacher`, {
            method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(payload)
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        alert(json.message);
        loadTeachers();
    } catch (err) { alert('Could not create teacher: ' + err.message); }
}

async function toggleTeacher(id, status) {
    try {
        const res = await fetch(`${QR_AJAX}?action=teacher_status&id=${id}`, {
            method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({status})
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        loadTeachers();
    } catch (err) { alert('Could not update: ' + err.message); }
}

loadSubmissions();
</script>
