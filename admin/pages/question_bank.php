<?php
/**
 * Admin page: question bank health per department, and top-up targets.
 * This is the screen that answers "how full is each department's bank?".
 */
?>
<style>
  .bank-stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(170px,1fr)); gap:1rem; margin-bottom:1.5rem; }
  .bstat { background:var(--bg-card,#151F32); border:1px solid rgba(148,163,184,.15);
           border-radius:var(--radius-md,12px); padding:1.1rem; }
  .bstat .n { font-size:1.75rem; font-weight:800; color:#fff; line-height:1; }
  .bstat .l { font-size:.75rem; color:var(--text-muted); margin-top:.4rem; }
  .bank-table { width:100%; border-collapse:collapse; font-size:.85rem; }
  .bank-table th { text-align:left; padding:.6rem; color:var(--text-muted); font-size:.7rem;
                   text-transform:uppercase; letter-spacing:.04em; border-bottom:1px solid rgba(148,163,184,.15); }
  .bank-table td { padding:.55rem .6rem; border-bottom:1px solid rgba(148,163,184,.07); color:var(--text-secondary); }
  .meter { height:7px; border-radius:99px; background:rgba(148,163,184,.15); overflow:hidden; min-width:110px; }
  .meter span { display:block; height:100%; border-radius:99px; }
  .ok   { background:#22C55E; } .warn { background:#F59E0B; } .low { background:#EF4444; }
  .dpill { padding:.1rem .5rem; border-radius:99px; font-size:.7rem; font-weight:700; }
  .d-easy{background:rgba(34,197,94,.15);color:#86efac;} .d-medium{background:rgba(245,158,11,.15);color:#fcd34d;}
  .d-hard{background:rgba(239,68,68,.15);color:#fca5a5;}
  .runs td { font-size:.78rem; }
</style>

<div class="bank-stats" id="bankStats"></div>

<div class="table-card" style="margin-bottom:1.5rem;">
  <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:.6rem;margin-bottom:.9rem;">
    <h3 style="color:#fff;font-size:.95rem;margin:0;">Bank depth by department</h3>
    <select id="examFilter" class="form-control" style="max-width:260px;"><option value="">All departments</option></select>
  </div>
  <div style="overflow-x:auto;"><table class="bank-table" id="levelsTable"></table></div>
</div>

<div class="table-card" style="margin-bottom:1.5rem;">
  <h3 style="color:#fff;font-size:.95rem;margin-bottom:.9rem;">Set a target</h3>
  <p style="color:var(--text-muted);font-size:.8rem;margin-bottom:.8rem;">
    The nightly job tops up any bucket below its target. A target of 150 means 150 easy + 150 medium + 150 hard per subject.
  </p>
  <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:.6rem;">
    <select id="tExam" class="form-control"></select>
    <select id="tSubject" class="form-control"></select>
    <input id="tTarget" class="form-control" type="number" min="0" max="5000" placeholder="Target per difficulty" value="150">
    <label style="display:flex;align-items:center;gap:.5rem;color:var(--text-secondary);font-size:.82rem;">
      <input id="tAuto" type="checkbox" checked> Auto top-up
    </label>
  </div>
  <button class="btn btn-primary" style="margin-top:.75rem;" onclick="saveTarget()">Save target</button>
</div>

<div class="table-card">
  <h3 style="color:#fff;font-size:.95rem;margin-bottom:.9rem;">Recent top-up runs</h3>
  <div style="overflow-x:auto;"><table class="bank-table runs" id="runsTable"></table></div>
  <p style="color:var(--text-muted);font-size:.78rem;margin-top:.9rem;">
    Runs are started by cron:
    <code style="color:#93c5fd;">0 2 * * * php <?php echo htmlspecialchars(realpath(__DIR__ . '/../../api/jobs/topup_questions.php'), ENT_QUOTES); ?></code>
  </p>
</div>

<script>
const QB = '/EXAMVERSE/admin/ajax/question_bank.php';
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]));}

async function loadMeta() {
  const r = await (await fetch(`${QB}?action=meta`)).json();
  if (r.status !== 'success') return;
  const exams = r.data.exams.map(e => `<option value="${e.id}">${esc(e.title)}</option>`).join('');
  document.getElementById('examFilter').innerHTML = '<option value="">All departments</option>' + exams;
  document.getElementById('tExam').innerHTML = exams;
  document.getElementById('tSubject').innerHTML = r.data.subjects.map(s => `<option value="${s.id}">${esc(s.name)}</option>`).join('');
}

async function loadLevels() {
  const examId = document.getElementById('examFilter').value;
  const body = document.getElementById('levelsTable');
  body.innerHTML = '<tr><td>Loading…</td></tr>';
  try {
    const r = await (await fetch(`${QB}?action=levels&exam_id=${examId}`)).json();
    if (r.status !== 'success') throw new Error(r.message);
    const t = r.data.totals;

    document.getElementById('bankStats').innerHTML = `
      <div class="bstat"><div class="n">${t.published}</div><div class="l">Published questions</div></div>
      <div class="bstat"><div class="n" style="color:#fcd34d;">${t.awaiting_review}</div><div class="l">Awaiting review</div></div>
      <div class="bstat"><div class="n" style="color:#86efac;">${t.from_teachers}</div><div class="l">From teachers</div></div>
      <div class="bstat"><div class="n" style="color:#93c5fd;">${t.bank_links}</div><div class="l">Department placements</div></div>`;

    const rows = r.data.levels;
    if (!rows.length) { body.innerHTML = '<tr><td style="padding:2rem;text-align:center;">No targets set yet — add one below.</td></tr>'; }
    else {
      body.innerHTML = `<thead><tr><th>Department</th><th>Subject</th><th>Difficulty</th><th>Have</th><th>Target</th><th style="min-width:130px;">Fill</th><th>Auto</th><th>Action</th></tr></thead><tbody>` +
        rows.map(l => {
          const pct = l.target_per_difficulty > 0 ? Math.min(100, Math.round(l.current_total / l.target_per_difficulty * 100)) : 100;
          const cls = pct >= 90 ? 'ok' : pct >= 50 ? 'warn' : 'low';
          return `<tr>
            <td>${esc(l.exam_title)}</td>
            <td>${esc(l.subject_name)}</td>
            <td><span class="dpill d-${esc(l.difficulty)}">${esc(l.difficulty)}</span></td>
            <td style="color:#fff;font-weight:700;">${l.current_total}</td>
            <td>${l.target_per_difficulty}</td>
            <td><div class="meter"><span class="${cls}" style="width:${pct}%"></span></div>
                <span style="font-size:.7rem;color:var(--text-muted);">${pct}%</span></td>
            <td>${Number(l.auto_topup) ? '✓' : '—'}</td>
            <td><button class="btn btn-xs" id="fill-${l.exam_id}-${l.subject_id}-${esc(l.difficulty)}"
                  onclick="fillBucket(${l.exam_id}, ${l.subject_id}, '${esc(l.difficulty)}')"
                  ${pct >= 100 ? 'disabled style="opacity:.4;cursor:default;"' : ''}>Fill now</button></td>
          </tr>`;
        }).join('') + '</tbody>';
    }

    renderRuns(r.data.recent_runs || []);
  } catch (e) {
    body.innerHTML = `<tr><td style="padding:2rem;">Could not load: ${esc(e.message)}</td></tr>`;
  }
}

/** Kicks off a background top-up for one bucket and polls until it settles. */
async function fillBucket(examId, subjectId, difficulty) {
  const btn = document.getElementById(`fill-${examId}-${subjectId}-${difficulty}`);
  const howMany = prompt('How many questions to generate for this bucket?', '10');
  if (howMany === null) return;
  const limit = parseInt(howMany, 10);
  if (!Number.isFinite(limit) || limit < 1 || limit > 50) { alert('Enter a number between 1 and 50.'); return; }

  if (btn) { btn.disabled = true; btn.textContent = 'Starting…'; }
  try {
    const r = await (await fetch(`${QB}?action=fill_bucket`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({exam_id: examId, subject_id: subjectId, difficulty, limit})
    })).json();
    if (r.status !== 'success') throw new Error(r.message);
    if (btn) btn.textContent = 'Generating…';
    pollRuns(btn);
  } catch (e) {
    alert('Could not start: ' + e.message);
    if (btn) { btn.disabled = false; btn.textContent = 'Fill now'; }
  }
}

