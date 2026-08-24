<?php
// Connect to DB
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

// Load exams and subjects for dropdowns
$exams = $db->query("SELECT id, title FROM exams WHERE status='active' ORDER BY title")->fetchAll(PDO::FETCH_ASSOC);
$subjects = $db->query("SELECT id, name FROM subjects ORDER BY name")->fetchAll(PDO::FETCH_ASSOC);

// Load saved API keys
$aiKeys = $db->query("SELECT id, label, provider, is_active, usage_count, last_used_at, created_at,
                      CONCAT(SUBSTR(api_key_encrypted,1,8),'••••••••••••••',SUBSTR(api_key_encrypted,-4)) as masked_key
                      FROM ai_api_keys ORDER BY created_at DESC")->fetchAll(PDO::FETCH_ASSOC);

// Recent batches
$batches = $db->query("SELECT aqb.*, e.title as exam_title, s.name as subject_name
                        FROM ai_question_batches aqb
                        LEFT JOIN exams e ON aqb.exam_id=e.id
                        LEFT JOIN subjects s ON aqb.subject_id=s.id
                        ORDER BY aqb.created_at DESC LIMIT 10")->fetchAll(PDO::FETCH_ASSOC);
?>

<div class="ai-gen-page">

    <!-- ═══ TOP: API KEY MANAGER ═══ -->
    <div class="ai-section">
        <div class="ai-section-header">
            <div>
                <h2 class="ai-title">🔑 API Key Manager</h2>
                <p class="ai-subtitle">Securely store your Gemini or OpenAI API key. Only the active key is used for generation.</p>
            </div>
        </div>

        <!-- Saved Keys -->
        <?php if ($aiKeys): ?>
        <div class="keys-grid">
            <?php foreach ($aiKeys as $k): ?>
            <div class="key-card <?php echo $k['is_active'] ? 'key-active' : ''; ?>">
                <div class="key-card-top">
                    <span class="provider-badge provider-<?php echo $k['provider']; ?>"><?php echo strtoupper($k['provider']); ?></span>
                    <span class="key-status-dot <?php echo $k['is_active'] ? 'dot-active' : 'dot-inactive'; ?>"></span>
                </div>
                <div class="key-label"><?php echo htmlspecialchars($k['label']); ?></div>
                <div class="key-masked"><?php echo htmlspecialchars($k['masked_key']); ?></div>
                <div class="key-meta">
                    Used <?php echo $k['usage_count']; ?>x &nbsp;·&nbsp;
                    <?php echo $k['last_used_at'] ? date('d M', strtotime($k['last_used_at'])) : 'Never used'; ?>
                </div>
                <div class="key-actions">
                    <?php if (!$k['is_active']): ?>
                    <button class="btn-xs btn-activate" onclick="toggleKey(<?php echo $k['id']; ?>)">Activate</button>
                    <?php else: ?>
                    <span class="badge-active-tag">✓ Active</span>
                    <?php endif; ?>
                    <button class="btn-xs btn-danger-xs" onclick="deleteKey(<?php echo $k['id']; ?>)">Delete</button>
                </div>
            </div>
            <?php endforeach; ?>
        </div>
        <?php else: ?>
        <div class="empty-keys-hint">No API keys added yet. Add one below to start generating questions with AI.</div>
        <?php endif; ?>

        <!-- Add New Key Form -->
        <div class="add-key-form">
            <h3 class="form-sub-title">Add New API Key</h3>
            <div class="form-row-3">
                <div class="form-group">
                    <label>Label (e.g. "My Gemini Key")</label>
                    <input type="text" id="keyLabel" placeholder="Gemini Primary" class="form-input">
                </div>
                <div class="form-group">
                    <label>Provider</label>
                    <select id="keyProvider" class="form-input">
                        <option value="gemini">Google Gemini</option>
                        <option value="openai">OpenAI GPT-4o</option>
                    </select>
                </div>
                <div class="form-group" style="flex:2">
                    <label>API Key</label>
                    <input type="password" id="keyValue" placeholder="AIza... or sk-..." class="form-input">
                </div>
            </div>
            <button class="btn-primary-ai" onclick="saveKey()">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="16"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
                Save & Activate Key
            </button>
        </div>
    </div>

    <!-- ═══ BOTTOM: QUESTION GENERATOR ═══ -->
    <div class="ai-section" id="gen-section">
        <div class="ai-section-header">
            <div>
                <h2 class="ai-title">⚡ AI Question Generator</h2>
                <p class="ai-subtitle">Configure parameters → Generate → Review → Approve to Question Bank</p>
            </div>
        </div>

        <!-- Config Form -->
        <div class="gen-form">
            <div class="form-row-3">
                <div class="form-group">
                    <label>Exam</label>
                    <select id="genExam" class="form-input">
                        <option value="">-- Any Exam --</option>
                        <?php foreach ($exams as $e): ?>
                        <option value="<?php echo $e['id']; ?>"><?php echo htmlspecialchars($e['title']); ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label>Subject</label>
                    <select id="genSubject" class="form-input">
                        <option value="">-- Any Subject --</option>
                        <?php foreach ($subjects as $s): ?>
                        <option value="<?php echo $s['id']; ?>"><?php echo htmlspecialchars($s['name']); ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="form-group">
                    <label>Section / Topic</label>
                    <input type="text" id="genSection" placeholder="e.g. Profit & Loss, History" class="form-input">
                </div>
            </div>
            <div class="form-row-3">
                <div class="form-group">
                    <label>Difficulty</label>
                    <select id="genDifficulty" class="form-input">
                        <option value="easy">Easy</option>
                        <option value="medium" selected>Medium</option>
                        <option value="hard">Hard</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Number of Questions (max 30)</label>
                    <input type="number" id="genCount" value="5" min="1" max="30" class="form-input">
                </div>
                <div class="form-group">
                    <label>Language</label>
                    <select id="genLang" class="form-input">
                        <option value="en">English</option>
                        <option value="hi">Hindi</option>
                    </select>
                </div>
            </div>
            <button class="btn-primary-ai btn-generate" id="genBtn" onclick="generateQuestions()">
                <svg id="genSpinner" class="spin hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24" width="18"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
                <span id="genBtnText">🤖 Generate Questions with AI</span>
            </button>
        </div>

        <!-- Results area -->
        <div id="genResults" class="gen-results hidden">
            <div class="results-header">
                <h3 class="results-title" id="resultsTitle">Generated Questions</h3>
                <div class="results-actions">
                    <button class="btn-sm btn-approve-all" onclick="approveAll()">✓ Approve All</button>
                    <button class="btn-sm btn-reject-all" onclick="rejectAll()">✗ Reject All</button>
                    <button class="btn-sm btn-save-approved" onclick="saveApproved()">💾 Save Approved to Bank</button>
                </div>
            </div>
            <div id="qList" class="q-list"></div>
        </div>

        <!-- Recent Batches -->
        <?php if ($batches): ?>
        <div class="batches-section">
            <h3 class="form-sub-title">Recent Generation History</h3>
            <div class="table-wrap">
                <table class="admin-table">
                    <thead><tr><th>Exam</th><th>Subject</th><th>Difficulty</th><th>Requested</th><th>Generated</th><th>Approved</th><th>Status</th><th>Date</th></tr></thead>
                    <tbody>
                    <?php foreach ($batches as $b): ?>
                    <tr>
                        <td><?php echo htmlspecialchars($b['exam_title'] ?? '—'); ?></td>
                        <td><?php echo htmlspecialchars($b['subject_name'] ?? $b['section_name']); ?></td>
                        <td><span class="badge badge-<?php echo $b['difficulty']; ?>"><?php echo $b['difficulty']; ?></span></td>
                        <td><?php echo $b['count_requested']; ?></td>
                        <td><?php echo $b['count_generated']; ?></td>
                        <td><?php echo $b['count_approved']; ?></td>
                        <td><span class="badge badge-<?php echo $b['status'] === 'completed' ? 'success' : ($b['status'] === 'error' ? 'danger' : 'warning'); ?>"><?php echo $b['status']; ?></span></td>
                        <td><?php echo date('d M H:i', strtotime($b['created_at'])); ?></td>
                    </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
        <?php endif; ?>
    </div>
</div>

<style>
:root { --accent: #6366f1; }
.ai-gen-page { display: flex; flex-direction: column; gap: 24px; }
.ai-section {
    background: var(--card-bg, #1e1e2e);
    border: 1px solid var(--border, rgba(255,255,255,0.08));
    border-radius: 16px;
    padding: 28px;
}
.ai-section-header { margin-bottom: 20px; }
.ai-title { font-size: 18px; font-weight: 700; margin: 0 0 4px; }
.ai-subtitle { color: var(--text-secondary, rgba(255,255,255,0.5)); font-size: 13px; margin: 0; }
.keys-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 16px; margin-bottom: 24px; }
.key-card {
    background: rgba(255,255,255,0.04);
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 12px; padding: 16px;
    transition: border-color 0.2s;
}
.key-card.key-active { border-color: #6366f1; box-shadow: 0 0 0 1px rgba(99,102,241,0.3); }
.key-card-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.provider-badge { padding: 2px 8px; border-radius: 6px; font-size: 10px; font-weight: 700; }
.provider-gemini { background: linear-gradient(135deg,#4285f4,#34a853); color: white; }
.provider-openai { background: linear-gradient(135deg,#10a37f,#1a7f64); color: white; }
.key-status-dot { width: 8px; height: 8px; border-radius: 50%; }
.dot-active { background: #22c55e; box-shadow: 0 0 6px #22c55e; }
.dot-inactive { background: rgba(255,255,255,0.2); }
.key-label { font-weight: 600; font-size: 14px; margin-bottom: 4px; }
.key-masked { font-family: monospace; font-size: 12px; color: rgba(255,255,255,0.4); margin-bottom: 6px; }
.key-meta { font-size: 11px; color: rgba(255,255,255,0.3); margin-bottom: 12px; }
.key-actions { display: flex; gap: 8px; align-items: center; }
.btn-xs { padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: 600; cursor: pointer; border: none; }
.btn-activate { background: rgba(99,102,241,0.15); color: #818cf8; }
.btn-activate:hover { background: rgba(99,102,241,0.3); }
.btn-danger-xs { background: rgba(239,68,68,0.1); color: #f87171; }
.btn-danger-xs:hover { background: rgba(239,68,68,0.2); }
.badge-active-tag { font-size: 11px; color: #22c55e; font-weight: 600; }
.empty-keys-hint { padding: 16px; background: rgba(255,255,255,0.03); border-radius: 10px; color: rgba(255,255,255,0.4); font-size: 13px; text-align: center; margin-bottom: 20px; }
.add-key-form { background: rgba(255,255,255,0.03); border-radius: 12px; padding: 20px; margin-top: 8px; }
.form-sub-title { font-size: 14px; font-weight: 600; margin: 0 0 16px; color: rgba(255,255,255,0.7); }
.form-row-3 { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 14px; margin-bottom: 16px; }
.form-group label { display: block; font-size: 11px; font-weight: 600; color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
.form-input { width: 100%; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); border-radius: 8px; padding: 9px 12px; color: white; font-size: 13px; box-sizing: border-box; }
.form-input:focus { outline: none; border-color: #6366f1; }
.form-input option { background: #1e1e2e; }
.btn-primary-ai {
    display: inline-flex; align-items: center; gap: 8px;
    background: linear-gradient(135deg, #6366f1, #a855f7);
    color: white; border: none; border-radius: 10px;
    padding: 10px 22px; font-size: 14px; font-weight: 600;
    cursor: pointer; transition: opacity 0.2s;
}
.btn-primary-ai:hover { opacity: 0.85; }
.btn-generate { padding: 13px 32px; font-size: 15px; width: 100%; justify-content: center; margin-top: 4px; }
.gen-form { margin-bottom: 8px; }
.gen-results { margin-top: 24px; border-top: 1px solid rgba(255,255,255,0.07); padding-top: 20px; }
.results-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; flex-wrap: wrap; gap: 10px; }
.results-title { font-size: 16px; font-weight: 700; margin: 0; }
.results-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.btn-sm { padding: 7px 14px; border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; border: none; }
.btn-approve-all { background: rgba(34,197,94,0.15); color: #4ade80; }
.btn-reject-all  { background: rgba(239,68,68,0.1); color: #f87171; }
.btn-save-approved { background: linear-gradient(135deg,#6366f1,#a855f7); color: white; }
.q-list { display: flex; flex-direction: column; gap: 16px; }
.q-card {
    background: rgba(255,255,255,0.04);
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 12px; padding: 18px;
    transition: border-color 0.2s;
}
.q-card.approved { border-color: #22c55e; }
.q-card.rejected { border-color: #ef4444; opacity: 0.5; }
.q-card-header { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 12px; }
.q-num { font-size: 11px; font-weight: 700; color: #818cf8; background: rgba(99,102,241,0.1); padding: 3px 8px; border-radius: 5px; white-space: nowrap; }
.q-text { font-size: 14px; font-weight: 500; line-height: 1.5; }
.q-options { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin: 12px 0; }
.q-option { padding: 8px 12px; border-radius: 8px; font-size: 13px; background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.06); }
.q-option.correct { background: rgba(34,197,94,0.1); border-color: #22c55e; color: #4ade80; }
.q-explanation { font-size: 12px; color: rgba(255,255,255,0.5); background: rgba(255,255,255,0.03); border-radius: 8px; padding: 10px 12px; margin-bottom: 12px; line-height: 1.5; }
.q-footer { display: flex; gap: 8px; justify-content: flex-end; }
.hidden { display: none !important; }
.spin { animation: spin 1s linear infinite; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
.batches-section { margin-top: 28px; border-top: 1px solid rgba(255,255,255,0.06); padding-top: 20px; }
.table-wrap { overflow-x: auto; }
.admin-table { width: 100%; border-collapse: collapse; font-size: 13px; }
.admin-table th { padding: 10px 12px; text-align: left; font-size: 11px; font-weight: 600; color: rgba(255,255,255,0.4); text-transform: uppercase; border-bottom: 1px solid rgba(255,255,255,0.06); }
.admin-table td { padding: 10px 12px; border-bottom: 1px solid rgba(255,255,255,0.04); color: rgba(255,255,255,0.75); }
.badge { padding: 3px 8px; border-radius: 5px; font-size: 11px; font-weight: 600; }
.badge-easy    { background: rgba(34,197,94,0.15); color: #4ade80; }
.badge-medium  { background: rgba(251,191,36,0.15); color: #fbbf24; }
.badge-hard    { background: rgba(239,68,68,0.12); color: #f87171; }
.badge-success { background: rgba(34,197,94,0.15); color: #4ade80; }
.badge-warning { background: rgba(251,191,36,0.15); color: #fbbf24; }
.badge-danger  { background: rgba(239,68,68,0.12); color: #f87171; }
</style>

<script>
// ─── All calls go to /admin/ajax/ (session-authenticated, no token needed) ───
const AJAX_KEYS = '/EXAMVERSE/admin/ajax/ai_keys.php';
const AJAX_GEN  = '/EXAMVERSE/admin/ajax/ai_generate.php';
let generatedData = [];
let currentBatchId = null;

// ── API KEY MANAGEMENT ────────────────────────────────────────────────────────

async function saveKey() {
    const label    = document.getElementById('keyLabel').value.trim();
    const provider = document.getElementById('keyProvider').value;
    const apiKey   = document.getElementById('keyValue').value.trim();
    if (!label)   { showToast('Please enter a label', 'error');  return; }
    if (!apiKey)  { showToast('Please paste your API key', 'error'); return; }

    const btn = event.target;
    btn.disabled = true;
    btn.textContent = 'Saving...';

    try {
        const res  = await fetch(`${AJAX_KEYS}?action=save`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ label, provider, api_key: apiKey })
        });
        const data = await res.json();
        if (data.status === 'success') {
            showToast(data.message, 'success');
            setTimeout(() => location.reload(), 1000);
        } else {
            showToast('Error: ' + (data.message || 'Failed to save key'), 'error');
        }
    } catch(e) {
        showToast('Network error: ' + e.message, 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = 'Save & Activate Key';
    }
}

async function deleteKey(id) {
    if (!confirm('Delete this API key permanently?')) return;
    const res  = await fetch(`${AJAX_KEYS}?action=delete&id=${id}`);
    const data = await res.json();
    if (data.status === 'success') { showToast('Key deleted', 'success'); setTimeout(() => location.reload(), 700); }
    else showToast(data.message, 'error');
}

async function toggleKey(id) {
    const res  = await fetch(`${AJAX_KEYS}?action=toggle&id=${id}`);
    const data = await res.json();
    if (data.status === 'success') { showToast(data.message, 'success'); setTimeout(() => location.reload(), 700); }
    else showToast(data.message, 'error');
}

// ── AI QUESTION GENERATION ────────────────────────────────────────────────────

async function generateQuestions() {
    const btn     = document.getElementById('genBtn');
    const spinner = document.getElementById('genSpinner');
    const btnText = document.getElementById('genBtnText');

    btn.disabled = true;
    spinner.classList.remove('hidden');
    btnText.textContent = 'Generating... Please wait (up to 30s)';

    const payload = {
        exam_id:      parseInt(document.getElementById('genExam').value)    || 0,
        subject_id:   parseInt(document.getElementById('genSubject').value) || 0,
        section_name: document.getElementById('genSection').value.trim()   || 'General',
        difficulty:   document.getElementById('genDifficulty').value,
        count:        parseInt(document.getElementById('genCount').value)   || 5,
        language:     document.getElementById('genLang').value
    };

    try {
        const res  = await fetch(`${AJAX_GEN}?action=generate`, {
            method:  'POST',
            headers: { 'Content-Type': 'application/json' },
            body:    JSON.stringify(payload)
        });
        const data = await res.json();

        if (data.status !== 'success') {
            showToast('❌ ' + (data.message || 'Generation failed'), 'error');
            return;
        }

        generatedData  = data.data.questions || [];
        currentBatchId = data.data.batch_id;

        renderQuestions(generatedData);
        document.getElementById('resultsTitle').textContent =
            `Generated ${generatedData.length} Questions via ${data.data.provider?.toUpperCase()} (Batch #${currentBatchId})`;
        document.getElementById('genResults').classList.remove('hidden');
        document.getElementById('genResults').scrollIntoView({ behavior: 'smooth' });
        showToast(`✓ ${generatedData.length} questions ready for review!`, 'success');

    } catch(e) {
        showToast('Error: ' + e.message, 'error');
    } finally {
        btn.disabled = false;
        spinner.classList.add('hidden');
        btnText.textContent = '🤖 Generate Questions with AI';
    }
}

function renderQuestions(questions) {
    const list = document.getElementById('qList');
    list.innerHTML = '';
    questions.forEach((q, i) => {
        const opts = ['A','B','C','D'];
        const optHtml = opts.map(k => {
            const isCorrect = (q.correct_option || '').toUpperCase() === k;
            return `<div class="q-option ${isCorrect ? 'correct' : ''}"><strong>${k}.</strong> ${escHtml(q['option_'+k.toLowerCase()] || '')}</div>`;
        }).join('');

        list.innerHTML += `
        <div class="q-card" id="qcard-${i}" data-idx="${i}" data-status="pending">
            <div class="q-card-header">
                <span class="q-num">Q${i+1}</span>
                <div class="q-footer">
                    <button class="btn-xs btn-activate" onclick="setStatus(${i},'approved')">✓ Approve</button>
                    <button class="btn-xs btn-danger-xs" onclick="setStatus(${i},'rejected')">✗ Reject</button>
                </div>
            </div>
            <div class="q-text">${escHtml(q.question_text || '')}</div>
            <div class="q-options">${optHtml}</div>
            <div class="q-explanation">💡 ${escHtml(q.explanation || 'No explanation provided')}</div>
        </div>`;
    });
}

function setStatus(idx, status) {
    const card = document.getElementById('qcard-'+idx);
    card.dataset.status = status;
    card.className = 'q-card ' + status;
}
function approveAll() { document.querySelectorAll('.q-card').forEach(c => { c.dataset.status='approved'; c.className='q-card approved'; }); }
function rejectAll()  { document.querySelectorAll('.q-card').forEach(c => { c.dataset.status='rejected'; c.className='q-card rejected'; }); }

async function saveApproved() {
    const cards      = document.querySelectorAll('.q-card');
    const approvedIds = [], rejectedIds = [];
    cards.forEach(c => {
        const idx = parseInt(c.dataset.idx);
        const id  = generatedData[idx]?.id;
        if (!id) return;
        if (c.dataset.status === 'approved')  approvedIds.push(id);
        else if (c.dataset.status === 'rejected') rejectedIds.push(id);
    });

    if (!approvedIds.length && !rejectedIds.length) {
        showToast('Please approve or reject at least one question first', 'error');
        return;
    }

    const res  = await fetch(`${AJAX_GEN}?action=approve`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ approved_ids: approvedIds, rejected_ids: rejectedIds })
    });
    const data = await res.json();
    if (data.status === 'success') {
        showToast(`✅ ${data.data?.saved || 0} questions added to Question Bank!`, 'success');
        document.getElementById('genResults').classList.add('hidden');
        setTimeout(() => location.reload(), 1200);
    } else {
        showToast('Error: ' + data.message, 'error');
    }
}

// ── TOAST NOTIFICATION ────────────────────────────────────────────────────────
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
        fontWeight: '600', fontSize: '14px', maxWidth: '380px',
        boxShadow: '0 8px 32px rgba(0,0,0,0.4)',
        transition: 'all 0.3s', animation: 'slideUp 0.3s ease'
    });
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 4000);
}

function escHtml(str) {
    return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// Add slideUp animation
const style = document.createElement('style');
style.textContent = '@keyframes slideUp { from { transform:translateY(20px); opacity:0; } to { transform:translateY(0); opacity:1; } }';
document.head.appendChild(style);
</script>
