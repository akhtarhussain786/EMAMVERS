<?php
require_once __DIR__ . '/../includes/page_guard.php';
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();
?>
<style>
    .qm-stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(160px,1fr)); gap:1rem; margin-bottom:1.5rem; }
    .qm-stat { background:var(--bg-card); border:1px solid rgba(148,163,184,.15); border-radius:var(--radius-md,12px); padding:1rem; }
    .qm-stat .num { font-size:1.6rem; font-weight:800; color:#fff; line-height:1; }
    .qm-stat .lbl { font-size:.75rem; color:var(--text-muted); margin-top:.35rem; }

    .qm-filters { display:flex; gap:.6rem; flex-wrap:wrap; align-items:center; margin-bottom:1.25rem; }
    .qm-filters .form-control { max-width:200px; }

    .q-pill { padding:.15rem .55rem; border-radius:99px; font-size:.7rem; font-weight:700; text-transform:uppercase; letter-spacing:.03em; }
    .q-published { background:rgba(34,197,94,.15); color:#86efac; border:1px solid rgba(34,197,94,.3); }
    .q-draft { background:rgba(148,163,184,.15); color:#cbd5e1; border:1px solid rgba(148,163,184,.3); }
    .q-review { background:rgba(245,158,11,.15); color:#fcd34d; border:1px solid rgba(245,158,11,.3); }
    .q-changes_requested { background:rgba(168,85,247,.15); color:#d8b4fe; border:1px solid rgba(168,85,247,.3); }
    .q-rejected { background:rgba(239,68,68,.15); color:#fca5a5; border:1px solid rgba(239,68,68,.3); }

    .d-easy { background:rgba(34,197,94,.12); color:#86efac; }
    .d-medium { background:rgba(245,158,11,.12); color:#fcd34d; }
    .d-hard { background:rgba(239,68,68,.12); color:#fca5a5; }

    .creator-tag { display:inline-flex; align-items:center; gap:4px; font-size:.72rem; padding:2px 6px; border-radius:4px; }
    .c-admin { background:rgba(56,189,248,.12); color:#38bdf8; }
    .c-teacher { background:rgba(168,85,247,.12); color:#c084fc; }

    .q-table { width:100%; border-collapse:collapse; font-size:.85rem; }
    .q-table th { text-align:left; padding:.65rem .6rem; color:var(--text-muted); font-size:.7rem; text-transform:uppercase; letter-spacing:.04em; border-bottom:1px solid rgba(148,163,184,.15); }
    .q-table td { padding:.65rem .6rem; border-bottom:1px solid rgba(148,163,184,.07); color:var(--text-secondary); vertical-align:middle; }
    .q-table tr:hover { background:rgba(255,255,255,.02); }

    /* Modal styling */
    .modal-overlay { display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.75); z-index:999; backdrop-filter:blur(5px); overflow-y:auto; padding:20px; }
    .modal-box { width:100%; max-width:850px; margin:2rem auto; background:var(--bg-main, #0f172a); border:1px solid rgba(148,163,184,.25); padding:1.75rem; border-radius:var(--radius-md,12px); box-shadow:0 20px 40px rgba(0,0,0,.5); }
    .modal-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:1.25rem; padding-bottom:.75rem; border-bottom:1px solid rgba(148,163,184,.15); }
    .modal-title { font-size:1.15rem; font-weight:700; color:#fff; }
    .modal-close { background:transparent; border:none; color:var(--text-muted); font-size:1.5rem; cursor:pointer; line-height:1; }
    .modal-close:hover { color:#fff; }

    .grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:1rem; }
    .grid-3 { display:grid; grid-template-columns:1fr 1fr 1fr; gap:1rem; }
    .grid-4 { display:grid; grid-template-columns:repeat(4, 1fr); gap:.8rem; }
    @media(max-width:768px) { .grid-2, .grid-3, .grid-4 { grid-template-columns:1fr; } }

    .opt-box { background:rgba(148,163,184,.05); border:1px solid rgba(148,163,184,.15); border-radius:8px; padding:.75rem; margin-bottom:.5rem; }
    .opt-box.selected { border-color:#22c55e; background:rgba(34,197,94,.06); }
    .opt-head { display:flex; align-items:center; justify-content:space-between; margin-bottom:.4rem; font-size:.8rem; font-weight:700; color:#fff; }

    .img-preview { max-width:180px; max-height:120px; object-fit:contain; border-radius:6px; border:1px solid rgba(148,163,184,.2); margin-top:.5rem; display:none; }
</style>

<!-- Stat Cards -->
<div class="qm-stats" id="qmStats">
    <div class="qm-stat"><div class="num" id="st-total">0</div><div class="lbl">Total Questions</div></div>
    <div class="qm-stat"><div class="num" style="color:#86efac;" id="st-pub">0</div><div class="lbl">Published (Active in App)</div></div>
    <div class="qm-stat"><div class="num" style="color:#cbd5e1;" id="st-draft">0</div><div class="lbl">Drafts</div></div>
    <div class="qm-stat"><div class="num" style="color:#fcd34d;" id="st-rev">0</div><div class="lbl">Awaiting Review</div></div>
    <div class="qm-stat"><div class="num" style="color:#d8b4fe;" id="st-req">0</div><div class="lbl">Changes Requested</div></div>
</div>

<div class="table-card">
    <div class="table-header" style="flex-wrap:wrap; gap:1rem; align-items:center;">
        <div>
            <div class="table-title">Question Management System</div>
            <div style="font-size:.78rem; color:var(--text-muted); margin-top:2px;">
                Create, manage, categorize and publish questions for students across all test modes.
            </div>
        </div>
        <div style="display:flex; gap:.6rem; flex-wrap:wrap;">
            <button class="btn btn-primary" onclick="openCreateModal()">+ Add New Question</button>
            <button class="btn" style="background:rgba(148,163,184,.12); color:#fff;" onclick="openBulkModal()">Bulk Import (JSON)</button>
        </div>
    </div>

    <!-- Filters Bar -->
    <div class="qm-filters" style="padding-top:.5rem;">
        <input type="text" id="fSearch" class="form-control" placeholder="Search questions..." style="min-width:220px;" oninput="debounceLoad()">
        <select id="fSubject" class="form-control" onchange="onFilterSubjectChange()"><option value="">All Subjects</option></select>
        <select id="fChapter" class="form-control" onchange="loadQuestions()"><option value="">All Chapters</option></select>
        <select id="fCategory" class="form-control" onchange="loadQuestions()"><option value="">All Categories</option></select>
        <select id="fType" class="form-control" onchange="loadQuestions()">
            <option value="">All Types</option>
            <option value="MCQ">MCQ</option>
            <option value="TRUE_FALSE">True / False</option>
            <option value="DESCRIPTIVE">Descriptive</option>
            <option value="NUMERICAL">Numerical</option>
        </select>
        <select id="fDifficulty" class="form-control" onchange="loadQuestions()">
            <option value="">All Difficulties</option>
            <option value="easy">Easy</option>
            <option value="medium">Medium</option>
            <option value="hard">Hard</option>
        </select>
        <select id="fStatus" class="form-control" onchange="loadQuestions()">
            <option value="">All Statuses</option>
            <option value="published">Published</option>
            <option value="draft">Draft</option>
            <option value="review">Review (Pending)</option>
            <option value="changes_requested">Changes Requested</option>
            <option value="rejected">Rejected</option>
        </select>
        <select id="fAuthor" class="form-control" onchange="loadQuestions()">
            <option value="">All Creators</option>
            <option value="admin">Admin Created</option>
            <option value="teacher">Teacher Submitted</option>
        </select>
        <button class="btn" style="padding:.5rem .75rem;" onclick="resetFilters()">Reset</button>
    </div>

    <!-- Table Container -->
    <div style="overflow-x:auto;">
        <table class="q-table" id="questionsTable">
            <thead>
                <tr>
                    <th style="width:70px;">ID</th>
                    <th>Question</th>
                    <th style="width:130px;">Subject / Chapter</th>
                    <th style="width:90px;">Type</th>
                    <th style="width:85px;">Difficulty</th>
                    <th style="width:90px;">Marks</th>
                    <th style="width:110px;">Creator</th>
                    <th style="width:105px;">Status</th>
                    <th style="width:140px; text-align:right;">Actions</th>
                </tr>
            </thead>
            <tbody id="questionsBody">
                <tr><td colspan="9" style="text-align:center; padding:3rem 1rem; color:var(--text-muted);">Loading questions...</td></tr>
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    <div style="display:flex; justify-content:space-between; align-items:center; margin-top:1.25rem; font-size:.85rem; color:var(--text-muted); flex-wrap:wrap; gap:.5rem;">
        <div id="pageInfo">Showing 0 of 0 questions</div>
        <div style="display:flex; gap:.4rem;" id="pageNav"></div>
    </div>
</div>

<!-- ================= ADD / EDIT QUESTION MODAL ================= -->
<div class="modal-overlay" id="questionModal">
    <div class="modal-box">
        <div class="modal-header">
            <div class="modal-title" id="modalTitle">Add New Question</div>
            <button class="modal-close" onclick="closeQuestionModal()">&times;</button>
        </div>
        <form id="questionForm" onsubmit="saveQuestion(event)">
            <input type="hidden" id="qId" value="0">
            <input type="hidden" id="qImageUrl" value="">

            <!-- Category, Subject, Chapter, Topic Cascading -->
            <div class="grid-2" style="margin-bottom:1rem;">
                <div class="form-group">
                    <label class="form-label">Subject *</label>
                    <select id="mSubject" class="form-control" required onchange="onModalSubjectChange()">
                        <option value="">Select Subject</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Exam / Category</label>
                    <select id="mExam" class="form-control">
                        <option value="">Select Exam Category</option>
                    </select>
                </div>
            </div>

            <div class="grid-2" style="margin-bottom:1rem;">
                <div class="form-group">
                    <label class="form-label">Chapter</label>
                    <select id="mChapter" class="form-control" onchange="onModalChapterChange()">
                        <option value="">Select Chapter (Optional)</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Topic</label>
                    <select id="mTopic" class="form-control">
                        <option value="">Select Topic (Optional)</option>
                    </select>
                </div>
            </div>

            <!-- Type, Difficulty, Marks -->
            <div class="grid-4" style="margin-bottom:1rem;">
                <div class="form-group">
                    <label class="form-label">Question Type *</label>
                    <select id="mType" class="form-control" onchange="onTypeChange()">
                        <option value="MCQ">MCQ (4 Options)</option>
                        <option value="TRUE_FALSE">True / False</option>
                        <option value="DESCRIPTIVE">Descriptive</option>
                        <option value="NUMERICAL">Numerical</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Difficulty *</label>
                    <select id="mDifficulty" class="form-control">
                        <option value="easy">Easy</option>
                        <option value="medium" selected>Medium</option>
                        <option value="hard">Hard</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Marks *</label>
                    <input type="number" step="0.25" min="0" max="100" id="mMarks" class="form-control" value="2.00" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Negative Marks</label>
                    <input type="number" step="0.25" min="0" max="100" id="mNegativeMarks" class="form-control" value="0.50">
                </div>
            </div>

            <!-- Question Text -->
            <div class="form-group" style="margin-bottom:1rem;">
                <label class="form-label">Question Text *</label>
                <textarea id="mQuestionText" class="form-control" rows="3" placeholder="Enter the complete question..." required></textarea>
            </div>

            <!-- Optional Image Upload -->
            <div class="form-group" style="margin-bottom:1rem; background:rgba(148,163,184,.04); padding:.8rem; border-radius:8px; border:1px dashed rgba(148,163,184,.2);">
                <label class="form-label" style="display:flex; justify-content:space-between; align-items:center;">
                    <span>Optional Question Image (Diagram, Graph, Equation)</span>
                    <button type="button" id="btnRemoveImg" class="btn btn-sm" style="display:none; color:var(--accent-rose); padding:0 5px;" onclick="removeImage()">Remove Image</button>
                </label>
                <input type="file" id="mImageFile" class="form-control" accept="image/*" onchange="handleImageUpload(event)">
                <img id="imgPreview" class="img-preview" alt="Question Preview">
            </div>

            <!-- MCQ / True-False Options Container -->
            <div id="optionsContainer" style="margin-bottom:1rem;">
                <label class="form-label" style="display:flex; justify-content:space-between;">
                    <span>Answer Options</span>
                    <span style="font-size:.75rem; color:#86efac;">● Mark the radio button for the correct answer</span>
                </label>

                <!-- MCQ Options (A, B, C, D) -->
                <div id="mcqOptions">
                    <div class="opt-box" id="optBoxA">
                        <div class="opt-head">
                            <span>Option A</span>
                            <label style="cursor:pointer; font-weight:normal; display:flex; align-items:center; gap:5px;">
                                <input type="radio" name="correct_opt" value="A" checked onchange="highlightCorrectOpt('A')"> Correct Answer
                            </label>
                        </div>
                        <input type="text" id="optA" class="form-control" placeholder="Option A text..." required>
                    </div>

                    <div class="opt-box" id="optBoxB">
                        <div class="opt-head">
                            <span>Option B</span>
                            <label style="cursor:pointer; font-weight:normal; display:flex; align-items:center; gap:5px;">
                                <input type="radio" name="correct_opt" value="B" onchange="highlightCorrectOpt('B')"> Correct Answer
                            </label>
                        </div>
                        <input type="text" id="optB" class="form-control" placeholder="Option B text..." required>
                    </div>

                    <div class="opt-box" id="optBoxC">
                        <div class="opt-head">
                            <span>Option C</span>
                            <label style="cursor:pointer; font-weight:normal; display:flex; align-items:center; gap:5px;">
                                <input type="radio" name="correct_opt" value="C" onchange="highlightCorrectOpt('C')"> Correct Answer
                            </label>
                        </div>
                        <input type="text" id="optC" class="form-control" placeholder="Option C text..." required>
                    </div>

                    <div class="opt-box" id="optBoxD">
                        <div class="opt-head">
                            <span>Option D</span>
                            <label style="cursor:pointer; font-weight:normal; display:flex; align-items:center; gap:5px;">
                                <input type="radio" name="correct_opt" value="D" onchange="highlightCorrectOpt('D')"> Correct Answer
                            </label>
                        </div>
                        <input type="text" id="optD" class="form-control" placeholder="Option D text..." required>
                    </div>
                </div>

                <!-- True / False Options -->
                <div id="tfOptions" style="display:none;">
                    <div class="grid-2">
                        <div class="opt-box" id="optBoxTrue">
                            <label style="display:flex; align-items:center; gap:8px; cursor:pointer; color:#fff; font-weight:600;">
                                <input type="radio" name="correct_opt_tf" value="A" checked> True
                            </label>
                        </div>
                        <div class="opt-box" id="optBoxFalse">
                            <label style="display:flex; align-items:center; gap:8px; cursor:pointer; color:#fff; font-weight:600;">
                                <input type="radio" name="correct_opt_tf" value="B"> False
                            </label>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Explanation / Solution -->
            <div class="form-group" style="margin-bottom:1.5rem;">
                <label class="form-label">Explanation / Solution (Visible to students after test completion)</label>
                <textarea id="mExplanation" class="form-control" rows="2" placeholder="Detailed step-by-step solution and explanation..."></textarea>
            </div>

            <!-- Footer Buttons -->
            <div style="display:flex; justify-content:flex-end; gap:.75rem; border-top:1px solid rgba(148,163,184,.15); padding-top:1rem;">
                <button type="button" class="btn" onclick="closeQuestionModal()">Cancel</button>
                <button type="button" class="btn" style="background:rgba(148,163,184,.15); color:#fff;" onclick="submitSave('draft')">Save as Draft</button>
                <button type="button" class="btn btn-primary" onclick="submitSave('published')">Publish & Activate</button>
            </div>
        </form>
    </div>
</div>

<!-- ================= BULK IMPORT MODAL ================= -->
<div class="modal-overlay" id="bulkModal">
    <div class="modal-box" style="max-width:650px;">
        <div class="modal-header">
            <div class="modal-title">Bulk Import Questions (JSON)</div>
            <button class="modal-close" onclick="closeBulkModal()">&times;</button>
        </div>
        <form method="POST">
            <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars(adminCsrfToken(), ENT_QUOTES); ?>">
            <input type="hidden" name="bulk_import" value="1">
            <div class="form-group" style="margin-bottom:1rem;">
                <label class="form-label">Paste JSON Array</label>
                <textarea name="json_data" class="form-control" rows="8" placeholder='[{"subject_id":1, "question_text":"What is the capital of India?", "options":{"A":"Mumbai", "B":"New Delhi", "C":"Kolkata", "D":"Chennai"}, "correct_option":"B"}]'></textarea>
            </div>
            <div style="display:flex; justify-content:flex-end; gap:.75rem;">
                <button type="button" class="btn" onclick="closeBulkModal()">Cancel</button>
                <button type="submit" class="btn btn-primary">Import Questions</button>
            </div>
        </form>
    </div>
</div>

<script>
const QA = '/EXAMVERSE/admin/ajax/questions.php';
let taxonomy = { categories: [], exams: [], subjects: [], chapters: [], topics: [] };
let currentPage = 1;
let searchTimer = null;

function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g,
        c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]));
}

async function init() {
    await loadTaxonomy();
    await loadQuestions();
}

async function loadTaxonomy() {
    try {
        const res = await fetch(`${QA}?action=taxonomy`);
        const json = await res.json();
        if (json.status === 'success') {
            taxonomy = json.data;
            populateTaxonomyDropdowns();
        }
    } catch (e) {
        console.error('Failed to load taxonomy:', e);
    }
}

function populateTaxonomyDropdowns() {
    // Filter subject dropdown
    const fSubj = document.getElementById('fSubject');
    fSubj.innerHTML = '<option value="">All Subjects</option>' +
        taxonomy.subjects.map(s => `<option value="${s.id}">${esc(s.name)}</option>`).join('');

    // Filter categories
    const fCat = document.getElementById('fCategory');
    fCat.innerHTML = '<option value="">All Categories</option>' +
        taxonomy.categories.map(c => `<option value="${c.id}">${esc(c.name)}</option>`).join('');

    // Modal subjects
    const mSubj = document.getElementById('mSubject');
    mSubj.innerHTML = '<option value="">Select Subject</option>' +
        taxonomy.subjects.map(s => `<option value="${s.id}">${esc(s.name)}</option>`).join('');

    // Modal exams
    const mExam = document.getElementById('mExam');
    mExam.innerHTML = '<option value="">Select Exam Category</option>' +
        taxonomy.exams.map(e => `<option value="${e.id}">${esc(e.title)}</option>`).join('');
}

function onFilterSubjectChange() {
    const sid = parseInt(document.getElementById('fSubject').value) || 0;
    const fChap = document.getElementById('fChapter');
    const filteredChapters = sid ? taxonomy.chapters.filter(c => c.subject_id === sid) : taxonomy.chapters;
    fChap.innerHTML = '<option value="">All Chapters</option>' +
        filteredChapters.map(c => `<option value="${c.id}">${esc(c.name)}</option>`).join('');
    loadQuestions();
}

function onModalSubjectChange() {
    const sid = parseInt(document.getElementById('mSubject').value) || 0;
    const mChap = document.getElementById('mChapter');
    const filtered = taxonomy.chapters.filter(c => c.subject_id === sid);
    mChap.innerHTML = '<option value="">Select Chapter (Optional)</option>' +
        filtered.map(c => `<option value="${c.id}">${esc(c.name)}</option>`).join('');
    onModalChapterChange();
}

function onModalChapterChange() {
    const cid = parseInt(document.getElementById('mChapter').value) || 0;
    const mTop = document.getElementById('mTopic');
    const filtered = taxonomy.topics.filter(t => t.chapter_id === cid);
    mTop.innerHTML = '<option value="">Select Topic (Optional)</option>' +
        filtered.map(t => `<option value="${t.id}">${esc(t.name)}</option>`).join('');
}

function onTypeChange() {
    const type = document.getElementById('mType').value;
    const mcq = document.getElementById('mcqOptions');
    const tf = document.getElementById('tfOptions');
    const optContainer = document.getElementById('optionsContainer');

    if (type === 'MCQ') {
        optContainer.style.display = 'block';
        mcq.style.display = 'block';
        tf.style.display = 'none';
        document.getElementById('optA').required = true;
        document.getElementById('optB').required = true;
        document.getElementById('optC').required = true;
        document.getElementById('optD').required = true;
    } else if (type === 'TRUE_FALSE') {
        optContainer.style.display = 'block';
        mcq.style.display = 'none';
        tf.style.display = 'block';
        document.getElementById('optA').required = false;
        document.getElementById('optB').required = false;
        document.getElementById('optC').required = false;
        document.getElementById('optD').required = false;
    } else {
        // Descriptive or Numerical
        optContainer.style.display = 'none';
        document.getElementById('optA').required = false;
        document.getElementById('optB').required = false;
        document.getElementById('optC').required = false;
        document.getElementById('optD').required = false;
    }
}

function highlightCorrectOpt(key) {
    ['A', 'B', 'C', 'D'].forEach(k => {
        const box = document.getElementById('optBox' + k);
        if (box) box.classList.toggle('selected', k === key);
    });
}

function debounceLoad() {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
        currentPage = 1;
        loadQuestions();
    }, 350);
}

function resetFilters() {
    document.getElementById('fSearch').value = '';
    document.getElementById('fSubject').value = '';
    document.getElementById('fChapter').innerHTML = '<option value="">All Chapters</option>';
    document.getElementById('fCategory').value = '';
    document.getElementById('fType').value = '';
    document.getElementById('fDifficulty').value = '';
    document.getElementById('fStatus').value = '';
    document.getElementById('fAuthor').value = '';
    currentPage = 1;
    loadQuestions();
}

async function loadQuestions(page = 1) {
    currentPage = page;
    const tbody = document.getElementById('questionsBody');
    tbody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding:2rem; color:var(--text-muted);">Loading questions...</td></tr>';

    const params = new URLSearchParams({
        action: 'list',
        search: document.getElementById('fSearch').value.trim(),
        subject_id: document.getElementById('fSubject').value,
        chapter_id: document.getElementById('fChapter').value,
        category_id: document.getElementById('fCategory').value,
        type: document.getElementById('fType').value,
        difficulty: document.getElementById('fDifficulty').value,
        status: document.getElementById('fStatus').value,
        author_type: document.getElementById('fAuthor').value,
        page: currentPage,
        limit: 15
    });

    try {
        const res = await fetch(`${QA}?${params}`);
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);

        // Update Stats
        const st = json.data.stats || {};
        document.getElementById('st-total').textContent = st.total || 0;
        document.getElementById('st-pub').textContent = st.published || 0;
        document.getElementById('st-draft').textContent = st.draft || 0;
        document.getElementById('st-rev').textContent = st.review || 0;
        document.getElementById('st-req').textContent = st.changes_requested || 0;

        const rows = json.data.questions || [];
        if (!rows.length) {
            tbody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding:3rem; color:var(--text-muted);">No questions match the current filters.</td></tr>';
            document.getElementById('pageInfo').textContent = 'Showing 0 questions';
            document.getElementById('pageNav').innerHTML = '';
            return;
        }

        tbody.innerHTML = rows.map(renderRow).join('');

        // Pagination info
        const total = json.data.total;
        const start = (currentPage - 1) * 15 + 1;
        const end = Math.min(currentPage * 15, total);
        document.getElementById('pageInfo').textContent = `Showing ${start} - ${end} of ${total} questions`;

        renderPagination(json.data.pages, currentPage);
    } catch (e) {
        tbody.innerHTML = `<tr><td colspan="9" style="text-align:center; padding:2rem; color:var(--accent-danger);">Error: ${esc(e.message)}</td></tr>`;
    }
}

function renderRow(q) {
    const statusClass = 'q-' + q.status;
    const statusLabel = q.status === 'review' ? 'In Review' : (q.status.replace('_', ' '));
    const isPublished = q.status === 'published';

    const creatorHtml = q.author_user_id 
        ? `<span class="creator-tag c-teacher" title="Teacher: ${esc(q.teacher_name)}">👨‍🏫 ${esc(q.teacher_display_name || q.teacher_name || 'Teacher')}</span>`
        : `<span class="creator-tag c-admin" title="Admin Created">🛡️ Admin</span>`;

    const imgTag = q.image_url ? `<a href="${esc(q.image_url)}" target="_blank" style="margin-left:6px; color:#38bdf8;" title="View attached image">🖼️</a>` : '';

    return `
        <tr>
            <td style="font-weight:700; color:#fff;">#${q.id}</td>
            <td style="max-width:320px;">
                <div style="font-weight:600; color:#fff; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
                    ${esc(q.question_text || '(No text)')} ${imgTag}
                </div>
                ${q.correct_answer ? `<div style="font-size:.74rem; color:#86efac; margin-top:2px;">Ans: Option ${esc(q.correct_answer)}</div>` : ''}
            </td>
            <td>
                <div style="font-weight:600; color:#fff;">${esc(q.subject_name || 'General')}</div>
                <div style="font-size:.72rem; color:var(--text-muted);">${esc(q.chapter_name || q.topic_name || '-')}</div>
            </td>
            <td><span style="font-size:.75rem; color:#cbd5e1;">${esc(q.question_type)}</span></td>
            <td><span class="q-pill d-${esc(q.difficulty)}">${esc(q.difficulty)}</span></td>
            <td>
                <span style="color:#86efac; font-weight:700;">+${parseFloat(q.marks).toFixed(1)}</span>
                <span style="color:#fca5a5; font-size:.75rem; margin-left:3px;">-${parseFloat(q.negative_marks).toFixed(1)}</span>
            </td>
            <td>${creatorHtml}</td>
            <td><span class="q-pill ${statusClass}">${esc(statusLabel)}</span></td>
            <td style="text-align:right;">
                <div style="display:flex; justify-content:flex-end; gap:.35rem;">
                    <button class="btn btn-sm" style="padding:.25rem .5rem;" title="Edit question" onclick="openEditModal(${q.id})">✏️</button>
                    <button class="btn btn-sm" style="padding:.25rem .5rem; background:${isPublished ? 'rgba(239,68,68,.12)' : 'rgba(34,197,94,.12)'}; color:${isPublished ? '#fca5a5' : '#86efac'};"
                            title="${isPublished ? 'Unpublish (hide from students)' : 'Publish (activate in student app)'}"
                            onclick="togglePublish(${q.id})">
                        ${isPublished ? 'Unpublish' : 'Publish'}
                    </button>
                    <button class="btn btn-sm" style="padding:.25rem .5rem; color:var(--accent-rose);" title="Delete" onclick="deleteQuestion(${q.id})">🗑️</button>
                </div>
            </td>
        </tr>
    `;
}

function renderPagination(totalPages, current) {
    const nav = document.getElementById('pageNav');
    if (totalPages <= 1) { nav.innerHTML = ''; return; }

    let btns = '';
    if (current > 1) btns += `<button class="btn btn-sm" onclick="loadQuestions(${current - 1})">&laquo; Prev</button>`;
    btns += `<span style="padding:.3rem .6rem; font-size:.8rem; color:#fff;">Page ${current} of ${totalPages}</span>`;
    if (current < totalPages) btns += `<button class="btn btn-sm" onclick="loadQuestions(${current + 1})">Next &raquo;</button>`;
    nav.innerHTML = btns;
}

// ── ADD / EDIT MODAL LOGIC ──────────────────────────────────────────
function openCreateModal() {
    document.getElementById('modalTitle').textContent = 'Add New Question';
    document.getElementById('qId').value = '0';
    document.getElementById('questionForm').reset();
    document.getElementById('qImageUrl').value = '';
    document.getElementById('imgPreview').style.display = 'none';
    document.getElementById('btnRemoveImg').style.display = 'none';
    highlightCorrectOpt('A');
    onTypeChange();
    document.getElementById('questionModal').style.display = 'block';
}

async function openEditModal(id) {
    try {
        const res = await fetch(`${QA}?action=get&id=${id}`);
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);

        const q = json.data;
        document.getElementById('modalTitle').textContent = `Edit Question #${q.id}`;
        document.getElementById('qId').value = q.id;
        document.getElementById('mSubject').value = q.subject_id || '';
        onModalSubjectChange();

        document.getElementById('mChapter').value = q.chapter_id || '';
        onModalChapterChange();

        document.getElementById('mTopic').value = q.topic_id || '';
        document.getElementById('mExam').value = (q.exam_ids && q.exam_ids[0]) ? q.exam_ids[0] : '';
        document.getElementById('mType').value = q.question_type || 'MCQ';
        document.getElementById('mDifficulty').value = q.difficulty || 'medium';
        document.getElementById('mMarks').value = q.marks || '2.00';
        document.getElementById('mNegativeMarks').value = q.negative_marks || '0.50';
        document.getElementById('mQuestionText').value = q.question_text || '';
        document.getElementById('mExplanation').value = q.explanation || '';

        // Image
        if (q.image_url) {
            document.getElementById('qImageUrl').value = q.image_url;
            const prev = document.getElementById('imgPreview');
            prev.src = q.image_url;
            prev.style.display = 'block';
            document.getElementById('btnRemoveImg').style.display = 'inline-block';
        } else {
            removeImage();
        }

        onTypeChange();

        // Populate options
        if (q.options && q.options.length) {
            q.options.forEach(opt => {
                const k = opt.option_key;
                const txtInput = document.getElementById('opt' + k);
                if (txtInput) txtInput.value = opt.option_text;
                if (opt.is_correct == 1) {
                    const r = document.querySelector(`input[name="correct_opt"][value="${k}"]`);
                    if (r) r.checked = true;
                    highlightCorrectOpt(k);

                    const rTf = document.querySelector(`input[name="correct_opt_tf"][value="${k}"]`);
                    if (rTf) rTf.checked = true;
                }
            });
        }

        document.getElementById('questionModal').style.display = 'block';
    } catch (e) {
        alert('Could not load question: ' + e.message);
    }
}

function closeQuestionModal() {
    document.getElementById('questionModal').style.display = 'none';
}

function openBulkModal() {
    document.getElementById('bulkModal').style.display = 'block';
}

function closeBulkModal() {
    document.getElementById('bulkModal').style.display = 'none';
}

async function handleImageUpload(e) {
    const file = e.target.files[0];
    if (!file) return;

    const fd = new FormData();
    fd.append('image', file);

    try {
        const res = await fetch(`${QA}?action=upload_image`, {
            method: 'POST',
            headers: { 'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || '' },
            body: fd
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);

        document.getElementById('qImageUrl').value = json.data.url;
        const prev = document.getElementById('imgPreview');
        prev.src = json.data.url;
        prev.style.display = 'block';
        document.getElementById('btnRemoveImg').style.display = 'inline-block';
    } catch (err) {
        alert('Image upload failed: ' + err.message);
    }
}

function removeImage() {
    document.getElementById('qImageUrl').value = '';
    document.getElementById('mImageFile').value = '';
    document.getElementById('imgPreview').style.display = 'none';
    document.getElementById('btnRemoveImg').style.display = 'none';
}

async function submitSave(status) {
    const form = document.getElementById('questionForm');
    if (!form.checkValidity()) {
        form.reportValidity();
        return;
    }

    const id = parseInt(document.getElementById('qId').value) || 0;
    const type = document.getElementById('mType').value;
    let correctOption = 'A';

    if (type === 'MCQ') {
        const checked = document.querySelector('input[name="correct_opt"]:checked');
        if (checked) correctOption = checked.value;
    } else if (type === 'TRUE_FALSE') {
        const checked = document.querySelector('input[name="correct_opt_tf"]:checked');
        if (checked) correctOption = checked.value;
    }

    const payload = {
        id: id,
        subject_id: parseInt(document.getElementById('mSubject').value),
        chapter_id: parseInt(document.getElementById('mChapter').value) || null,
        topic_id: parseInt(document.getElementById('mTopic').value) || null,
        exam_ids: document.getElementById('mExam').value ? [parseInt(document.getElementById('mExam').value)] : [],
        question_type: type,
        difficulty: document.getElementById('mDifficulty').value,
        marks: parseFloat(document.getElementById('mMarks').value) || 2.00,
        negative_marks: parseFloat(document.getElementById('mNegativeMarks').value) || 0.00,
        question_text: document.getElementById('mQuestionText').value.trim(),
        explanation: document.getElementById('mExplanation').value.trim(),
        image_url: document.getElementById('qImageUrl').value,
        status: status,
        correct_option: correctOption,
        options: type === 'MCQ' ? [
            { option_key: 'A', option_text: document.getElementById('optA').value.trim() },
            { option_key: 'B', option_text: document.getElementById('optB').value.trim() },
            { option_key: 'C', option_text: document.getElementById('optC').value.trim() },
            { option_key: 'D', option_text: document.getElementById('optD').value.trim() }
        ] : []
    };

    try {
        const res = await fetch(`${QA}?action=save`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || ''
            },
            body: JSON.stringify(payload)
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);

        closeQuestionModal();
        loadQuestions(currentPage);
    } catch (e) {
        alert('Could not save question: ' + e.message);
    }
}

async function togglePublish(id) {
    try {
        const res = await fetch(`${QA}?action=toggle_publish&id=${id}`, {
            method: 'POST',
            headers: { 'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || '' }
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        loadQuestions(currentPage);
    } catch (e) {
        alert('Toggle failed: ' + e.message);
    }
}

async function deleteQuestion(id) {
    if (!confirm(`Are you sure you want to permanently delete Question #${id}? This action cannot be undone.`)) return;

    try {
        const res = await fetch(`${QA}?action=delete&id=${id}`, {
            method: 'POST',
            headers: { 'X-CSRF-Token': window.ADMIN_CSRF_TOKEN || '' }
        });
        const json = await res.json();
        if (json.status !== 'success') throw new Error(json.message);
        loadQuestions(currentPage);
    } catch (e) {
        alert('Delete failed: ' + e.message);
    }
}

window.addEventListener('DOMContentLoaded', init);
</script>