/** Generation takes minutes, so poll the run table rather than blocking. */
let pollTimer = null;
async function pollRuns(btn) {
  clearInterval(pollTimer);
  let ticks = 0;
  pollTimer = setInterval(async () => {
    ticks++;
    try {
      const r = await (await fetch(`${QB}?action=run_status`)).json();
      if (r.status !== 'success') return;
      renderRuns(r.data);
      const active = r.data.some(x => x.status === 'running');
      if (!active || ticks > 60) {
        clearInterval(pollTimer);
        if (btn) { btn.disabled = false; btn.textContent = 'Fill now'; }
        loadLevels();
      }
    } catch (_) { /* transient; keep polling */ }
  }, 5000);
}

function renderRuns(runs) {
  document.getElementById('runsTable').innerHTML = runs.length
    ? `<thead><tr><th>When</th><th>Department</th><th>Subject</th><th>Diff</th><th>Generated</th><th>Dupes</th><th>Inserted</th><th>Status</th></tr></thead><tbody>` +
      runs.map(x => {
        const colour = x.status === 'completed' ? '#86efac' : x.status === 'error' ? '#fca5a5' : '#fcd34d';
        return `<tr>
          <td>${esc((x.started_at||'').slice(0,16))}</td>
          <td>${esc(x.exam_title||'—')}</td><td>${esc(x.subject_name||'—')}</td>
          <td>${esc(x.difficulty||'—')}</td><td>${x.generated_count}</td>
          <td style="color:#fcd34d;">${x.duplicates_rejected}</td>
          <td style="color:#86efac;font-weight:700;">${x.inserted}</td>
          <td style="color:${colour};">${esc(x.status)}${x.error_message ? ' — ' + esc(x.error_message.slice(0,44)) : ''}</td>
        </tr>`;
      }).join('') + '</tbody>'
    : '<tr><td style="padding:1.5rem;text-align:center;">No top-up runs yet.</td></tr>';
}

async function saveTarget() {
  const payload = {
    exam_id: document.getElementById('tExam').value,
    subject_id: document.getElementById('tSubject').value,
    target_per_difficulty: document.getElementById('tTarget').value,
    auto_topup: document.getElementById('tAuto').checked,
  };
  try {
    const r = await (await fetch(`${QB}?action=set_target`, {
      method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload)
    })).json();
    if (r.status !== 'success') throw new Error(r.message);
    loadLevels();
  } catch (e) { alert('Could not save: ' + e.message); }
}

document.getElementById('examFilter').addEventListener('change', loadLevels);
loadMeta().then(loadLevels);
</script>
