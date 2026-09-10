<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$filter = $_GET['filter'] ?? 'submitted';
$validFilters = ['submitted', 'changes_required', 'approved', 'rejected', 'all'];
if (!in_array($filter, $validFilters)) $filter = 'submitted';

$whereMap = [
    'submitted'        => "ta.status IN ('submitted', 'under_review')",
    'changes_required' => "ta.status = 'changes_required'",
    'approved'         => "ta.status = 'approved'",
    'rejected'         => "ta.status = 'rejected'",
    'all'              => '1=1'
];

$stmt = $db->query("
    SELECT ta.*, u.full_name, u.email, u.mobile, COALESCE(s.name, 'All India') AS state_name, u.created_at AS user_joined_at,
           (SELECT COUNT(*) FROM teacher_documents td WHERE td.application_id = ta.id) AS document_count
    FROM teacher_applications ta
    JOIN users u ON ta.user_id = u.id
    LEFT JOIN states s ON u.state_id = s.id
    WHERE {$whereMap[$filter]}
    ORDER BY ta.submitted_at DESC, ta.id DESC
");
$applications = $stmt->fetchAll(PDO::FETCH_ASSOC);

$counts = $db->query("
    SELECT
        COALESCE(SUM(status IN ('submitted', 'under_review')), 0) as pending,
        COALESCE(SUM(status = 'changes_required'), 0) as changes_required,
        COALESCE(SUM(status = 'approved'), 0) as approved,
        COALESCE(SUM(status = 'rejected'), 0) as rejected,
        COUNT(*) as total
    FROM teacher_applications
")->fetch(PDO::FETCH_ASSOC);

// Map subjects and exams for display
$subjectsById = [];
try {
    $subRes = $db->query("SELECT id, name FROM subjects")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($subRes as $s) $subjectsById[$s['id']] = $s['name'];
} catch (Exception $e) {}

$examsById = [];
try {
    $exRes = $db->query("SELECT id, title FROM exams")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($exRes as $e) $examsById[$e['id']] = $e['title'];
} catch (Exception $e) {}
?>

<div style="width: 100%; max-width: 100%; box-sizing: border-box;">
    <!-- Page Header Title & Subtitle -->
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 22px; font-weight: 800; color: var(--text-primary); margin: 0 0 6px 0; display: flex; align-items: center; gap: 8px;">
            <span>🎓</span> Teacher KYC & Credential Verification Queue
        </h2>
        <p style="margin: 0; font-size: 13.5px; color: var(--text-muted);">
            Review teacher applicant credentials, verify degree & identity documents, and approve question authoring access (PRD §15).
        </p>
    </div>

    <!-- 1. KPI Metric Summary Cards -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-bottom: 24px;">
        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 12px; padding: 16px 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Pending Review</div>
                <div style="font-size: 26px; font-weight: 800; color: #f97316; line-height: 1;"><?php echo (int)$counts['pending']; ?></div>
                <div style="font-size: 11.5px; color: #94a3b8; margin-top: 4px;">Awaiting verification</div>
            </div>
            <div style="width: 44px; height: 44px; border-radius: 10px; background: #fff7ed; color: #f97316; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid #ffedd5;">
                ⏳
            </div>
        </div>

        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 12px; padding: 16px 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Changes Requested</div>
                <div style="font-size: 26px; font-weight: 800; color: #8b5cf6; line-height: 1;"><?php echo (int)$counts['changes_required']; ?></div>
                <div style="font-size: 11.5px; color: #94a3b8; margin-top: 4px;">Waiting for teacher re-upload</div>
            </div>
            <div style="width: 44px; height: 44px; border-radius: 10px; background: #f5f3ff; color: #8b5cf6; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid #ede9fe;">
                ✏️
            </div>
        </div>

        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 12px; padding: 16px 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Verified Teachers</div>
                <div style="font-size: 26px; font-weight: 800; color: #10b981; line-height: 1;"><?php echo (int)$counts['approved']; ?></div>
                <div style="font-size: 11.5px; color: #94a3b8; margin-top: 4px;">Active creators & authors</div>
            </div>
            <div style="width: 44px; height: 44px; border-radius: 10px; background: #ecfdf5; color: #10b981; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid #d1fae5;">
                ✓
            </div>
        </div>

        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 12px; padding: 16px 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">Rejected / Ineligible</div>
                <div style="font-size: 26px; font-weight: 800; color: #ef4444; line-height: 1;"><?php echo (int)$counts['rejected']; ?></div>
                <div style="font-size: 11.5px; color: #94a3b8; margin-top: 4px;">Declined KYC requests</div>
            </div>
            <div style="width: 44px; height: 44px; border-radius: 10px; background: #fef2f2; color: #ef4444; display: flex; align-items: center; justify-content: center; font-size: 20px; border: 1px solid #fee2e2;">
                ✕
            </div>
        </div>
    </div>

    <!-- 2. Filter Navigation Tabs -->
    <div style="display: flex; gap: 8px; margin-bottom: 20px; flex-wrap: wrap; background: #ffffff; padding: 8px; border-radius: 10px; border: 1px solid var(--border-color); box-shadow: 0 1px 2px rgba(0,0,0,0.03);">
        <?php 
        $tabs = [
            'submitted'        => ['label' => 'Pending Review', 'count' => (int)$counts['pending'], 'icon' => '⏳'],
            'changes_required' => ['label' => 'Action Required', 'count' => (int)$counts['changes_required'], 'icon' => '✏️'],
            'approved'         => ['label' => 'Approved', 'count' => (int)$counts['approved'], 'icon' => '✓'],
            'rejected'         => ['label' => 'Rejected', 'count' => (int)$counts['rejected'], 'icon' => '✕'],
            'all'              => ['label' => 'All Applications', 'count' => (int)$counts['total'], 'icon' => '📋'],
        ];
        foreach ($tabs as $val => $t):
            $isActive = ($filter === $val);
        ?>
        <a href="?page=teacher_applications&filter=<?php echo $val; ?>"
           style="display: inline-flex; align-items: center; gap: 6px; padding: 7px 16px; border-radius: 7px; font-size: 12.5px; font-weight: 600; text-decoration: none; transition: all 0.15s ease; <?php echo $isActive ? 'background: #2563eb; color: #ffffff; box-shadow: 0 2px 6px rgba(37,99,235,0.3);' : 'background: transparent; color: #475569; hover: background #f1f5f9;'; ?>">
            <span><?php echo $t['icon']; ?></span>
            <span><?php echo $t['label']; ?></span>
            <span style="background: <?php echo $isActive ? 'rgba(255,255,255,0.25)' : '#e2e8f0'; ?>; color: <?php echo $isActive ? '#ffffff' : '#334155'; ?>; padding: 1px 7px; border-radius: 12px; font-size: 11px; font-weight: 700;">
                <?php echo $t['count']; ?>
            </span>
        </a>
        <?php endforeach; ?>
    </div>

    <!-- 3. Teacher Application Cards List -->
    <?php if (empty($applications)): ?>
    <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 12px; text-align: center; padding: 60px 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
        <div style="font-size: 40px; margin-bottom: 12px;">📂</div>
        <h3 style="font-size: 17px; font-weight: 700; color: var(--text-primary); margin: 0 0 6px 0;">No Applications In This Queue</h3>
        <p style="font-size: 13.5px; color: var(--text-muted); margin: 0;">There are currently no teacher KYC verification requests matching the selected filter.</p>
    </div>
    <?php else: ?>
    <div style="display: flex; flex-direction: column; gap: 20px;">
        <?php foreach ($applications as $app):
            $subIds = $app['subject_ids'] ? json_decode($app['subject_ids'], true) : [];
            $exIds  = $app['exam_ids'] ? json_decode($app['exam_ids'], true) : [];

            // Load documents
            $docStmt = $db->prepare("SELECT * FROM teacher_documents WHERE application_id = ? ORDER BY id ASC");
            $docStmt->execute([$app['id']]);
            $docs = $docStmt->fetchAll(PDO::FETCH_ASSOC);

            $statusConfig = [
                'draft'            => ['bg' => '#f1f5f9', 'text' => '#475569', 'label' => 'Draft'],
                'submitted'        => ['bg' => '#fff7ed', 'text' => '#c2410c', 'label' => 'Submitted / Under Review'],
                'under_review'     => ['bg' => '#eff6ff', 'text' => '#1d4ed8', 'label' => 'Under Review'],
                'changes_required' => ['bg' => '#f5f3ff', 'text' => '#7c3aed', 'label' => 'Changes Requested'],
                'approved'         => ['bg' => '#ecfdf5', 'text' => '#047857', 'label' => 'Approved (Verified Teacher)'],
                'rejected'         => ['bg' => '#fef2f2', 'text' => '#b91c1c', 'label' => 'Rejected / Ineligible'],
            ][$app['status']] ?? ['bg' => '#f1f5f9', 'text' => '#475569', 'label' => ucfirst($app['status'])];
        ?>
        <div id="app-card-<?php echo $app['id']; ?>" style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 12px; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,0.05); transition: box-shadow 0.2s ease;">
            
            <!-- Card Header -->
            <div style="background: #f8fafc; padding: 14px 20px; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                    <span style="background: <?php echo $statusConfig['bg']; ?>; color: <?php echo $statusConfig['text']; ?>; font-weight: 700; font-size: 11.5px; padding: 4px 10px; border-radius: 6px; text-transform: uppercase; letter-spacing: 0.5px;">
                        <?php echo $statusConfig['label']; ?>
                    </span>
                    <span style="font-weight: 800; font-size: 15px; color: var(--text-primary); letter-spacing: -0.2px;">
                        #<?php echo htmlspecialchars($app['application_no'] ?: 'TCH-'.$app['id']); ?>
                    </span>
                    <span style="font-size: 12.5px; color: var(--text-muted);">
                        Submitted: <strong><?php echo $app['submitted_at'] ? date('d M Y, h:i A', strtotime($app['submitted_at'])) : 'Draft'; ?></strong>
                    </span>
                </div>
                
                <!-- Action Buttons -->
                <div style="display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
                    <?php if (in_array($app['status'], ['submitted', 'under_review', 'changes_required'])): ?>
                    <button type="button" class="btn btn-sm btn-outline" style="border-color: #f59e0b; color: #b45309; background: #fffbeb; font-weight: 600; padding: 6px 12px; border-radius: 6px; cursor: pointer;" onclick="openRequestChangesModal(<?php echo $app['id']; ?>)">
                        ✏️ Request Changes
                    </button>
                    <button type="button" class="btn btn-sm btn-outline" style="border-color: #ef4444; color: #b91c1c; background: #fef2f2; font-weight: 600; padding: 6px 12px; border-radius: 6px; cursor: pointer;" onclick="openRejectModal(<?php echo $app['id']; ?>)">
                        ✕ Reject
                    </button>
                    <button type="button" class="btn btn-sm btn-success" style="background: #10b981; color: #ffffff; border: none; font-weight: 700; padding: 6px 14px; border-radius: 6px; cursor: pointer; box-shadow: 0 1px 3px rgba(16,185,129,0.3);" onclick="approveApplication(<?php echo $app['id']; ?>)">
                        ✓ Approve & Unlock Teacher Role
                    </button>
                    <?php else: ?>
                    <span style="background: #f1f5f9; color: #475569; font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 6px;">
                        Decision Recorded
                    </span>
                    <?php endif; ?>
                </div>
            </div>

            <!-- Card Body 3-Column Layout -->
            <div style="padding: 20px; display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; box-sizing: border-box;">
                
                <!-- Column 1: Applicant Profile -->
                <div style="background: #f8fafc; border: 1px solid var(--border-color); border-radius: 10px; padding: 16px;">
                    <div style="font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.6px; color: #64748b; margin-bottom: 12px; display: flex; align-items: center; gap: 6px;">
                        <span>👤</span> Applicant Information
                    </div>
                    
                    <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 12px;">
                        <div style="width: 44px; height: 44px; border-radius: 50%; background: #dbeafe; color: #1d4ed8; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 16px; border: 2px solid #bfdbfe;">
                            <?php echo strtoupper(substr($app['full_name'] ?? 'T', 0, 1)); ?>
                        </div>
                        <div>
                            <div style="font-size: 15px; font-weight: 800; color: var(--text-primary);">
                                <?php echo htmlspecialchars($app['full_name']); ?>
                            </div>
                            <div style="font-size: 12px; color: #64748b;">
                                Member since <?php echo date('M Y', strtotime($app['user_joined_at'] ?? 'now')); ?>
                            </div>
                        </div>
                    </div>

                    <div style="display: flex; flex-direction: column; gap: 6px; font-size: 13px; color: var(--text-secondary);">
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <span style="color: #94a3b8;">✉️</span>
                            <span style="color: var(--text-primary); font-weight: 500;"><?php echo htmlspecialchars($app['email']); ?></span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <span style="color: #94a3b8;">📞</span>
                            <span style="color: var(--text-primary); font-weight: 500;"><?php echo htmlspecialchars($app['mobile'] ?: 'Not provided'); ?></span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <span style="color: #94a3b8;">📍</span>
                            <span>State: <strong style="color: var(--text-primary);"><?php echo htmlspecialchars($app['state_name']); ?></strong></span>
                        </div>
                    </div>

                    <?php if ($app['reviewer_message']): ?>
                    <div style="background: #fffbeb; border: 1px solid #fde68a; border-radius: 8px; padding: 10px; margin-top: 14px; font-size: 12px; color: #92400e;">
                        <strong style="display: block; margin-bottom: 2px;">💬 Reviewer Note:</strong>
                        <?php echo htmlspecialchars($app['reviewer_message']); ?>
                    </div>
                    <?php endif; ?>
                </div>

                <!-- Column 2: Academic & Teaching Background -->
                <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 16px;">
                    <div style="font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.6px; color: #64748b; margin-bottom: 12px; display: flex; align-items: center; gap: 6px;">
                        <span>🎓</span> Academic & Experience Background
                    </div>

                    <div style="display: flex; flex-direction: column; gap: 8px; font-size: 13px; color: var(--text-secondary);">
                        <div>
                            <span style="color: #64748b;">Highest Qualification:</span><br>
                            <strong style="color: var(--text-primary); font-size: 13.5px;"><?php echo htmlspecialchars($app['highest_qualification']); ?></strong>
                            <?php if ($app['degree_name']): ?>
                                in <span style="color: #2563eb; font-weight: 600;"><?php echo htmlspecialchars($app['degree_name']); ?></span>
                            <?php endif; ?>
                        </div>

                        <?php if ($app['specialization']): ?>
                        <div>
                            <span style="color: #64748b;">Specialization:</span> 
                            <strong style="color: var(--text-primary);"><?php echo htmlspecialchars($app['specialization']); ?></strong>
                        </div>
                        <?php endif; ?>

                        <div>
                            <span style="color: #64748b;">Institution:</span> 
                            <strong style="color: var(--text-primary);"><?php echo htmlspecialchars($app['institution_name'] ?: 'Not Specified'); ?></strong>
                            <?php if ($app['passing_year']): ?>(<?php echo htmlspecialchars($app['passing_year']); ?>)<?php endif; ?>
                        </div>

                        <div style="display: flex; align-items: center; gap: 8px; margin-top: 2px;">
                            <span style="color: #64748b;">Teaching Experience:</span>
                            <span style="background: #eff6ff; color: #1d4ed8; font-weight: 700; padding: 3px 10px; border-radius: 6px; font-size: 12px; border: 1px solid #bfdbfe;">
                                <?php echo number_format($app['experience_years'], 1); ?> Years
                            </span>
                        </div>

                        <?php if ($app['current_organization']): ?>
                        <div>
                            <span style="color: #64748b;">Current Org:</span> 
                            <strong style="color: var(--text-primary);"><?php echo htmlspecialchars($app['current_organization']); ?></strong>
                        </div>
                        <?php endif; ?>

                        <div style="margin-top: 6px;">
                            <span style="color: #64748b; font-size: 12px; display: block; margin-bottom: 4px;">Target Subjects:</span>
                            <?php if (!empty($subIds)): ?>
                                <div style="display: flex; gap: 4px; flex-wrap: wrap;">
                                    <?php foreach ($subIds as $sid): ?>
                                        <span style="background: #f1f5f9; color: #334155; font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 4px; border: 1px solid #e2e8f0;">
                                            <?php echo htmlspecialchars($subjectsById[$sid] ?? "Subject #$sid"); ?>
                                        </span>
                                    <?php endforeach; ?>
                                </div>
                            <?php else: ?>
                                <span style="font-size: 12px; color: #94a3b8; font-style: italic;">All general subjects</span>
                            <?php endif; ?>
                        </div>
                    </div>
                </div>

                <!-- Column 3: Uploaded KYC Verification Documents -->
                <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 16px;">
                    <div style="font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.6px; color: #64748b; margin-bottom: 12px; display: flex; align-items: center; justify-content: space-between;">
                        <span style="display: flex; align-items: center; gap: 6px;">
                            <span>📁</span> Uploaded Documents
                        </span>
                        <span style="background: #e2e8f0; color: #334155; padding: 2px 8px; border-radius: 10px; font-size: 10px; font-weight: 700;">
                            <?php echo count($docs); ?> files
                        </span>
                    </div>

                    <?php if (empty($docs)): ?>
                        <div style="background: #fef2f2; border: 1px solid #fee2e2; border-radius: 8px; padding: 16px; color: #b91c1c; font-size: 12.5px; text-align: center;">
                            <div style="font-size: 24px; margin-bottom: 4px;">⚠️</div>
                            <strong>No verification documents uploaded</strong>
                            <div style="font-size: 11px; color: #ef4444; margin-top: 4px;">Request changes to ask applicant to upload PAN/Aadhaar & Degree.</div>
                        </div>
                    <?php else: ?>
                        <div style="display: flex; flex-direction: column; gap: 8px;">
                        <?php foreach ($docs as $doc):
                            $docStatusConfig = [
                                'pending'           => ['bg' => '#fff7ed', 'text' => '#c2410c', 'border' => '#fed7aa', 'label' => 'PENDING'],
                                'verified'          => ['bg' => '#ecfdf5', 'text' => '#047857', 'border' => '#a7f3d0', 'label' => 'VERIFIED'],
                                'invalid'           => ['bg' => '#fef2f2', 'text' => '#b91c1c', 'border' => '#fecaca', 'label' => 'INVALID'],
                                'unclear'           => ['bg' => '#f5f3ff', 'text' => '#7c3aed', 'border' => '#ddd6fe', 'label' => 'UNCLEAR'],
                                'reupload_required' => ['bg' => '#fdf2f8', 'text' => '#be185d', 'border' => '#fbcfe8', 'label' => 'RE-UPLOAD']
                            ][$doc['verification_status']] ?? ['bg' => '#f1f5f9', 'text' => '#475569', 'border' => '#e2e8f0', 'label' => 'UNKNOWN'];
                        ?>
                        <div style="background: #f8fafc; border: 1px solid var(--border-color); border-radius: 8px; padding: 10px 12px; display: flex; justify-content: space-between; align-items: center; gap: 10px;">
                            <div style="flex: 1; min-width: 0;">
                                <div style="font-weight: 700; font-size: 12.5px; color: var(--text-primary); display: flex; align-items: center; gap: 6px;">
                                    <span>📄</span>
                                    <span><?php echo strtoupper(str_replace('_', ' ', $doc['document_type'])); ?></span>
                                </div>
                                <div style="font-size: 11px; color: var(--text-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-top: 2px;" title="<?php echo htmlspecialchars($doc['original_name']); ?>">
                                    <?php echo htmlspecialchars($doc['original_name']); ?> (<?php echo round($doc['file_size']/1024); ?> KB)
                                </div>
                                <span style="display: inline-block; background: <?php echo $docStatusConfig['bg']; ?>; color: <?php echo $docStatusConfig['text']; ?>; border: 1px solid <?php echo $docStatusConfig['border']; ?>; font-size: 9px; font-weight: 800; padding: 1px 6px; border-radius: 4px; margin-top: 4px;">
                                    <?php echo $docStatusConfig['label']; ?>
                                </span>
                            </div>
                            <div style="display: flex; gap: 6px; align-items: center;">
                                <button type="button" class="btn btn-sm" style="background: #ffffff; border: 1px solid #cbd5e1; color: #334155; padding: 4px 10px; font-size: 11.5px; border-radius: 5px; cursor: pointer; font-weight: 600;" onclick="viewDocument(<?php echo $doc['id']; ?>, '<?php echo htmlspecialchars(addslashes($doc['original_name'])); ?>')">
                                    👁️ View
                                </button>
                                <?php if ($doc['verification_status'] !== 'verified'): ?>
                                <button type="button" class="btn btn-sm" style="background: #10b981; border: none; color: #ffffff; padding: 4px 8px; font-size: 11.5px; border-radius: 5px; cursor: pointer; font-weight: 700;" title="Mark Document Verified" onclick="setDocStatus(<?php echo $doc['id']; ?>, 'verified')">
                                    ✓
                                </button>
                                <?php endif; ?>
                            </div>
                        </div>
                        <?php endforeach; ?>
                        </div>
                    <?php endif; ?>
                </div>

            </div>
        </div>
        <?php endforeach; ?>
    </div>
    <?php endif; ?>
</div>

<!-- Modal: Secure Document Viewer -->
<div id="docViewerModal" style="display:none; position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,0.65); z-index:9999; align-items:center; justify-content:center; padding:20px; backdrop-filter: blur(2px);">
    <div style="background:#ffffff; border-radius:14px; width:95%; max-width:850px; height:85vh; display:flex; flex-direction:column; overflow:hidden; box-shadow:0 25px 50px -12px rgba(0,0,0,0.3);">
        <div style="background:#f8fafc; padding:14px 20px; border-bottom:1px solid var(--border-color); display:flex; justify-content:space-between; align-items:center;">
            <div style="font-weight:700; font-size:15px; color: var(--text-primary);" id="docViewerTitle">📄 Document Viewer</div>
            <button onclick="closeViewer()" style="background:none; border:none; font-size:22px; cursor:pointer; color:var(--text-muted); line-height: 1;">✕</button>
        </div>
        <div style="flex:1; background:#0f172a; position:relative;">
            <iframe id="docIframe" src="about:blank" style="width:100%; height:100%; border:none;"></iframe>
        </div>
    </div>
</div>

<!-- Modal: Request Changes -->
<div id="requestChangesModal" style="display:none; position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,0.65); z-index:9999; align-items:center; justify-content:center; padding:20px; backdrop-filter: blur(2px);">
    <div style="background:#ffffff; border-radius:14px; width:90%; max-width:500px; padding:24px; box-shadow:0 25px 50px -12px rgba(0,0,0,0.3);">
        <h4 style="margin:0 0 8px 0; font-weight:800; font-size: 17px; color: var(--text-primary);">✏️ Request Changes from Candidate</h4>
        <p style="font-size:13px; color:var(--text-muted); margin:0 0 16px 0;">Explain what document or credential needs re-uploading.</p>
        <input type="hidden" id="rcAppId" value="">
        <textarea id="rcMessage" class="form-control" rows="4" placeholder="e.g. Please re-upload degree certificate with all pages clearly legible..." style="margin-bottom:16px; width: 100%; box-sizing: border-box; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color); font-family: inherit; font-size: 13px;"></textarea>
        <div style="display:flex; justify-content:flex-end; gap:10px;">
            <button class="btn btn-outline" style="padding: 8px 16px; border-radius: 6px; cursor: pointer;" onclick="closeModal('requestChangesModal')">Cancel</button>
            <button class="btn btn-primary" style="padding: 8px 18px; border-radius: 6px; cursor: pointer; background: #2563eb; color: #fff; border: none; font-weight: 600;" onclick="submitRequestChanges()">Send Request</button>
        </div>
    </div>
</div>

<!-- Modal: Reject Application -->
<div id="rejectModal" style="display:none; position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,0.65); z-index:9999; align-items:center; justify-content:center; padding:20px; backdrop-filter: blur(2px);">
    <div style="background:#ffffff; border-radius:14px; width:90%; max-width:500px; padding:24px; box-shadow:0 25px 50px -12px rgba(0,0,0,0.3);">
        <h4 style="margin:0 0 8px 0; font-weight:800; font-size: 17px; color:#ef4444;">✕ Reject Teacher Application</h4>
        <p style="font-size:13px; color:var(--text-muted); margin:0 0 16px 0;">Provide reason for application rejection.</p>
        <input type="hidden" id="rejAppId" value="">
        <textarea id="rejReason" class="form-control" rows="4" placeholder="e.g. Minimum teaching experience requirement not met..." style="margin-bottom:16px; width: 100%; box-sizing: border-box; padding: 10px; border-radius: 8px; border: 1px solid var(--border-color); font-family: inherit; font-size: 13px;"></textarea>
        <div style="display:flex; justify-content:flex-end; gap:10px;">
            <button class="btn btn-outline" style="padding: 8px 16px; border-radius: 6px; cursor: pointer;" onclick="closeModal('rejectModal')">Cancel</button>
            <button class="btn btn-danger" style="padding: 8px 18px; border-radius: 6px; cursor: pointer; background: #ef4444; color: #fff; border: none; font-weight: 600;" onclick="submitReject()">Reject Application</button>
        </div>
    </div>
</div>

<script>
function viewDocument(docId, docName) {
    document.getElementById('docViewerTitle').innerText = '📄 Document: ' + docName;
    document.getElementById('docIframe').src = '../api/v1/admin/teacher-documents/' + docId + '/view';
    document.getElementById('docViewerModal').style.display = 'flex';
}
function closeViewer() {
    document.getElementById('docViewerModal').style.display = 'none';
    document.getElementById('docIframe').src = 'about:blank';
}
function openRequestChangesModal(appId) {
    document.getElementById('rcAppId').value = appId;
    document.getElementById('requestChangesModal').style.display = 'flex';
}
function openRejectModal(appId) {
    document.getElementById('rejAppId').value = appId;
    document.getElementById('rejectModal').style.display = 'flex';
}
function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}

