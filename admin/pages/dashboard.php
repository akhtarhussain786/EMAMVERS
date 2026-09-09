<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

// 1. LIVE SUMMARY METRICS DIRECT FROM MYSQL TABLES WITH SAFE WRAPPERS
$totalStudents = 0;
$activeTeachers = 0;
$totalQuestions = 0;
$approvedQuestions = 0;
$pendingQuestions = 0;
$rejectedQuestions = 0;
$totalTopics = 0;

$exactDuplicates = 0;
$nearDuplicates = 0;
$answerConflicts = 0;
$languageVariants = 0;
$duplicateClusters = 0;
$totalDuplicateFlags = 0;

$liveTests = 0;
$totalAttempts = 0;
$revenueMtd = 0.0;

$teacherAppsCount = 0;
$docsPendingCount = 0;
$underReviewCount = 0;
$verifiedTeachersCount = 0;

try { $totalStudents = (int)$db->query("SELECT COUNT(*) FROM users WHERE user_type = 'student' OR user_type IS NULL")->fetchColumn(); } catch (Exception $e) {}
try { $activeTeachers = (int)$db->query("SELECT COUNT(*) FROM users WHERE user_type = 'teacher'")->fetchColumn(); } catch (Exception $e) {}
try { $totalQuestions = (int)$db->query("SELECT COUNT(*) FROM questions")->fetchColumn(); } catch (Exception $e) {}
try { $approvedQuestions = (int)$db->query("SELECT COUNT(*) FROM questions WHERE status IN ('approved', 'published')")->fetchColumn(); } catch (Exception $e) {}
try { $pendingQuestions = (int)$db->query("SELECT COUNT(*) FROM questions WHERE status = 'pending_review' OR status = 'draft'")->fetchColumn(); } catch (Exception $e) {}
try { $rejectedQuestions = (int)$db->query("SELECT COUNT(*) FROM questions WHERE status = 'rejected'")->fetchColumn(); } catch (Exception $e) {}
try { $totalTopics = (int)$db->query("SELECT COUNT(DISTINCT topic_id) FROM questions WHERE topic_id IS NOT NULL")->fetchColumn(); } catch (Exception $e) {}

// Duplicates & Flags
try { $exactDuplicates = (int)$db->query("SELECT COUNT(*) FROM question_duplicate_candidates WHERE match_method = 'exact_hash' OR status = 'pending'")->fetchColumn(); } catch (Exception $e) {}
try { $nearDuplicates = (int)$db->query("SELECT COUNT(*) FROM question_duplicate_candidates WHERE match_method = 'structure_hash'")->fetchColumn(); } catch (Exception $e) {}
try { $answerConflicts = (int)$db->query("SELECT COUNT(*) FROM question_reports WHERE report_reason = 'wrong_answer'")->fetchColumn(); } catch (Exception $e) {}
try { $languageVariants = (int)$db->query("SELECT COUNT(*) FROM question_translations WHERE language != 'en'")->fetchColumn(); } catch (Exception $e) {}
try { $duplicateClusters = (int)$db->query("SELECT COUNT(*) FROM question_duplicate_clusters")->fetchColumn(); } catch (Exception $e) {}
try { $reportsCount = (int)$db->query("SELECT COUNT(*) FROM question_reports")->fetchColumn(); } catch (Exception $e) { $reportsCount = 0; }
$totalDuplicateFlags = $exactDuplicates + $nearDuplicates + $reportsCount;

// Tests & Revenue
try { $liveTests = (int)$db->query("SELECT COUNT(*) FROM tests WHERE status = 'published'")->fetchColumn(); } catch (Exception $e) {}
try { $totalAttempts = (int)$db->query("SELECT COUNT(*) FROM test_attempts")->fetchColumn(); } catch (Exception $e) {}
try { $revenueMtd = (float)$db->query("SELECT COALESCE(SUM(p.price), 0) FROM user_subscriptions us JOIN subscription_plans p ON us.plan_id = p.id WHERE us.status IN ('active', 'trial')")->fetchColumn(); } catch (Exception $e) {}

