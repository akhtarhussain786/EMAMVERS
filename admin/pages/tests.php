<?php
require_once __DIR__ . '/../includes/page_guard.php';
?>
<style>
/* ── Stat Cards ── */
.tm-stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:1rem;margin-bottom:1.5rem}
.tm-stat{background:var(--bg-card);border:1px solid rgba(148,163,184,.15);border-radius:12px;padding:1rem;cursor:pointer;transition:border-color .2s}
.tm-stat:hover,.tm-stat.active{border-color:rgba(99,102,241,.5)}
.tm-stat .num{font-size:1.6rem;font-weight:800;color:#fff;line-height:1}
.tm-stat .lbl{font-size:.73rem;color:var(--text-muted);margin-top:.3rem}

/* ── Status Pills ── */
.sp{padding:.18rem .55rem;border-radius:99px;font-size:.68rem;font-weight:700;text-transform:uppercase;letter-spacing:.04em;white-space:nowrap}
.sp-draft{background:rgba(148,163,184,.15);color:#cbd5e1;border:1px solid rgba(148,163,184,.3)}
.sp-ready_to_publish{background:rgba(245,158,11,.15);color:#fcd34d;border:1px solid rgba(245,158,11,.3)}
.sp-published{background:rgba(34,197,94,.15);color:#86efac;border:1px solid rgba(34,197,94,.3)}
.sp-active{background:rgba(99,102,241,.15);color:#a5b4fc;border:1px solid rgba(99,102,241,.3)}
.sp-completed{background:rgba(56,189,248,.15);color:#7dd3fc;border:1px solid rgba(56,189,248,.3)}
.sp-archived{background:rgba(100,116,139,.15);color:#94a3b8;border:1px solid rgba(100,116,139,.3)}
.sp-easy{background:rgba(34,197,94,.12);color:#86efac}
.sp-medium{background:rgba(245,158,11,.12);color:#fcd34d}
.sp-hard{background:rgba(239,68,68,.12);color:#fca5a5}

/* ── Table ── */
.tm-table{width:100%;border-collapse:collapse;font-size:.84rem}
.tm-table th{text-align:left;padding:.6rem .7rem;color:var(--text-muted);font-size:.7rem;text-transform:uppercase;letter-spacing:.04em;border-bottom:1px solid rgba(148,163,184,.15)}
.tm-table td{padding:.7rem .7rem;border-bottom:1px solid rgba(148,163,184,.07);color:var(--text-secondary);vertical-align:middle}
.tm-table tr:hover{background:rgba(255,255,255,.018)}
.tm-table .test-title{font-weight:700;color:#fff;font-size:.88rem}
.tm-table .test-meta{font-size:.72rem;color:var(--text-muted);margin-top:2px}

/* ── Modals ── */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.78);z-index:1000;backdrop-filter:blur(6px);overflow-y:auto;padding:20px}
.modal-box{width:100%;max-width:900px;margin:2rem auto;background:var(--bg-main,#0f172a);border:1px solid rgba(148,163,184,.25);padding:1.75rem;border-radius:14px;box-shadow:0 24px 48px rgba(0,0,0,.55)}
.modal-xl{max-width:1150px}
.modal-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:1.25rem;padding-bottom:.75rem;border-bottom:1px solid rgba(148,163,184,.15)}
.modal-title{font-size:1.1rem;font-weight:700;color:#fff}
.modal-close{background:transparent;border:none;color:var(--text-muted);font-size:1.5rem;cursor:pointer;line-height:1;padding:0 .2rem}
.modal-close:hover{color:#fff}

.g2{display:grid;grid-template-columns:1fr 1fr;gap:1rem}
.g3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:1rem}
.g4{display:grid;grid-template-columns:repeat(4,1fr);gap:.8rem}
@media(max-width:768px){.g2,.g3,.g4{grid-template-columns:1fr}}

/* ── Question Builder ── */
.qb-toolbar{display:flex;gap:.6rem;margin-bottom:1.25rem;flex-wrap:wrap;align-items:center}
.q-card{background:rgba(255,255,255,.025);border:1px solid rgba(148,163,184,.15);border-radius:10px;padding:1rem;margin-bottom:.75rem;position:relative}
.q-card .q-num{position:absolute;top:.7rem;left:.8rem;font-size:.72rem;font-weight:700;color:var(--text-muted)}
.q-card .q-text{font-size:.85rem;color:#fff;margin:0 0 .5rem 2rem;line-height:1.5}
.q-card .q-opts{display:grid;grid-template-columns:1fr 1fr;gap:.35rem;margin-left:2rem;font-size:.78rem}
.q-card .q-opt{padding:.3rem .6rem;border-radius:6px;border:1px solid rgba(148,163,184,.2);color:var(--text-muted)}
.q-card .q-opt.correct{border-color:rgba(34,197,94,.5);background:rgba(34,197,94,.08);color:#86efac}
.q-card .q-actions{position:absolute;top:.6rem;right:.7rem;display:flex;gap:.35rem}
.q-card .q-actions button{background:rgba(148,163,184,.1);border:none;border-radius:5px;padding:.22rem .48rem;color:var(--text-muted);cursor:pointer;font-size:.78rem}
.q-card .q-actions button:hover{background:rgba(148,163,184,.2);color:#fff}

/* ── AI Preview card ── */
.ai-card{background:rgba(99,102,241,.05);border:1px solid rgba(99,102,241,.25);border-radius:10px;padding:1rem;margin-bottom:.75rem;position:relative}
.ai-card .ai-chk{position:absolute;top:.8rem;left:.8rem}
.ai-card .ai-body{margin-left:1.9rem}
.ai-card .ai-q{font-size:.86rem;color:#fff;margin-bottom:.5rem;line-height:1.5}
.ai-card .ai-opts{display:grid;grid-template-columns:1fr 1fr;gap:.3rem;font-size:.77rem}
.ai-card .ai-opt{padding:.28rem .55rem;border-radius:5px;border:1px solid rgba(148,163,184,.18);color:var(--text-muted)}
.ai-card .ai-opt.correct{border-color:rgba(34,197,94,.5);background:rgba(34,197,94,.08);color:#86efac}
.ai-card .ai-actions{position:absolute;top:.7rem;right:.8rem;display:flex;gap:.3rem}
.ai-card .ai-actions button{background:rgba(148,163,184,.1);border:none;border-radius:5px;padding:.22rem .48rem;cursor:pointer;font-size:.77rem;color:var(--text-muted)}
.ai-card .ai-actions button:hover{background:rgba(148,163,184,.2);color:#fff}

.btn-ai{background:linear-gradient(135deg,#6366f1,#8b5cf6);color:#fff;border:none;padding:.55rem 1.1rem;border-radius:8px;font-weight:600;font-size:.85rem;cursor:pointer;display:flex;align-items:center;gap:.45rem}
.btn-ai:hover{opacity:.88}
.btn-pub{background:linear-gradient(135deg,#22c55e,#16a34a);color:#fff;border:none;padding:.55rem 1.4rem;border-radius:8px;font-weight:700;font-size:.88rem;cursor:pointer}
.btn-pub:hover{opacity:.88}

.empty-state{text-align:center;padding:3rem 1rem;color:var(--text-muted);font-size:.88rem}
.empty-state .icon{font-size:2.5rem;margin-bottom:.75rem;display:block}

.pagination{display:flex;gap:.4rem;align-items:center;justify-content:flex-end;margin-top:1rem}
.pagination button{background:rgba(148,163,184,.12);border:none;border-radius:6px;padding:.35rem .75rem;color:var(--text-secondary);cursor:pointer;font-size:.82rem}
.pagination button:hover,.pagination button.active{background:rgba(99,102,241,.3);color:#fff}
.pagination button:disabled{opacity:.35;cursor:not-allowed}

.tab-bar{display:flex;gap:.4rem;border-bottom:1px solid rgba(148,163,184,.15);margin-bottom:1.25rem}
.tab-btn{background:transparent;border:none;border-bottom:2px solid transparent;padding:.6rem 1.1rem;color:var(--text-muted);cursor:pointer;font-size:.85rem;font-weight:600;transition:all .2s}
.tab-btn.active,.tab-btn:hover{color:#fff;border-bottom-color:#6366f1}

.form-label{font-size:.78rem;color:var(--text-muted);margin-bottom:.3rem;font-weight:600;text-transform:uppercase;letter-spacing:.04em}
.opt-row{display:flex;align-items:center;gap:.6rem;margin-bottom:.5rem}
.opt-row input[type="radio"]{accent-color:#22c55e}
.opt-label{font-size:.8rem;font-weight:700;min-width:28px;color:#a5b4fc}
</style>

<!-- ── Stat Cards ── -->
<div class="tm-stats" id="tmStats">
    <div class="tm-stat" onclick="filterByStatus('')" id="stat-all">
        <div class="num" id="st-total">—</div><div class="lbl">Total Tests</div>
    </div>
    <div class="tm-stat" onclick="filterByStatus('draft')" id="stat-draft">
        <div class="num" style="color:#94a3b8" id="st-draft">—</div><div class="lbl">Draft</div>
    </div>
    <div class="tm-stat" onclick="filterByStatus('ready_to_publish')" id="stat-rtp">
        <div class="num" style="color:#fcd34d" id="st-rtp">—</div><div class="lbl">Ready to Publish</div>
    </div>
    <div class="tm-stat" onclick="filterByStatus('published')" id="stat-pub">
        <div class="num" style="color:#86efac" id="st-pub">—</div><div class="lbl">Published</div>
    </div>
    <div class="tm-stat" onclick="filterByStatus('active')" id="stat-act">
        <div class="num" style="color:#a5b4fc" id="st-act">—</div><div class="lbl">Active</div>
    </div>
    <div class="tm-stat" onclick="filterByStatus('completed')" id="stat-comp">
        <div class="num" style="color:#7dd3fc" id="st-comp">—</div><div class="lbl">Completed</div>
    </div>
</div>

<!-- ── Main Table Card ── -->
<div class="table-card">
    <div class="table-header" style="flex-wrap:wrap;gap:1rem;align-items:center">
        <div>
            <div class="table-title">Test Management</div>
            <div style="font-size:.78rem;color:var(--text-muted);margin-top:2px">Create AI-powered and manual tests, build question banks, publish to students.</div>
        </div>
        <div style="display:flex;gap:.6rem;flex-wrap:wrap">
            <button class="btn btn-primary" onclick="openCreateModal()">+ Create New Test</button>
        </div>
    </div>

    <!-- Filters -->
    <div style="display:flex;gap:.6rem;flex-wrap:wrap;align-items:center;padding:.75rem 0 1rem">
        <input type="text" id="fSearch" class="form-control" placeholder="Search tests..." style="min-width:220px" oninput="debounceLoad()">
        <select id="fStatus" class="form-control" onchange="loadTests()">
            <option value="">All Statuses</option>
            <option value="draft">Draft</option>
            <option value="ready_to_publish">Ready to Publish</option>
            <option value="published">Published</option>
            <option value="active">Active</option>
            <option value="completed">Completed</option>
            <option value="archived">Archived</option>
        </select>
        <select id="fSubject" class="form-control" onchange="loadTests()"><option value="">All Subjects</option></select>
        <select id="fDifficulty" class="form-control" onchange="loadTests()">
            <option value="">All Difficulties</option>
            <option value="easy">Easy</option>
            <option value="medium">Medium</option>
            <option value="hard">Hard</option>
        </select>
    </div>

    <!-- Table -->
    <div style="overflow-x:auto">
        <table class="tm-table">
            <thead>
                <tr>
                    <th>Test</th>
                    <th>Subject / Exam</th>
                    <th>Questions</th>
                    <th>Marks</th>
                    <th>Duration</th>
                    <th>Difficulty</th>
                    <th>Status</th>
                    <th>Attempts</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody id="tmTableBody">
                <tr><td colspan="9" class="empty-state"><span class="icon">⏳</span>Loading tests…</td></tr>
            </tbody>
        </table>
    </div>
    <div class="pagination" id="tmPagination"></div>
</div>

<!-- ═══════════════════════════════════════════════════════════════
     MODAL 1: CREATE / EDIT TEST
══════════════════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="createModal">
<div class="modal-box">
    <div class="modal-header">
        <div class="modal-title" id="createModalTitle">Create New Test</div>
        <button class="modal-close" onclick="closeModal('createModal')">×</button>
    </div>

    <div class="g2">
        <div>
            <div class="form-group">
                <label class="form-label">Test Title *</label>
                <input type="text" id="f_title" class="form-control" placeholder="e.g. SSC CGL Full Mock Test 1">
            </div>
        </div>
        <div>
            <div class="form-group">
                <label class="form-label">Test Category</label>
                <select id="f_test_category" class="form-control">
                    <option value="">Select Category</option>
                    <option value="mock_test">Mock Test</option>
                    <option value="chapter_test">Chapter Test</option>
                    <option value="topic_test">Topic Test</option>
                    <option value="full_syllabus">Full Syllabus Test</option>
                    <option value="previous_year">Previous Year Paper</option>
                    <option value="sectional">Sectional Test</option>
                </select>
            </div>
        </div>
    </div>

    <div class="form-group">
        <label class="form-label">Description</label>
        <textarea id="f_description" class="form-control" rows="2" placeholder="Brief description about this test…"></textarea>
    </div>

    <div class="g3">
        <div class="form-group">
            <label class="form-label">Subject</label>
            <select id="f_subject_id" class="form-control" onchange="onCreateSubjectChange()"><option value="">Select Subject</option></select>
        </div>
        <div class="form-group">
            <label class="form-label">Chapter</label>
            <select id="f_chapter_id" class="form-control"><option value="">Select Chapter</option></select>
        </div>
        <div class="form-group">
            <label class="form-label">Exam / Series</label>
            <select id="f_exam_id" class="form-control"><option value="">Select Exam</option></select>
        </div>
    </div>

    <div class="g4">
        <div class="form-group">
            <label class="form-label">Total Questions</label>
            <input type="number" id="f_total_questions" class="form-control" value="30" min="0">
        </div>
        <div class="form-group">
            <label class="form-label">Total Marks</label>
            <input type="number" id="f_total_marks" class="form-control" value="100" min="0" step="0.5">
        </div>
        <div class="form-group">
            <label class="form-label">Duration (Minutes)</label>
            <input type="number" id="f_duration_minutes" class="form-control" value="60" min="1">
        </div>
        <div class="form-group">
            <label class="form-label">Difficulty</label>
            <select id="f_difficulty" class="form-control">
                <option value="easy">Easy</option>
                <option value="medium" selected>Medium</option>
                <option value="hard">Hard</option>
            </select>
        </div>
    </div>

    <div class="g4">
        <div class="form-group">
            <label class="form-label">Negative Marking</label>
            <input type="number" id="f_negative_marking" class="form-control" value="0" min="0" step="0.25">
        </div>
        <div class="form-group">
            <label class="form-label">Passing Marks</label>
            <input type="number" id="f_passing_marks" class="form-control" value="0" min="0" step="0.5">
        </div>
        <div class="form-group">
            <label class="form-label">Start Date & Time</label>
            <input type="datetime-local" id="f_start_time" class="form-control">
        </div>
        <div class="form-group">
            <label class="form-label">End Date & Time</label>
            <input type="datetime-local" id="f_end_time" class="form-control">
        </div>
    </div>

    <div class="form-group">
        <label class="form-label">Test Instructions</label>
        <textarea id="f_instructions" class="form-control" rows="3" placeholder="Instructions shown to students before they start the test…"></textarea>
    </div>

    <div style="display:flex;gap:.7rem;justify-content:flex-end;margin-top:1rem">
        <button class="btn" style="background:rgba(148,163,184,.12);color:#fff" onclick="closeModal('createModal')">Cancel</button>
        <button class="btn btn-primary" onclick="saveTest()">💾 Save as Draft</button>
    </div>
    <input type="hidden" id="f_test_id" value="0">
</div>
</div>

<!-- ═══════════════════════════════════════════════════════════════
     MODAL 2: QUESTION BUILDER (AI + Manual)
══════════════════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="builderModal">
<div class="modal-box modal-xl">
    <div class="modal-header">
        <div>
            <div class="modal-title" id="builderTestTitle">Question Builder</div>
            <div style="font-size:.75rem;color:var(--text-muted);margin-top:2px" id="builderTestMeta"></div>
        </div>
        <div style="display:flex;gap:.6rem;align-items:center">
            <button class="btn-pub" onclick="confirmPublish()">🚀 Publish Test</button>
            <button class="modal-close" onclick="closeModal('builderModal')">×</button>
        </div>
    </div>

    <div class="tab-bar">
        <button class="tab-btn active" onclick="switchBuilderTab('questions')" id="tab-questions">📋 Questions (<span id="qCountBadge">0</span>)</button>
        <button class="tab-btn" onclick="switchBuilderTab('ai')" id="tab-ai">🤖 AI Generate</button>
        <button class="tab-btn" onclick="switchBuilderTab('manual')" id="tab-manual">✏️ Add Manually</button>
    </div>

    <!-- Tab: Existing Questions -->
    <div id="tab-panel-questions">
        <div id="qBuilderList">
            <div class="empty-state"><span class="icon">📭</span>No questions yet. Use AI Generate or Add Manually.</div>
        </div>
    </div>

    <!-- Tab: AI Generate -->
    <div id="tab-panel-ai" style="display:none">
        <div style="background:rgba(99,102,241,.06);border:1px solid rgba(99,102,241,.25);border-radius:10px;padding:1.25rem;margin-bottom:1.25rem">
            <div style="font-size:.85rem;font-weight:700;color:#a5b4fc;margin-bottom:1rem">🤖 AI Question Generation Settings</div>
            <div class="g3">
                <div class="form-group">
                    <label class="form-label">Subject</label>
                    <select id="ai_subject_id" class="form-control"><option value="">Select Subject</option></select>
                </div>
                <div class="form-group">
                    <label class="form-label">Topic / Chapter</label>
                    <input type="text" id="ai_topic" class="form-control" placeholder="e.g. Simple Interest, Modern History">
                </div>
                <div class="form-group">
                    <label class="form-label">Number of Questions</label>
                    <select id="ai_count" class="form-control">
                        <option value="3">3 Questions</option>
                        <option value="5" selected>5 Questions</option>
                        <option value="10">10 Questions</option>
                        <option value="15">15 Questions</option>
                    </select>
                </div>
            </div>
            <div class="g3">
                <div class="form-group">
                    <label class="form-label">Difficulty</label>
                    <select id="ai_difficulty" class="form-control">
                        <option value="easy">Easy</option>
                        <option value="medium" selected>Medium</option>
                        <option value="hard">Hard</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Question Type</label>
                    <select id="ai_qtype" class="form-control">
                        <option value="MCQ">MCQ (4 Options)</option>
                        <option value="TRUE_FALSE">True / False</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Language</label>
                    <select id="ai_language" class="form-control">
                        <option value="en">English</option>
                        <option value="hi">Hindi</option>
                    </select>
                </div>
            </div>
            <button class="btn-ai" onclick="runAiGenerate()" id="btnAiGenerate">
                <span>✨</span> Generate Questions
            </button>
        </div>

        <div id="aiPreviewArea" style="display:none">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem">
                <div style="font-size:.85rem;font-weight:700;color:#fff">Preview — Select questions to add to test</div>
                <div style="display:flex;gap:.6rem">
                    <button class="btn" style="background:rgba(148,163,184,.12);color:#fff;font-size:.8rem" onclick="selectAllAi(true)">Select All</button>
                    <button class="btn" style="background:rgba(148,163,184,.12);color:#fff;font-size:.8rem" onclick="selectAllAi(false)">Deselect All</button>
                    <button class="btn btn-primary" style="font-size:.82rem" onclick="addSelectedAiToTest()">✅ Add Selected to Test</button>
                </div>
            </div>
            <div id="aiCardsList"></div>
        </div>
    </div>

    <!-- Tab: Add Manually -->
    <div id="tab-panel-manual" style="display:none">
        <div style="background:rgba(255,255,255,.025);border:1px solid rgba(148,163,184,.18);border-radius:10px;padding:1.25rem">
            <div style="font-size:.85rem;font-weight:700;color:#fff;margin-bottom:1rem">✏️ Add Question Manually</div>

            <div class="form-group">
                <label class="form-label">Question Text *</label>
                <textarea id="mq_text" class="form-control" rows="3" placeholder="Enter your question here…"></textarea>
            </div>

            <div id="mq_options_area">
                <div class="form-label" style="margin-bottom:.6rem">Answer Options</div>
                <?php foreach (['A','B','C','D'] as $opt): ?>
                <div class="opt-row">
                    <input type="radio" name="mq_correct" value="<?= $opt ?>" id="mq_correct_<?= $opt ?>">
                    <span class="opt-label"><?= $opt ?>.</span>
                    <input type="text" id="mq_opt_<?= strtolower($opt) ?>" class="form-control" placeholder="Option <?= $opt ?>">
                </div>
                <?php endforeach; ?>
                <div style="font-size:.75rem;color:var(--text-muted);margin-top:.3rem">Select the radio button next to the correct answer.</div>
            </div>

            <div class="g3" style="margin-top:1rem">
                <div class="form-group">
                    <label class="form-label">Difficulty</label>
                    <select id="mq_difficulty" class="form-control">
                        <option value="easy">Easy</option>
                        <option value="medium" selected>Medium</option>
                        <option value="hard">Hard</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Marks</label>
                    <input type="number" id="mq_marks" class="form-control" value="1" min="0" step="0.5">
                </div>
                <div class="form-group">
                    <label class="form-label">Negative Marks</label>
                    <input type="number" id="mq_neg_marks" class="form-control" value="0" min="0" step="0.25">
                </div>
            </div>

            <div class="form-group">
                <label class="form-label">Explanation / Solution</label>
                <textarea id="mq_explanation" class="form-control" rows="2" placeholder="Explain the correct answer (optional)…"></textarea>
            </div>

            <div style="display:flex;gap:.6rem;justify-content:flex-end;margin-top:.75rem">
                <button class="btn" style="background:rgba(148,163,184,.12);color:#fff" onclick="clearManualForm()">Clear</button>
                <button class="btn btn-primary" onclick="submitManualQuestion()">➕ Add to Test</button>
            </div>
        </div>
    </div>
</div>
</div>

<!-- ═══════════════════════════════════════════════════════════════
     MODAL 3: TEST PREVIEW
══════════════════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="previewModal">
<div class="modal-box modal-xl">
    <div class="modal-header">
        <div class="modal-title">Test Preview</div>
        <div style="display:flex;gap:.6rem">
            <button class="btn-pub" onclick="confirmPublish()">🚀 PUBLISH TEST</button>
            <button class="modal-close" onclick="closeModal('previewModal')">×</button>
        </div>
    </div>
    <div id="previewContent">Loading…</div>
</div>
</div>

<!-- ═══════════════════════════════════════════════════════════════
     MODAL 4: CONFIRM PUBLISH
══════════════════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="publishConfirmModal">
<div class="modal-box" style="max-width:480px">
    <div class="modal-header">
        <div class="modal-title">🚀 Confirm Publish</div>
        <button class="modal-close" onclick="closeModal('publishConfirmModal')">×</button>
    </div>
    <div style="color:var(--text-secondary);font-size:.88rem;line-height:1.6;margin-bottom:1.25rem">
        Publishing will make this test <strong style="color:#86efac">visible to all students</strong> immediately (or at the scheduled start time). Students will receive a push notification.<br><br>
        <strong style="color:#fcd34d">⚠️ Draft tests are never visible to students.</strong>
    </div>
    <div id="publishConfirmInfo" style="background:rgba(34,197,94,.07);border:1px solid rgba(34,197,94,.2);border-radius:8px;padding:.75rem;font-size:.83rem;margin-bottom:1.25rem"></div>
    <div style="display:flex;gap:.7rem;justify-content:flex-end">
        <button class="btn" style="background:rgba(148,163,184,.12);color:#fff" onclick="closeModal('publishConfirmModal')">Cancel</button>
        <button class="btn-pub" onclick="doPublish()" id="btnDoPublish">🚀 Yes, Publish Now</button>
    </div>
</div>
</div>

<!-- ═══════════════════════════════════════════════════════════════
     MODAL 5: ATTEMPTS & RESULTS
══════════════════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="attemptsModal">
<div class="modal-box modal-xl">
    <div class="modal-header">
        <div>
            <div class="modal-title">Student Attempts & Results</div>
            <div style="font-size:.75rem;color:var(--text-muted)" id="attemptsTestTitle"></div>
        </div>
        <div style="display:flex;gap:.6rem">
            <button class="btn" style="background:rgba(99,102,241,.2);color:#a5b4fc;font-size:.82rem" onclick="toggleResults()" id="btnToggleResults">Toggle Results</button>
            <button class="modal-close" onclick="closeModal('attemptsModal')">×</button>
        </div>
    </div>
    <div id="attemptsContent">Loading…</div>
</div>
</div>

<!-- ═══════════════════════════════════════════════════════════════
     MODAL 6: EDIT QUESTION
══════════════════════════════════════════════════════════════════ -->
<div class="modal-overlay" id="editQModal">
<div class="modal-box">
    <div class="modal-header">
        <div class="modal-title">Edit Question</div>
        <button class="modal-close" onclick="closeModal('editQModal')">×</button>
    </div>
    <div class="form-group">
        <label class="form-label">Question Text *</label>
        <textarea id="eq_text" class="form-control" rows="3"></textarea>
    </div>
    <div id="eq_options_area">
        <div class="form-label" style="margin-bottom:.6rem">Answer Options</div>
        <?php foreach (['A','B','C','D'] as $opt): ?>
        <div class="opt-row">
            <input type="radio" name="eq_correct" value="<?= $opt ?>" id="eq_correct_<?= $opt ?>">
            <span class="opt-label"><?= $opt ?>.</span>
            <input type="text" id="eq_opt_<?= strtolower($opt) ?>" class="form-control" placeholder="Option <?= $opt ?>">
        </div>
        <?php endforeach; ?>
    </div>
    <div class="g3" style="margin-top:1rem">
        <div class="form-group">
            <label class="form-label">Difficulty</label>
            <select id="eq_difficulty" class="form-control">
                <option value="easy">Easy</option>
                <option value="medium">Medium</option>
                <option value="hard">Hard</option>
            </select>
        </div>
        <div class="form-group">
            <label class="form-label">Marks</label>
            <input type="number" id="eq_marks" class="form-control" value="1" step="0.5">
        </div>
        <div class="form-group">
            <label class="form-label">Negative Marks</label>
            <input type="number" id="eq_neg_marks" class="form-control" value="0" step="0.25">
        </div>
    </div>
    <div class="form-group">
        <label class="form-label">Explanation</label>
        <textarea id="eq_explanation" class="form-control" rows="2"></textarea>
    </div>
    <div style="display:flex;gap:.7rem;justify-content:flex-end;margin-top:1rem">
        <button class="btn" style="background:rgba(148,163,184,.12);color:#fff" onclick="closeModal('editQModal')">Cancel</button>
        <button class="btn btn-primary" onclick="saveEditQuestion()">💾 Save Changes</button>
    </div>
    <input type="hidden" id="eq_question_id">
    <input type="hidden" id="eq_test_id">
</div>
</div>

<script>
const AJAX = 'ajax/tests.php';
const CSRF = '<?php echo htmlspecialchars(adminCsrfToken()); ?>';
let taxonomy = {subjects:[], chapters:[], topics:[], exams:[]};
let currentPage = 1;
let activeTestId = null;
let activeTestData = {};
let debTimer = null;

// ── Init ──────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    loadTaxonomy();
    loadTests();
});

function debounceLoad() { clearTimeout(debTimer); debTimer = setTimeout(loadTests, 400); }

async function loadTaxonomy() {
    const r = await fetch(`${AJAX}?action=taxonomy`);
    const j = await r.json();
    if (j.status !== 'success') return;
    taxonomy = j.data;
    // Fill create form subjects
    fillSelect('f_subject_id', taxonomy.subjects, {label:'Select Subject'});
    fillSelect('f_exam_id', taxonomy.exams, {label:'Select Exam', textKey:'title'});
    fillSelect('fSubject', taxonomy.subjects, {label:'All Subjects'});
    // AI form subjects
    fillSelect('ai_subject_id', taxonomy.subjects, {label:'Select Subject'});
}

function fillSelect(id, items, opts={}) {
    const sel = document.getElementById(id);
    if (!sel) return;
    const textKey = opts.textKey || 'name';
    const first = opts.label ? `<option value="">${opts.label}</option>` : '';
    sel.innerHTML = first + items.map(it => `<option value="${it.id}">${it[textKey]}</option>`).join('');
}

function onCreateSubjectChange() {
    const sid = document.getElementById('f_subject_id').value;
    const filtered = taxonomy.chapters.filter(c => !sid || c.subject_id == sid);
    const sel = document.getElementById('f_chapter_id');
    sel.innerHTML = '<option value="">Select Chapter</option>' + filtered.map(c => `<option value="${c.id}">${c.name}</option>`).join('');
}

// ── Load Tests Table ──────────────────────────────────────────────────────
async function loadTests(page = currentPage) {
    currentPage = page;
    const params = new URLSearchParams({
        action: 'list',
        search: document.getElementById('fSearch').value,
        status: document.getElementById('fStatus').value,
        subject_id: document.getElementById('fSubject').value,
        difficulty: document.getElementById('fDifficulty').value,
        page, limit: 15,
    });
    const r = await fetch(`${AJAX}?${params}`);
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message, 'error'); return; }
    const {tests, stats, total, pages} = j.data;

    // Update stat cards
    document.getElementById('st-total').textContent = stats.total;
    document.getElementById('st-draft').textContent  = stats.draft;
    document.getElementById('st-rtp').textContent    = stats.ready_to_publish;
    document.getElementById('st-pub').textContent    = stats.published;
    document.getElementById('st-act').textContent    = stats.active;
    document.getElementById('st-comp').textContent   = stats.completed;

    // Render table
    const tbody = document.getElementById('tmTableBody');
    if (!tests.length) {
        tbody.innerHTML = `<tr><td colspan="9" class="empty-state"><span class="icon">📭</span>No tests found. Create your first test!</td></tr>`;
        document.getElementById('tmPagination').innerHTML = '';
        return;
    }

    tbody.innerHTML = tests.map(t => {
        const statusClass = `sp-${t.status}`;
        const statusLabel = t.status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
        const diffClass   = `sp-${t.difficulty}`;
        const pubBtn = t.status === 'published' || t.status === 'active'
            ? `<button onclick="unpublishTest(${t.id})" class="btn" style="background:rgba(239,68,68,.15);color:#fca5a5;border:1px solid rgba(239,68,68,.3);font-size:.75rem;padding:.28rem .6rem">📴 Unpublish</button>`
            : `<button onclick="openPublishFlow(${t.id})" class="btn-pub" style="font-size:.75rem;padding:.3rem .75rem">🚀 Publish</button>`;

        return `<tr>
            <td>
                <div class="test-title">${esc(t.title)}</div>
                <div class="test-meta">#TEST-${t.id} · ${t.creator_name ? 'by '+esc(t.creator_name) : 'Admin'} · ${fmt(t.created_at)}</div>
            </td>
            <td><div>${esc(t.subject_name||t.exam_title||'—')}</div><div style="font-size:.72rem;color:var(--text-muted)">${esc(t.exam_title||'')}</div></td>
            <td><strong style="color:#fff">${t.actual_q_count}</strong> <span style="color:var(--text-muted);font-size:.78rem">/${t.q_count||'?'}</span></td>
            <td>${(+t.marks||0).toFixed(0)}</td>
            <td>${t.duration_mins} min</td>
            <td><span class="sp ${diffClass}">${t.difficulty}</span></td>
            <td><span class="sp ${statusClass}">${statusLabel}</span></td>
            <td>${t.attempt_count}</td>
            <td>
                <div style="display:flex;gap:.35rem;flex-wrap:wrap">
                    <button onclick="openBuilder(${t.id})" class="btn" style="background:rgba(99,102,241,.18);color:#a5b4fc;font-size:.75rem;padding:.28rem .6rem">🔧 Build</button>
                    <button onclick="openPreview(${t.id})" class="btn" style="background:rgba(148,163,184,.1);color:#fff;font-size:.75rem;padding:.28rem .6rem">👁 Preview</button>
                    ${pubBtn}
                    <button onclick="openAttempts(${t.id})" class="btn" style="background:rgba(56,189,248,.12);color:#7dd3fc;font-size:.75rem;padding:.28rem .6rem">📊 Results</button>
                    <button onclick="editTest(${t.id})" class="btn" style="background:rgba(148,163,184,.1);color:#fff;font-size:.75rem;padding:.28rem .6rem">✏️</button>
                    <button onclick="deleteTest(${t.id})" class="btn" style="background:rgba(239,68,68,.1);color:#fca5a5;font-size:.75rem;padding:.28rem .6rem">🗑</button>
                </div>
            </td>
        </tr>`;
    }).join('');

    // Pagination
    const pg = document.getElementById('tmPagination');
    if (pages <= 1) { pg.innerHTML = ''; return; }
    let html = `<button onclick="loadTests(${page-1})" ${page<=1?'disabled':''}>‹ Prev</button>`;
    for (let i=1; i<=pages; i++) html += `<button onclick="loadTests(${i})" class="${i===page?'active':''}">${i}</button>`;
    html += `<button onclick="loadTests(${page+1})" ${page>=pages?'disabled':''}>Next ›</button>`;
    pg.innerHTML = html;
}

function filterByStatus(status) {
    document.getElementById('fStatus').value = status;
    loadTests(1);
}

// ── Create / Edit Test Modal ──────────────────────────────────────────────
function openCreateModal() {
    document.getElementById('f_test_id').value = 0;
    document.getElementById('createModalTitle').textContent = 'Create New Test';
    ['f_title','f_description','f_course_class','f_instructions'].forEach(id => { const el=document.getElementById(id); if(el) el.value=''; });
    document.getElementById('f_subject_id').value = '';
    document.getElementById('f_exam_id').value = '';
    document.getElementById('f_total_questions').value = 30;
    document.getElementById('f_total_marks').value = 100;
    document.getElementById('f_duration_minutes').value = 60;
    document.getElementById('f_difficulty').value = 'medium';
    document.getElementById('f_negative_marking').value = 0;
    document.getElementById('f_passing_marks').value = 0;
    document.getElementById('f_start_time').value = '';
    document.getElementById('f_end_time').value = '';
    document.getElementById('f_test_category').value = '';
    openModal('createModal');
}

async function editTest(id) {
    const r = await fetch(`${AJAX}?action=get_test&id=${id}`);
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message, 'error'); return; }
    const t = j.data;
    document.getElementById('f_test_id').value = t.id;
    document.getElementById('createModalTitle').textContent = 'Edit Test';
    document.getElementById('f_title').value = t.title || '';
    document.getElementById('f_description').value = t.description || '';
    document.getElementById('f_subject_id').value = t.subject_id || '';
    document.getElementById('f_exam_id').value = t.exam_id || '';
    document.getElementById('f_total_questions').value = t.total_questions || 0;
    document.getElementById('f_total_marks').value = t.total_marks || 0;
    document.getElementById('f_duration_minutes').value = t.duration_minutes || 60;
    document.getElementById('f_difficulty').value = t.difficulty || 'medium';
    document.getElementById('f_negative_marking').value = t.negative_marking || 0;
    document.getElementById('f_passing_marks').value = t.passing_marks || 0;
    document.getElementById('f_start_time').value = t.start_time ? t.start_time.replace(' ','T').substring(0,16) : '';
    document.getElementById('f_end_time').value = t.end_time ? t.end_time.replace(' ','T').substring(0,16) : '';
    document.getElementById('f_instructions').value = t.instructions || '';
    document.getElementById('f_test_category').value = t.test_category || '';
    onCreateSubjectChange();
    setTimeout(() => { const el=document.getElementById('f_chapter_id'); if(el && t.chapter_id) el.value=t.chapter_id; }, 100);
    openModal('createModal');
}

async function saveTest() {
    const title = document.getElementById('f_title').value.trim();
    if (!title) { showToast('Test title is required', 'error'); return; }
    const body = {
        _csrf: CSRF,
        id: parseInt(document.getElementById('f_test_id').value),
        title,
        description: document.getElementById('f_description').value,
        exam_id: document.getElementById('f_exam_id').value || null,
        subject_id: document.getElementById('f_subject_id').value || null,
        chapter_id: document.getElementById('f_chapter_id')?.value || null,
        test_category: document.getElementById('f_test_category').value,
        total_questions: document.getElementById('f_total_questions').value,
        total_marks: document.getElementById('f_total_marks').value,
        duration_minutes: document.getElementById('f_duration_minutes').value,
        difficulty: document.getElementById('f_difficulty').value,
        negative_marking: document.getElementById('f_negative_marking').value,
        passing_marks: document.getElementById('f_passing_marks').value,
        start_time: document.getElementById('f_start_time').value || null,
        end_time: document.getElementById('f_end_time').value || null,
        instructions: document.getElementById('f_instructions').value,
    };
    const r = await fetch(`${AJAX}?action=save_test`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message, 'error'); return; }
    showToast(j.message, 'success');
    closeModal('createModal');
    loadTests();
}

// ── Question Builder ──────────────────────────────────────────────────────
async function openBuilder(testId) {
    activeTestId = testId;
    const r = await fetch(`${AJAX}?action=get_test&id=${testId}`);
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    activeTestData = j.data;
    document.getElementById('builderTestTitle').textContent = '🔧 ' + activeTestData.title;
    document.getElementById('builderTestMeta').textContent = `Status: ${activeTestData.status} · Duration: ${activeTestData.duration_minutes||60} min`;
    switchBuilderTab('questions');
    openModal('builderModal');
    await loadBuilderQuestions();
}

function switchBuilderTab(tab) {
    ['questions','ai','manual'].forEach(t => {
        document.getElementById(`tab-${t}`).classList.toggle('active', t===tab);
        document.getElementById(`tab-panel-${t}`).style.display = t===tab ? '' : 'none';
    });
}

async function loadBuilderQuestions() {
    const r = await fetch(`${AJAX}?action=test_questions&test_id=${activeTestId}`);
    const j = await r.json();
    if (j.status !== 'success') return;
    const qs = j.data.questions;
    document.getElementById('qCountBadge').textContent = qs.length;

    if (!qs.length) {
        document.getElementById('qBuilderList').innerHTML = `<div class="empty-state"><span class="icon">📭</span>No questions yet. Use AI Generate or Add Manually.</div>`;
        return;
    }

    document.getElementById('qBuilderList').innerHTML = qs.map((q, i) => {
        const opts = ['A','B','C','D'].map(o => {
            const val = q[`option_${o.toLowerCase()}`] || '';
            const isCorrect = q.correct_option === o;
            return `<div class="q-opt${isCorrect?' correct':''}"><strong>${o}.</strong> ${esc(val)}</div>`;
        }).join('');
        return `<div class="q-card">
            <span class="q-num">Q${i+1}</span>
            <div class="q-text">${esc(q.question_text)}</div>
            <div class="q-opts">${opts}</div>
            ${q.explanation ? `<div style="font-size:.73rem;color:var(--text-muted);margin:.4rem 0 0 2rem">💡 ${esc(q.explanation)}</div>` : ''}
            <div class="q-actions">
                <button onclick="openEditQ(${q.id}, ${activeTestId})" title="Edit">✏️</button>
                <button onclick="dupQ(${q.id})" title="Duplicate">📋</button>
                <button onclick="delQ(${q.id})" title="Remove" style="color:#fca5a5">🗑</button>
            </div>
            <div style="margin:.4rem 0 0 2rem;font-size:.7rem;color:var(--text-muted)">
                <span class="sp sp-${q.difficulty}">${q.difficulty}</span>
                &nbsp;${q.tq_marks||q.q_marks||1} mark${q.tq_neg>0?' · -'+q.tq_neg+' neg':''}
            </div>
        </div>`;
    }).join('');
}

async function delQ(qId) {
    if (!confirm('Remove this question from the test?')) return;
    const r = await fetch(`${AJAX}?action=delete_question`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({_csrf:CSRF, test_id:activeTestId, question_id:qId})});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast('Question removed', 'success');
    loadBuilderQuestions();
}

async function dupQ(qId) {
    const r = await fetch(`${AJAX}?action=duplicate_question`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({_csrf:CSRF, test_id:activeTestId, question_id:qId})});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast('Question duplicated', 'success');
    loadBuilderQuestions();
}

async function openEditQ(qId, testId) {
    const r = await fetch(`${AJAX}?action=test_questions&test_id=${testId}`);
    const j = await r.json();
    const q = (j.data.questions || []).find(x => x.id === qId);
    if (!q) { showToast('Question not found', 'error'); return; }
    document.getElementById('eq_question_id').value = qId;
    document.getElementById('eq_test_id').value = testId;
    document.getElementById('eq_text').value = q.question_text;
    ['a','b','c','d'].forEach(o => { const el=document.getElementById(`eq_opt_${o}`); if(el) el.value=q[`option_${o}`]||''; });
    const correct = q.correct_option || 'A';
    const r2 = document.getElementById(`eq_correct_${correct}`);
    if (r2) r2.checked = true;
    document.getElementById('eq_difficulty').value = q.difficulty || 'medium';
    document.getElementById('eq_marks').value = q.tq_marks || q.q_marks || 1;
    document.getElementById('eq_neg_marks').value = q.tq_neg || q.q_neg || 0;
    document.getElementById('eq_explanation').value = q.explanation || '';
    openModal('editQModal');
}

async function saveEditQuestion() {
    const qId = document.getElementById('eq_question_id').value;
    const testId = document.getElementById('eq_test_id').value;
    const correctEl = document.querySelector('input[name="eq_correct"]:checked');
    if (!correctEl) { showToast('Select the correct answer', 'error'); return; }
    const body = {
        _csrf: CSRF, question_id: parseInt(qId), test_id: parseInt(testId),
        question_text: document.getElementById('eq_text').value.trim(),
        option_a: document.getElementById('eq_opt_a').value,
        option_b: document.getElementById('eq_opt_b').value,
        option_c: document.getElementById('eq_opt_c').value,
        option_d: document.getElementById('eq_opt_d').value,
        correct_option: correctEl.value,
        difficulty: document.getElementById('eq_difficulty').value,
        marks: parseFloat(document.getElementById('eq_marks').value),
        negative_marks: parseFloat(document.getElementById('eq_neg_marks').value),
        explanation: document.getElementById('eq_explanation').value,
    };
    const r = await fetch(`${AJAX}?action=update_question`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast('Question updated!', 'success');
    closeModal('editQModal');
    loadBuilderQuestions();
}

// ── AI Generate ───────────────────────────────────────────────────────────
let aiQuestions = [];
async function runAiGenerate() {
    const btn = document.getElementById('btnAiGenerate');
    btn.disabled = true; btn.innerHTML = '<span>⏳</span> Generating…';
    const body = {
        _csrf: CSRF,
        test_id: activeTestId,
        subject_id: document.getElementById('ai_subject_id').value || null,
        topic: document.getElementById('ai_topic').value,
        count: parseInt(document.getElementById('ai_count').value),
        difficulty: document.getElementById('ai_difficulty').value,
        question_type: document.getElementById('ai_qtype').value,
        language: document.getElementById('ai_language').value,
    };
    try {
        const r = await fetch(`${AJAX}?action=ai_generate`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)});
        const j = await r.json();
        if (j.status !== 'success') { showToast(j.message, 'error'); return; }
        aiQuestions = j.data.questions;
        renderAiCards(aiQuestions);
        document.getElementById('aiPreviewArea').style.display = '';
        if (j.data.is_fallback) showToast('Sample questions shown. Add a Gemini/OpenAI key in AI Generator settings for real AI generation.', 'info');
        else showToast(`${aiQuestions.length} questions generated!`, 'success');
    } catch(e) {
        showToast('AI generation failed: ' + e.message, 'error');
    } finally {
        btn.disabled = false; btn.innerHTML = '<span>✨</span> Generate Questions';
    }
}

function renderAiCards(qs) {
    const area = document.getElementById('aiCardsList');
    area.innerHTML = qs.map((q, i) => {
        const opts = ['a','b','c','d'].filter(o => q[`option_${o}`]).map(o => {
            const isCorrect = q.correct_option && q.correct_option.toLowerCase() === o;
            return `<div class="ai-opt${isCorrect?' correct':''}"><strong>${o.toUpperCase()}.</strong> ${esc(q[`option_${o}`])}</div>`;
        }).join('');
        return `<div class="ai-card">
            <input type="checkbox" class="ai-chk" id="aichk_${i}" data-idx="${i}" checked>
            <div class="ai-body">
                <div class="ai-q">${esc(q.question_text)}</div>
                <div class="ai-opts">${opts}</div>
                ${q.explanation ? `<div style="font-size:.73rem;color:var(--text-muted);margin-top:.4rem">💡 ${esc(q.explanation)}</div>` : ''}
                <div style="font-size:.7rem;color:var(--text-muted);margin-top:.3rem"><span class="sp sp-${q.difficulty}">${q.difficulty}</span> &nbsp; ${q.marks||1} mark</div>
            </div>
            <div class="ai-actions">
                <button onclick="regenOneAi(${i})" title="Regenerate">🔄</button>
            </div>
        </div>`;
    }).join('');
}

function selectAllAi(val) {
    document.querySelectorAll('.ai-chk').forEach(c => c.checked = val);
}

function regenOneAi(idx) {
    // Shuffle options as a quick local regen visual
    const q = aiQuestions[idx];
    if (q) showToast('Re-generate by clicking "Generate Questions" again with updated settings.', 'info');
}

async function addSelectedAiToTest() {
    const selected = [];
    document.querySelectorAll('.ai-chk:checked').forEach(c => {
        const idx = parseInt(c.dataset.idx);
        if (aiQuestions[idx]) selected.push(aiQuestions[idx]);
    });
    if (!selected.length) { showToast('Select at least one question', 'error'); return; }
    const body = {_csrf: CSRF, test_id: activeTestId, questions: selected};
    const r = await fetch(`${AJAX}?action=add_questions`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast(j.message, 'success');
    document.getElementById('aiPreviewArea').style.display = 'none';
    aiQuestions = [];
    switchBuilderTab('questions');
    loadBuilderQuestions();
    loadTests();
}

// ── Manual Question ───────────────────────────────────────────────────────
function clearManualForm() {
    document.getElementById('mq_text').value = '';
    ['a','b','c','d'].forEach(o => { document.getElementById(`mq_opt_${o}`).value = ''; });
    document.getElementById('mq_explanation').value = '';
    document.getElementById('mq_marks').value = 1;
    document.getElementById('mq_neg_marks').value = 0;
    document.getElementById('mq_difficulty').value = 'medium';
    const r = document.getElementById('mq_correct_A'); if (r) r.checked = true;
}

async function submitManualQuestion() {
    const text = document.getElementById('mq_text').value.trim();
    if (!text) { showToast('Question text is required', 'error'); return; }
    const correctEl = document.querySelector('input[name="mq_correct"]:checked');
    if (!correctEl) { showToast('Select the correct answer option', 'error'); return; }
    const body = {
        _csrf: CSRF, test_id: activeTestId,
        question_text: text,
        question_type: 'MCQ',
        option_a: document.getElementById('mq_opt_a').value,
        option_b: document.getElementById('mq_opt_b').value,
        option_c: document.getElementById('mq_opt_c').value,
        option_d: document.getElementById('mq_opt_d').value,
        correct_option: correctEl.value,
        difficulty: document.getElementById('mq_difficulty').value,
        marks: parseFloat(document.getElementById('mq_marks').value) || 1,
        negative_marks: parseFloat(document.getElementById('mq_neg_marks').value) || 0,
        explanation: document.getElementById('mq_explanation').value,
    };
    const r = await fetch(`${AJAX}?action=add_manual_question`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast('Question added!', 'success');
    clearManualForm();
    switchBuilderTab('questions');
    loadBuilderQuestions();
    loadTests();
}

// ── Publish Flow ──────────────────────────────────────────────────────────
async function openPublishFlow(testId) {
    activeTestId = testId;
    const r = await fetch(`${AJAX}?action=get_test&id=${testId}`);
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    const t = j.data;
    activeTestData = t;

    const qr = await fetch(`${AJAX}?action=test_questions&test_id=${testId}`);
    const qj = await qr.json();
    const qCount = qj.data?.count || 0;

    document.getElementById('publishConfirmInfo').innerHTML = `
        <strong style="color:#fff">${esc(t.title)}</strong><br>
        Questions: <strong style="color:#86efac">${qCount}</strong> &nbsp;|&nbsp;
        Duration: <strong>${t.duration_minutes||60} min</strong> &nbsp;|&nbsp;
        Marks: <strong>${t.total_marks||0}</strong> &nbsp;|&nbsp;
        Passing: <strong>${t.passing_marks||0}</strong>
        ${t.start_time ? `<br>Scheduled: <strong>${t.start_time}</strong> → ${t.end_time||'Open ended'}` : ''}
    `;
    openModal('publishConfirmModal');
}

function confirmPublish() {
    if (!activeTestId) return;
    closeModal('builderModal');
    closeModal('previewModal');
    openPublishFlow(activeTestId);
}

async function doPublish() {
    document.getElementById('btnDoPublish').disabled = true;
    document.getElementById('btnDoPublish').textContent = '⏳ Publishing…';
    const r = await fetch(`${AJAX}?action=publish`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({_csrf:CSRF, test_id:activeTestId})});
    const j = await r.json();
    document.getElementById('btnDoPublish').disabled = false;
    document.getElementById('btnDoPublish').innerHTML = '🚀 Yes, Publish Now';
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast('🎉 Test published! Students can now see it.', 'success');
    closeModal('publishConfirmModal');
    loadTests();
}

async function unpublishTest(testId) {
    if (!confirm('Unpublish this test? Students will no longer see it.')) return;
    const r = await fetch(`${AJAX}?action=unpublish`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({_csrf:CSRF, test_id:testId})});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast(j.message, 'success');
    loadTests();
}

// ── Preview ───────────────────────────────────────────────────────────────
async function openPreview(testId) {
    activeTestId = testId;
    const [tr, qr] = await Promise.all([
        fetch(`${AJAX}?action=get_test&id=${testId}`).then(r=>r.json()),
        fetch(`${AJAX}?action=test_questions&test_id=${testId}`).then(r=>r.json()),
    ]);
    const t = tr.data;
    const qs = qr.data?.questions || [];
    const statusClass = `sp-${t.status}`;

    let html = `
        <div style="background:rgba(255,255,255,.025);border:1px solid rgba(148,163,184,.15);border-radius:10px;padding:1.25rem;margin-bottom:1.25rem">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:1rem">
                <div>
                    <div style="font-size:1.2rem;font-weight:800;color:#fff">${esc(t.title)}</div>
                    ${t.description ? `<div style="color:var(--text-muted);font-size:.84rem;margin-top:.3rem">${esc(t.description)}</div>` : ''}
                </div>
                <span class="sp ${statusClass}">${t.status?.replace('_',' ')}</span>
            </div>
            <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:.75rem;font-size:.8rem">
                ${infoBox('📋 Questions', qs.length + ' / ' + (t.total_questions||'?'))}
                ${infoBox('⭐ Total Marks', t.total_marks||0)}
                ${infoBox('⏱ Duration', (t.duration_minutes||60)+' min')}
                ${infoBox('🎯 Passing', t.passing_marks||0+' marks')}
                ${infoBox('➖ Negative', t.negative_marking||0+' per Q')}
                ${infoBox('📊 Difficulty', t.difficulty)}
            </div>
            ${t.instructions ? `<div style="margin-top:1rem;padding:.75rem;background:rgba(245,158,11,.06);border-radius:8px;font-size:.82rem;color:var(--text-secondary)"><strong style="color:#fcd34d">📌 Instructions:</strong><br>${esc(t.instructions)}</div>` : ''}
        </div>
        <div style="font-size:.85rem;font-weight:700;color:#fff;margin-bottom:.75rem">Questions (${qs.length})</div>
    `;

    if (!qs.length) {
        html += `<div class="empty-state"><span class="icon">📭</span>No questions added yet.</div>`;
    } else {
        html += qs.map((q, i) => {
            const opts = ['A','B','C','D'].map(o => {
                const val = q[`option_${o.toLowerCase()}`] || '';
                const isCorrect = q.correct_option === o;
                return `<div style="padding:.3rem .6rem;border-radius:6px;border:1px solid rgba(148,163,184,.2);font-size:.8rem;color:${isCorrect?'#86efac':'var(--text-muted)'};background:${isCorrect?'rgba(34,197,94,.08)':'transparent'};border-color:${isCorrect?'rgba(34,197,94,.4)':'rgba(148,163,184,.2)'}">
                    <strong>${o}.</strong> ${esc(val)}
                </div>`;
            }).join('');
            return `<div style="background:rgba(255,255,255,.02);border:1px solid rgba(148,163,184,.12);border-radius:9px;padding:1rem;margin-bottom:.65rem">
                <div style="font-size:.88rem;color:#fff;margin-bottom:.6rem"><strong style="color:var(--text-muted)">Q${i+1}.</strong> ${esc(q.question_text)}</div>
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:.35rem">${opts}</div>
                ${q.explanation ? `<div style="font-size:.73rem;color:var(--text-muted);margin-top:.5rem">💡 ${esc(q.explanation)}</div>` : ''}
                <div style="font-size:.7rem;color:var(--text-muted);margin-top:.4rem"><span class="sp sp-${q.difficulty}">${q.difficulty}</span> ${q.tq_marks||q.q_marks||1} mark</div>
            </div>`;
        }).join('');
    }

    document.getElementById('previewContent').innerHTML = html;
    openModal('previewModal');
}

function infoBox(label, value) {
    return `<div style="background:rgba(255,255,255,.025);border-radius:7px;padding:.6rem .8rem">
        <div style="font-size:.7rem;color:var(--text-muted)">${label}</div>
        <div style="font-weight:700;color:#fff;font-size:.9rem">${value}</div>
    </div>`;
}

// ── Attempts & Results ────────────────────────────────────────────────────
let currentAttemptsTestId = null;
async function openAttempts(testId) {
    currentAttemptsTestId = testId;
    const r = await fetch(`${AJAX}?action=attempts&test_id=${testId}`);
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    const {attempts, results_published, test_title, passing_marks, count} = j.data;
    document.getElementById('attemptsTestTitle').textContent = test_title;
    document.getElementById('btnToggleResults').textContent = results_published ? '🙈 Hide Results from Students' : '👁 Show Results to Students';

    let html = `<div style="font-size:.82rem;color:var(--text-muted);margin-bottom:1rem">
        ${count} attempts · Passing: ${passing_marks} marks ·
        Results: <strong style="color:${results_published?'#86efac':'#fca5a5'}">${results_published?'Visible to Students':'Hidden'}</strong>
    </div>`;

    if (!attempts.length) {
        html += `<div class="empty-state"><span class="icon">📊</span>No students have attempted this test yet.</div>`;
    } else {
        html += `<table style="width:100%;border-collapse:collapse;font-size:.83rem">
            <thead><tr>
                <th style="text-align:left;padding:.5rem .6rem;color:var(--text-muted);font-size:.7rem;text-transform:uppercase;border-bottom:1px solid rgba(148,163,184,.15)">Student</th>
                <th style="text-align:left;padding:.5rem .6rem;color:var(--text-muted);font-size:.7rem;text-transform:uppercase;border-bottom:1px solid rgba(148,163,184,.15)">Score</th>
                <th style="text-align:left;padding:.5rem .6rem;color:var(--text-muted);font-size:.7rem;text-transform:uppercase;border-bottom:1px solid rgba(148,163,184,.15)">%</th>
                <th style="text-align:left;padding:.5rem .6rem;color:var(--text-muted);font-size:.7rem;text-transform:uppercase;border-bottom:1px solid rgba(148,163,184,.15)">Result</th>
                <th style="text-align:left;padding:.5rem .6rem;color:var(--text-muted);font-size:.7rem;text-transform:uppercase;border-bottom:1px solid rgba(148,163,184,.15)">Submitted</th>
            </tr></thead><tbody>`;
        attempts.forEach(a => {
            const passed = passing_marks > 0 ? (parseFloat(a.marks_obtained) >= parseFloat(passing_marks)) : null;
            const badge  = passed === null ? '' : passed
                ? `<span class="sp" style="background:rgba(34,197,94,.15);color:#86efac;border:1px solid rgba(34,197,94,.3)">PASS</span>`
                : `<span class="sp" style="background:rgba(239,68,68,.15);color:#fca5a5;border:1px solid rgba(239,68,68,.3)">FAIL</span>`;
            html += `<tr>
                <td style="padding:.55rem .6rem;border-bottom:1px solid rgba(148,163,184,.07)">
                    <div style="font-weight:600;color:#fff">${esc(a.student_name)}</div>
                    <div style="font-size:.72rem;color:var(--text-muted)">${esc(a.student_email||'')}</div>
                </td>
                <td style="padding:.55rem .6rem;border-bottom:1px solid rgba(148,163,184,.07);color:#fff;font-weight:700">${(+a.marks_obtained||0).toFixed(1)} / ${(+a.max_marks||0).toFixed(1)}</td>
                <td style="padding:.55rem .6rem;border-bottom:1px solid rgba(148,163,184,.07);color:#a5b4fc">${a.percentage||0}%</td>
                <td style="padding:.55rem .6rem;border-bottom:1px solid rgba(148,163,184,.07)">${badge}</td>
                <td style="padding:.55rem .6rem;border-bottom:1px solid rgba(148,163,184,.07);font-size:.75rem;color:var(--text-muted)">${fmt(a.submitted_at)}</td>
            </tr>`;
        });
        html += '</tbody></table>';
    }
    document.getElementById('attemptsContent').innerHTML = html;
    openModal('attemptsModal');
}

async function toggleResults() {
    if (!currentAttemptsTestId) return;
    const r = await fetch(`${AJAX}?action=toggle_results`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({_csrf:CSRF, test_id:currentAttemptsTestId})});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast(j.message, 'success');
    openAttempts(currentAttemptsTestId);
}

// ── Delete Test ───────────────────────────────────────────────────────────
async function deleteTest(testId) {
    if (!confirm('Delete this test? This cannot be undone.')) return;
    const r = await fetch(`${AJAX}?action=delete_test`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({_csrf:CSRF, test_id:testId})});
    const j = await r.json();
    if (j.status !== 'success') { showToast(j.message,'error'); return; }
    showToast('Test deleted', 'success');
    loadTests();
}

// ── Utilities ─────────────────────────────────────────────────────────────
function openModal(id)  { document.getElementById(id).style.display = 'block'; document.body.style.overflow = 'hidden'; }
function closeModal(id) { document.getElementById(id).style.display = 'none'; document.body.style.overflow = ''; }

function showToast(msg, type='success') {
    const toast = document.createElement('div');
    const colors = {success:'rgba(34,197,94,.9)', error:'rgba(239,68,68,.9)', info:'rgba(99,102,241,.9)'};
    toast.style.cssText = `position:fixed;bottom:1.5rem;right:1.5rem;z-index:9999;background:${colors[type]||colors.success};color:#fff;padding:.75rem 1.25rem;border-radius:10px;font-size:.85rem;font-weight:600;max-width:360px;box-shadow:0 8px 24px rgba(0,0,0,.35);backdrop-filter:blur(8px);transition:opacity .3s`;
    toast.textContent = msg;
    document.body.appendChild(toast);
    setTimeout(() => { toast.style.opacity=0; setTimeout(()=>toast.remove(),300); }, 3500);
}

function esc(str) { return String(str||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function fmt(dt) { if (!dt) return '—'; const d=new Date(dt); return isNaN(d)?dt:d.toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}); }

// Close modals on backdrop click
['createModal','builderModal','previewModal','publishConfirmModal','attemptsModal','editQModal'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('click', e => { if (e.target === el) closeModal(id); });
});
</script>