async function approveApplication(appId) {
    if (!confirm('Are you sure you want to approve this application and unlock the verified Teacher role?')) return;
    try {
        const res = await fetch('../api/v1/admin/teacher-applications/' + appId + '/approve', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({decision_reason: 'Approved credentials & verified KYC documents.'})
        });
        const data = await res.json();
        if (data.status === 'success') {
            alert('Teacher approved successfully!');
            window.location.reload();
        } else {
            alert('Approval failed: ' + (data.message || 'Unknown error'));
        }
    } catch (e) {
        alert('Request error: ' + e);
    }
}

async function setDocStatus(docId, status) {
    try {
        const res = await fetch('../api/v1/admin/teacher-documents/' + docId + '/status', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({verification_status: status})
        });
        const data = await res.json();
        if (data.status === 'success') {
            window.location.reload();
        } else {
            alert('Failed to update document: ' + data.message);
        }
    } catch (e) {
        alert('Request error: ' + e);
    }
}

async function submitRequestChanges() {
    const appId = document.getElementById('rcAppId').value;
    const msg = document.getElementById('rcMessage').value.trim();
    if (!msg) { alert('Please enter message for the teacher.'); return; }
    try {
        const res = await fetch('../api/v1/admin/teacher-applications/' + appId + '/request-changes', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({message: msg})
        });
        const data = await res.json();
        if (data.status === 'success') {
            alert('Change request sent to teacher.');
            window.location.reload();
        } else {
            alert('Failed: ' + data.message);
        }
    } catch (e) {
        alert('Request error: ' + e);
    }
}

async function submitReject() {
    const appId = document.getElementById('rejAppId').value;
    const reason = document.getElementById('rejReason').value.trim();
    if (!reason) { alert('Please enter rejection reason.'); return; }
    try {
        const res = await fetch('../api/v1/admin/teacher-applications/' + appId + '/reject', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({reason: reason})
        });
        const data = await res.json();
        if (data.status === 'success') {
            alert('Application rejected.');
            window.location.reload();
        } else {
            alert('Failed: ' + data.message);
        }
    } catch (e) {
        alert('Request error: ' + e);
    }
}
</script>