// Teacher KYC Counts
try { $teacherAppsCount = (int)$db->query("SELECT COUNT(*) FROM teacher_applications WHERE status = 'submitted'")->fetchColumn(); } catch (Exception $e) {}
try { $docsPendingCount = (int)$db->query("SELECT COUNT(*) FROM teacher_documents WHERE verification_status = 'pending'")->fetchColumn(); } catch (Exception $e) {}
try { $underReviewCount = (int)$db->query("SELECT COUNT(*) FROM teacher_applications WHERE status = 'under_review'")->fetchColumn(); } catch (Exception $e) {}
try { $verifiedTeachersCount = (int)$db->query("SELECT COUNT(*) FROM teacher_applications WHERE status = 'approved'")->fetchColumn(); } catch (Exception $e) {}

// 2. LIVE TABLES QUERY
// 2.1 Live Teacher Applications
$teacherKycList = [];
try {
    $teacherKycList = $db->query("
        SELECT ta.id, ta.application_no, ta.status, u.full_name,
               (SELECT COUNT(*) FROM teacher_documents td WHERE td.application_id = ta.id AND td.verification_status = 'pending') as pending_docs,
               (SELECT COUNT(*) FROM teacher_documents td WHERE td.application_id = ta.id AND td.verification_status = 'verified') as verified_docs
        FROM teacher_applications ta
        JOIN users u ON ta.user_id = u.id
        ORDER BY ta.id DESC LIMIT 4
    ")->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {}

// 2.2 Live Test Management Table
$recentTests = [];
try {
    $recentTests = $db->query("
        SELECT t.id, t.title, COALESCE(e.title, 'Competitive Exam') as exam_title, t.status, t.created_at,
               (SELECT COUNT(*) FROM test_attempts att WHERE att.test_id = t.id) as attempts_count
        FROM tests t
        LEFT JOIN exams e ON t.exam_id = e.id
        ORDER BY t.id DESC LIMIT 5
    ")->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {}

// 2.3 Live Review Queue / Flagged Questions
$reviewItems = [];
try {
    $reviewItems = $db->query("
        SELECT q.id, COALESCE(u.full_name, 'Teacher Contributor') as author_name,
               COALESCE(s.name, 'General Subject') as subject_name,
               q.status, q.difficulty, q.created_at
        FROM questions q
        LEFT JOIN users u ON q.author_user_id = u.id
        LEFT JOIN subjects s ON q.subject_id = s.id
        ORDER BY q.id DESC LIMIT 4
    ")->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {}

// Dynamic percentages
$approvalRatePct = $totalQuestions > 0 ? round(($approvedQuestions / $totalQuestions) * 100, 1) : 100.0;
$pendingRatePct = $totalQuestions > 0 ? round(($pendingQuestions / $totalQuestions) * 100, 1) : 0.0;
$rejectedRatePct = $totalQuestions > 0 ? round(($rejectedQuestions / $totalQuestions) * 100, 1) : 0.0;
?>

<!-- 1. TOP 6 KPI STAT CARDS (REAL DATABASE COUNTS) -->
<div class="stat-cards-grid">
    <!-- Card 1: Total Students -->
    <div class="stat-card-modern">
        <div class="stat-card-header">
            <span class="stat-card-title">Total Students</span>
            <div class="stat-card-icon" style="background:#dbeafe;color:#2563eb;">
                <svg fill="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;"><path d="M12 3L1 9l4 2.18v6L12 21l7-3.82v-6l2-1.09V17h2V9L12 3z"/></svg>
            </div>
        </div>
        <div class="stat-card-value"><?php echo number_format($totalStudents); ?></div>
        <div class="stat-card-trend trend-up">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:14px;height:14px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            Live Registered <span style="color:#64748b;font-weight:400;">candidates</span>
        </div>
    </div>

    <!-- Card 2: Active Teachers -->
    <div class="stat-card-modern">
        <div class="stat-card-header">
            <span class="stat-card-title">Active Teachers</span>
            <div class="stat-card-icon" style="background:#dcfce7;color:#10b981;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
            </div>
        </div>
        <div class="stat-card-value"><?php echo number_format($activeTeachers); ?></div>
        <div class="stat-card-trend trend-up">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:14px;height:14px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            Verified <span style="color:#64748b;font-weight:400;">educators</span>
        </div>
    </div>

    <!-- Card 3: Questions in Bank -->
    <div class="stat-card-modern">
        <div class="stat-card-header">
            <span class="stat-card-title">Questions in Bank</span>
            <div class="stat-card-icon" style="background:#f3e8ff;color:#8b5cf6;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            </div>
        </div>
        <div class="stat-card-value"><?php echo number_format($totalQuestions); ?></div>
        <div class="stat-card-trend trend-up">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:14px;height:14px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            <?php echo $approvalRatePct; ?>% <span style="color:#64748b;font-weight:400;">approval rate</span>
        </div>
    </div>

    <!-- Card 4: Duplicate Flags -->
    <div class="stat-card-modern">
        <div class="stat-card-header">
            <span class="stat-card-title">Duplicate & Dispute Flags</span>
            <div class="stat-card-icon" style="background:#ffedd5;color:#f97316;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"/></svg>
            </div>
        </div>
        <div class="stat-card-value"><?php echo number_format($totalDuplicateFlags); ?></div>
        <div class="stat-card-trend trend-up">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:14px;height:14px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            AI Fingerprinted <span style="color:#64748b;font-weight:400;">candidates</span>
        </div>
    </div>

    <!-- Card 5: Live Tests -->
    <div class="stat-card-modern">
        <div class="stat-card-header">
            <span class="stat-card-title">Live Tests</span>
            <div class="stat-card-icon" style="background:#cffafe;color:#06b6d4;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            </div>
        </div>
        <div class="stat-card-value"><?php echo number_format($liveTests); ?></div>
        <div class="stat-card-trend trend-up">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:14px;height:14px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            <?php echo number_format($totalAttempts); ?> <span style="color:#64748b;font-weight:400;">total attempts</span>
        </div>
    </div>

    <!-- Card 6: Revenue MTD -->
    <div class="stat-card-modern">
        <div class="stat-card-header">
            <span class="stat-card-title">Subscription Revenue</span>
            <div class="stat-card-icon" style="background:#e0e7ff;color:#4f46e5;">
                <span style="font-weight:800;font-size:16px;">₹</span>
            </div>
        </div>
        <div class="stat-card-value">₹<?php echo number_format($revenueMtd, 2); ?></div>
        <div class="stat-card-trend trend-up">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:14px;height:14px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
            Active <span style="color:#64748b;font-weight:400;">entitlements</span>
        </div>
    </div>
</div>

<!-- 2. ROW 1: QUESTION BANK MANAGEMENT + DUPLICATES + TEACHER VERIFICATION -->
<div class="dash-row-3">
    <!-- 2.1 Question Bank Management -->
    <div class="card">
        <div class="card-header-flex">
            <div class="card-title-main">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;color:#2563eb;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                Question Bank Management
            </div>
            <a href="index.php?page=questions" class="card-link-action">View Question Bank →</a>
        </div>

        <!-- Filter Dropdowns Grid -->
        <div style="display:grid;grid-template-columns:repeat(3, 1fr);gap:8px;margin-bottom:14px;">
            <select class="form-control" style="font-size:11.5px;padding:6px 8px;" onchange="window.location.href='index.php?page=questions'"><option>All Exams</option><option>SSC CGL</option><option>JEE Main</option><option>NEET UG</option></select>
            <select class="form-control" style="font-size:11.5px;padding:6px 8px;" onchange="window.location.href='index.php?page=questions'"><option>All Subjects</option><option>Quant</option><option>Reasoning</option><option>General Awareness</option></select>
            <select class="form-control" style="font-size:11.5px;padding:6px 8px;" onchange="window.location.href='index.php?page=questions'"><option>All Topics</option><option>Arithmetic</option><option>Algebra</option></select>
            <select class="form-control" style="font-size:11.5px;padding:6px 8px;" onchange="window.location.href='index.php?page=questions'"><option>All Levels</option><option>Easy</option><option>Medium</option><option>Hard</option></select>
            <select class="form-control" style="font-size:11.5px;padding:6px 8px;" onchange="window.location.href='index.php?page=questions'"><option>All Sources</option><option>PYQ</option><option>Teacher</option><option>AI</option></select>
            <select class="form-control" style="font-size:11.5px;padding:6px 8px;" onchange="window.location.href='index.php?page=questions'"><option>All Statuses</option><option>Approved</option><option>Pending</option></select>
        </div>

        <!-- Mini Stats Badges Strip (Live Database Breakdown) -->
        <div style="display:grid;grid-template-columns:repeat(5, 1fr);gap:6px;background:#f8fafc;padding:10px;border-radius:8px;border:1px solid #e2e8f0;text-align:center;">
            <div>
                <div style="font-size:10px;color:#64748b;font-weight:600;">Total Questions</div>
                <div style="font-size:13px;font-weight:800;color:#0f172a;margin-top:2px;"><?php echo number_format($totalQuestions); ?></div>
            </div>
            <div>
                <div style="font-size:10px;color:#15803d;font-weight:600;">Approved</div>
                <div style="font-size:13px;font-weight:800;color:#15803d;margin-top:2px;"><?php echo number_format($approvedQuestions); ?> <span style="font-size:9px;"><?php echo $approvalRatePct; ?>%</span></div>
            </div>
            <div>
                <div style="font-size:10px;color:#b45309;font-weight:600;">Pending Review</div>
                <div style="font-size:13px;font-weight:800;color:#b45309;margin-top:2px;"><?php echo number_format($pendingQuestions); ?> <span style="font-size:9px;"><?php echo $pendingRatePct; ?>%</span></div>
            </div>
            <div>
                <div style="font-size:10px;color:#b91c1c;font-weight:600;">Rejected</div>
                <div style="font-size:13px;font-weight:800;color:#b91c1c;margin-top:2px;"><?php echo number_format($rejectedQuestions); ?> <span style="font-size:9px;"><?php echo $rejectedRatePct; ?>%</span></div>
            </div>
            <div>
                <div style="font-size:10px;color:#64748b;font-weight:600;">Total Topics</div>
                <div style="font-size:13px;font-weight:800;color:#0f172a;margin-top:2px;"><?php echo number_format($totalTopics); ?></div>
            </div>
        </div>
    </div>

    <!-- 2.2 Duplicate Detection Overview -->
    <div class="card">
        <div class="card-header-flex">
            <div class="card-title-main">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;color:#2563eb;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
                Duplicate Detection Overview
            </div>
            <a href="index.php?page=question_duplicates" class="card-link-action">Open Duplicate Detection →</a>
        </div>

        <div style="display:grid;grid-template-columns:repeat(3, 1fr);gap:10px;margin-bottom:12px;">
            <div style="background:#fef2f2;border:1px solid #fee2e2;border-radius:8px;padding:8px;text-align:center;">
                <div style="font-size:10px;color:#b91c1c;font-weight:600;">Exact Clones</div>
                <div style="font-size:16px;font-weight:800;color:#991b1b;margin-top:2px;"><?php echo number_format($exactDuplicates); ?></div>
            </div>
            <div style="background:#fffbeb;border:1px solid #fef3c7;border-radius:8px;padding:8px;text-align:center;">
                <div style="font-size:10px;color:#b45309;font-weight:600;">Near Duplicates</div>
                <div style="font-size:16px;font-weight:800;color:#92400e;margin-top:2px;"><?php echo number_format($nearDuplicates); ?></div>
            </div>
            <div style="background:#faf5ff;border:1px solid #f3e8ff;border-radius:8px;padding:8px;text-align:center;">
                <div style="font-size:10px;color:#7e22ce;font-weight:600;">Answer Conflicts</div>
                <div style="font-size:16px;font-weight:800;color:#6b21a8;margin-top:2px;"><?php echo number_format($answerConflicts); ?></div>
            </div>
        </div>

        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:14px;">
            <div style="background:#eff6ff;border:1px solid #dbeafe;border-radius:8px;padding:8px;text-align:center;">
                <div style="font-size:10px;color:#1d4ed8;font-weight:600;">Language Variants</div>
                <div style="font-size:15px;font-weight:800;color:#1e40af;margin-top:2px;"><?php echo number_format($languageVariants); ?></div>
            </div>
            <div style="background:#f0fdf4;border:1px solid #dcfce7;border-radius:8px;padding:8px;text-align:center;">
                <div style="font-size:10px;color:#15803d;font-weight:600;">Duplicate Clusters</div>
                <div style="font-size:15px;font-weight:800;color:#166534;margin-top:2px;"><?php echo number_format($duplicateClusters); ?></div>
            </div>
        </div>

        <div style="display:flex;justify-content:space-between;align-items:center;font-size:11px;color:#64748b;border-top:1px solid #f1f5f9;padding-top:10px;">
            <span>Fingerprints: SHA-256 + Numeric Structure</span>
            <a href="index.php?page=question_duplicates" class="btn btn-outline btn-sm">🔄 Run Governance Scan</a>
        </div>
    </div>

    <!-- 2.3 Teacher Verification Live Table -->
    <div class="card">
        <div class="card-header-flex">
            <div class="card-title-main">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;color:#2563eb;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                Teacher KYC Verification
            </div>
            <a href="index.php?page=teacher_applications" class="card-link-action">View All (<?php echo $teacherAppsCount + $underReviewCount; ?>) →</a>
        </div>

        <div style="display:grid;grid-template-columns:repeat(4, 1fr);gap:6px;margin-bottom:12px;">
            <div style="background:#eff6ff;padding:6px;border-radius:6px;text-align:center;">
                <div style="font-size:9px;color:#1d4ed8;font-weight:600;">New Apps</div>
                <div style="font-size:14px;font-weight:800;color:#1e40af;"><?php echo $teacherAppsCount; ?></div>
            </div>
            <div style="background:#fff7ed;padding:6px;border-radius:6px;text-align:center;">
                <div style="font-size:9px;color:#c2410c;font-weight:600;">Docs Pending</div>
                <div style="font-size:14px;font-weight:800;color:#9a3412;"><?php echo $docsPendingCount; ?></div>
            </div>
            <div style="background:#faf5ff;padding:6px;border-radius:6px;text-align:center;">
                <div style="font-size:9px;color:#7e22ce;font-weight:600;">Under Review</div>
                <div style="font-size:14px;font-weight:800;color:#6b21a8;"><?php echo $underReviewCount; ?></div>
            </div>
            <div style="background:#f0fdf4;padding:6px;border-radius:6px;text-align:center;">
                <div style="font-size:9px;color:#15803d;font-weight:600;">Verified</div>
                <div style="font-size:14px;font-weight:800;color:#166534;"><?php echo $verifiedTeachersCount; ?></div>
            </div>
        </div>

        <div class="table-responsive">
            <table class="table" style="font-size:11.5px;">
                <thead>
                    <tr><th>Teacher</th><th>Application ID</th><th>Docs</th><th>Status</th><th></th></tr>
                </thead>
                <tbody>
                    <?php if (empty($teacherKycList)): ?>
                        <tr><td colspan="5" style="text-align:center;color:#64748b;padding:16px;">No teacher KYC applications yet.</td></tr>
                    <?php else: ?>
                        <?php foreach ($teacherKycList as $t): ?>
                            <?php
                                $badgeClass = 'badge-secondary';
                                if ($t['status'] === 'approved') $badgeClass = 'badge-success';
                                elseif ($t['status'] === 'under_review') $badgeClass = 'badge-warning';
                                elseif ($t['status'] === 'submitted') $badgeClass = 'badge-primary';
                            ?>
                            <tr>
                                <td style="font-weight:600;color:#0f172a;"><?php echo htmlspecialchars($t['full_name']); ?></td>
                                <td style="color:#64748b;"><?php echo htmlspecialchars($t['application_no']); ?></td>
                                <td>
                                    <?php if ($t['pending_docs'] > 0): ?>
                                        <span style="color:#f97316;font-weight:600;">Pending (<?php echo $t['pending_docs']; ?>)</span>
                                    <?php else: ?>
                                        <span style="color:#10b981;font-weight:600;">Verified</span>
                                    <?php endif; ?>
                                </td>
                                <td><span class="badge <?php echo $badgeClass; ?>" style="font-size:10px;"><?php echo strtoupper($t['status']); ?></span></td>
                                <td><a href="index.php?page=teacher_applications" style="color:#2563eb;text-decoration:none;">👁</a></td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- 3. ROW 2: LIVE TEST MANAGEMENT + REVIEW QUEUE -->
<div class="dash-row-2">
    <!-- 3.1 Live Test Management Table -->
    <div class="card">
        <div class="card-header-flex">
            <div class="card-title-main">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;color:#2563eb;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                Test Management Inventory
            </div>
            <a href="index.php?page=tests" class="card-link-action">Manage All Tests (<?php echo $liveTests; ?>) →</a>
        </div>

        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr><th>Test Name</th><th>Exam</th><th>Attempts</th><th>Date Created</th><th>Status</th><th>Actions</th></tr>
                </thead>
                <tbody>
                    <?php if (empty($recentTests)): ?>
                        <tr><td colspan="6" style="text-align:center;color:#64748b;padding:20px;">No tests created in inventory yet.</td></tr>
                    <?php else: ?>
                        <?php foreach ($recentTests as $test): ?>
                            <?php
                                $tBadge = 'badge-secondary';
                                if ($test['status'] === 'published') $tBadge = 'badge-success';
                                elseif ($test['status'] === 'draft') $tBadge = 'badge-secondary';
                                elseif ($test['status'] === 'archived') $tBadge = 'badge-danger';
                            ?>
                            <tr>
                                <td style="font-weight:700;color:#0f172a;"><?php echo htmlspecialchars($test['title']); ?></td>
                                <td><?php echo htmlspecialchars($test['exam_title']); ?></td>
                                <td style="color:#64748b;"><?php echo number_format($test['attempts_count']); ?> attempts</td>
                                <td style="color:#64748b;font-size:11.5px;"><?php echo date('d M Y', strtotime($test['created_at'])); ?></td>
                                <td><span class="badge <?php echo $tBadge; ?>"><?php echo strtoupper($test['status']); ?></span></td>
                                <td>
                                    <div style="display:flex;gap:6px;">
                                        <a href="index.php?page=tests" title="View Test" style="color:#64748b;text-decoration:none;">👁</a>
                                        <a href="index.php?page=tests" title="Edit Test" style="color:#2563eb;text-decoration:none;">✏️</a>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- 3.2 Live Review Queue Table -->
    <div class="card">
        <div class="card-header-flex">
            <div class="card-title-main">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;color:#2563eb;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                Question Bank Review Queue
            </div>
            <a href="index.php?page=question_review" class="card-link-action">View Full Queue →</a>
        </div>

        <div class="table-responsive">
            <table class="table">
                <thead>
                    <tr><th>Question ID</th><th>Author</th><th>Subject</th><th>Difficulty</th><th>Status</th><th>Actions</th></tr>
                </thead>
                <tbody>
                    <?php if (empty($reviewItems)): ?>
                        <tr><td colspan="6" style="text-align:center;color:#64748b;padding:20px;">Review queue is clear! All questions approved.</td></tr>
                    <?php else: ?>
                        <?php foreach ($reviewItems as $rev): ?>
                            <?php
                                $qBadge = 'badge-secondary';
                                if ($rev['status'] === 'approved' || $rev['status'] === 'published') $qBadge = 'badge-success';
                                elseif ($rev['status'] === 'pending_review' || $rev['status'] === 'draft') $qBadge = 'badge-warning';
                                elseif ($rev['status'] === 'rejected') $qBadge = 'badge-danger';
                            ?>
                            <tr>
                                <td style="font-weight:700;color:#2563eb;">#Q-<?php echo sprintf('%05d', $rev['id']); ?></td>
                                <td style="font-weight:600;color:#0f172a;"><?php echo htmlspecialchars($rev['author_name']); ?></td>
                                <td><?php echo htmlspecialchars($rev['subject_name']); ?></td>
                                <td><span class="badge badge-secondary" style="text-transform:capitalize;"><?php echo htmlspecialchars($rev['difficulty'] ?? 'Medium'); ?></span></td>
                                <td><span class="badge <?php echo $qBadge; ?>"><?php echo strtoupper($rev['status']); ?></span></td>
                                <td>
                                    <div style="display:flex;gap:4px;">
                                        <a href="index.php?page=question_review" class="btn btn-sm btn-outline" style="color:#15803d;border-color:#bbf7d0;padding:2px 6px;font-size:10px;text-decoration:none;">Review</a>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- 4. ROW 3: ANALYTICS OVERVIEW DIRECT FROM DATABASE -->
<div class="card">
    <div class="card-header-flex">
        <div class="card-title-main">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;color:#2563eb;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
            Live Platform Analytics Overview
        </div>
        <div style="display:flex;gap:8px;align-items:center;">
            <span style="font-size:12px;color:#64748b;font-weight:600;">Real-time MySQL Sync</span>
            <button class="btn btn-outline btn-sm" onclick="window.location.reload();">🔄 Refresh Stats</button>
        </div>
    </div>

    <div class="dash-row-4" style="margin-bottom:0;">
        <!-- Metric 1: Question Growth -->
        <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;padding:14px;">
            <div style="display:flex;justify-content:space-between;align-items:center;">
                <span style="font-size:12px;color:#64748b;font-weight:600;">Question Growth</span>
                <span style="color:#10b981;font-size:11px;font-weight:700;">Active</span>
            </div>
            <div style="font-size:20px;font-weight:800;color:#0f172a;margin:6px 0 2px 0;">+<?php echo number_format($totalQuestions); ?> Qs</div>
            <div style="font-size:11px;color:#64748b;margin-bottom:8px;">across <?php echo $totalTopics; ?> syllabus topics</div>
            <!-- SVG Sparkline -->
            <svg viewBox="0 0 100 30" style="width:100%;height:35px;overflow:visible;">
                <path d="M0,25 Q15,20 30,18 T60,10 T90,5 L100,2" fill="none" stroke="#2563eb" stroke-width="2.5" stroke-linecap="round"/>
                <circle cx="100" cy="2" r="3.5" fill="#2563eb"/>
            </svg>
        </div>

        <!-- Metric 2: Approval Rate -->
        <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;padding:14px;">
            <div style="display:flex;justify-content:space-between;align-items:center;">
                <span style="font-size:12px;color:#64748b;font-weight:600;">Approval Rate</span>
                <span style="color:#10b981;font-size:11px;font-weight:700;">Quality Gate</span>
            </div>
            <div style="font-size:20px;font-weight:800;color:#0f172a;margin:6px 0 2px 0;"><?php echo $approvalRatePct; ?>%</div>
            <div style="font-size:11px;color:#64748b;margin-bottom:8px;"><?php echo number_format($approvedQuestions); ?> approved questions</div>
            <!-- SVG Sparkline -->
            <svg viewBox="0 0 100 30" style="width:100%;height:35px;overflow:visible;">
                <path d="M0,15 Q20,18 40,16 T70,12 T95,10 L100,8" fill="none" stroke="#10b981" stroke-width="2.5" stroke-linecap="round"/>
                <circle cx="100" cy="8" r="3.5" fill="#10b981"/>
            </svg>
        </div>

        <!-- Metric 3: Test Attempts -->
        <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;padding:14px;">
            <div style="display:flex;justify-content:space-between;align-items:center;">
                <span style="font-size:12px;color:#64748b;font-weight:600;">Test Attempts</span>
                <span style="color:#10b981;font-size:11px;font-weight:700;">Live Evaluated</span>
            </div>
            <div style="font-size:20px;font-weight:800;color:#0f172a;margin:6px 0 2px 0;"><?php echo number_format($totalAttempts); ?></div>
            <div style="font-size:11px;color:#64748b;margin-bottom:8px;">across <?php echo $liveTests; ?> published tests</div>
            <!-- SVG Sparkline -->
            <svg viewBox="0 0 100 30" style="width:100%;height:35px;overflow:visible;">
                <path d="M0,22 Q25,25 50,15 T80,18 T95,6 L100,4" fill="none" stroke="#06b6d4" stroke-width="2.5" stroke-linecap="round"/>
                <circle cx="100" cy="4" r="3.5" fill="#06b6d4"/>
            </svg>
        </div>

        <!-- Metric 4: Teacher & Referral Network -->
        <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;padding:14px;">
            <div style="display:flex;justify-content:space-between;align-items:center;">
                <span style="font-size:12px;color:#64748b;font-weight:600;">Verified Network</span>
                <span style="color:#10b981;font-size:11px;font-weight:700;">KYC Active</span>
            </div>
            <div style="font-size:20px;font-weight:800;color:#0f172a;margin:6px 0 2px 0;"><?php echo number_format($activeTeachers); ?> Teachers</div>
            <div style="font-size:11px;color:#64748b;margin-bottom:8px;"><?php echo number_format($teacherAppsCount + $underReviewCount); ?> pending reviews</div>
            <!-- SVG Sparkline -->
            <svg viewBox="0 0 100 30" style="width:100%;height:35px;overflow:visible;">
                <path d="M0,18 Q30,12 55,20 T80,10 T95,14 L100,8" fill="none" stroke="#8b5cf6" stroke-width="2.5" stroke-linecap="round"/>
                <circle cx="100" cy="8" r="3.5" fill="#8b5cf6"/>
            </svg>
        </div>
    </div>
</div>
