<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$message = '';
$messageType = '';

// Handle Actions (Single & Bulk Delete / Activate / Suspend)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = trim($_POST['action'] ?? '');

    if ($action === 'toggle_status' && isset($_POST['user_id'])) {
        $userId = intval($_POST['user_id']);
        $newStatus = trim($_POST['new_status'] ?? '');
        if (in_array($newStatus, ['active', 'suspended', 'pending'])) {
            $stmt = $db->prepare("UPDATE users SET status = :status WHERE id = :id");
            $stmt->execute(['status' => $newStatus, 'id' => $userId]);
            $message = "User #USR-" . sprintf('%05d', $userId) . " status updated to " . ucfirst($newStatus);
            $messageType = "success";
        }
    } elseif ($action === 'delete_user' && isset($_POST['user_id'])) {
        $userId = intval($_POST['user_id']);
        try {
            $db->prepare("DELETE FROM test_attempts WHERE user_id = :id")->execute(['id' => $userId]);
            $db->prepare("DELETE FROM user_bookmarks WHERE user_id = :id")->execute(['id' => $userId]);
            $db->prepare("DELETE FROM mistake_notebook WHERE user_id = :id")->execute(['id' => $userId]);
            $db->prepare("DELETE FROM user_subscriptions WHERE user_id = :id")->execute(['id' => $userId]);
        } catch (Exception $e) {}
        $stmt = $db->prepare("DELETE FROM users WHERE id = :id");
        $stmt->execute(['id' => $userId]);
        $message = "Candidate #USR-" . sprintf('%05d', $userId) . " deleted successfully.";
        $messageType = "success";
    } elseif ($action === 'bulk_delete' && !empty($_POST['selected_users'])) {
        $ids = array_filter(array_map('intval', (array)$_POST['selected_users']));
        if (!empty($ids)) {
            $in = implode(',', array_fill(0, count($ids), '?'));
            try {
                $db->prepare("DELETE FROM test_attempts WHERE user_id IN ($in)")->execute($ids);
                $db->prepare("DELETE FROM user_bookmarks WHERE user_id IN ($in)")->execute($ids);
                $db->prepare("DELETE FROM mistake_notebook WHERE user_id IN ($in)")->execute($ids);
                $db->prepare("DELETE FROM user_subscriptions WHERE user_id IN ($in)")->execute($ids);
            } catch (Exception $e) {}
            $stmt = $db->prepare("DELETE FROM users WHERE id IN ($in)");
            $stmt->execute($ids);
            $message = count($ids) . " candidates permanently deleted.";
            $messageType = "success";
        }
    } elseif ($action === 'bulk_status' && !empty($_POST['selected_users'])) {
        $ids = array_filter(array_map('intval', (array)$_POST['selected_users']));
        $newStatus = trim($_POST['new_status'] ?? '');
        if (!empty($ids) && in_array($newStatus, ['active', 'suspended', 'pending'])) {
            $in = implode(',', array_fill(0, count($ids), '?'));
            $params = array_merge([$newStatus], $ids);
            $stmt = $db->prepare("UPDATE users SET status = ? WHERE id IN ($in)");
            $stmt->execute($params);
            $message = count($ids) . " candidates updated to " . ucfirst($newStatus) . " status.";
            $messageType = "success";
        }
    }
}

// Search & Filter Parameters
$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$statusFilter = isset($_GET['status']) ? trim($_GET['status']) : '';
$stateFilter = isset($_GET['state_id']) ? intval($_GET['state_id']) : 0;

// Base queries for metrics
$totalUsers = (int)$db->query("SELECT COUNT(*) FROM users")->fetchColumn();
$activeUsers = (int)$db->query("SELECT COUNT(*) FROM users WHERE status = 'active'")->fetchColumn();
$suspendedUsers = (int)$db->query("SELECT COUNT(*) FROM users WHERE status = 'suspended'")->fetchColumn();
$verifiedUsers = (int)$db->query("SELECT COUNT(*) FROM users WHERE is_verified = 1")->fetchColumn();
$subscribedUsers = (int)$db->query("SELECT COUNT(DISTINCT user_id) FROM user_subscriptions WHERE status IN ('active', 'trial') AND expiry_date > NOW()")->fetchColumn();

// Build SQL Query for Users Table
$whereClauses = [];
$params = [];

if ($search !== '') {
    $whereClauses[] = "(u.full_name LIKE :search OR u.email LIKE :search OR u.mobile LIKE :search OR u.district LIKE :search)";
    $params['search'] = "%{$search}%";
}

if ($statusFilter !== '') {
    $whereClauses[] = "u.status = :status";
    $params['status'] = $statusFilter;
}

if ($stateFilter > 0) {
    $whereClauses[] = "u.state_id = :state_id";
    $params['state_id'] = $stateFilter;
}

$whereSql = '';
if (!empty($whereClauses)) {
    $whereSql = 'WHERE ' . implode(' AND ', $whereClauses);
}

$sql = "
    SELECT u.*, 
           s.name as state_name, 
           q.name as qualification_name,
           (SELECT COUNT(*) FROM test_attempts WHERE user_id = u.id) as total_attempts,
           (SELECT sp.name 
            FROM user_subscriptions us 
            JOIN subscription_plans sp ON us.plan_id = sp.id 
            WHERE us.user_id = u.id AND us.status IN ('active', 'trial') AND us.expiry_date > NOW() 
            ORDER BY us.id DESC LIMIT 1) as active_plan_name,
           (SELECT us.expiry_date 
            FROM user_subscriptions us 
            WHERE us.user_id = u.id AND us.status IN ('active', 'trial') AND us.expiry_date > NOW() 
            ORDER BY us.id DESC LIMIT 1) as active_plan_expiry
    FROM users u
    LEFT JOIN states s ON u.state_id = s.id
    LEFT JOIN qualifications q ON u.qualification_id = q.id
    {$whereSql}
    ORDER BY u.id DESC
";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Fetch All States for Filter Dropdown
$statesList = $db->query("SELECT id, name FROM states ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
$plansList = $db->query("SELECT id, name, duration_days, price FROM subscription_plans WHERE is_active = 1 ORDER BY price ASC")->fetchAll(PDO::FETCH_ASSOC);
?>

<div style="display: flex; flex-direction: column; gap: 1.5rem;">

    <?php if ($message): ?>
        <div style="padding: 12px 20px; border-radius: 10px; font-size: 14px; font-weight: 600; background: <?php echo $messageType === 'success' ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)'; ?>; color: <?php echo $messageType === 'success' ? 'var(--accent-emerald)' : 'var(--accent-danger)'; ?>; border: 1px solid <?php echo $messageType === 'success' ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'; ?>;">
            ✓ <?php echo htmlspecialchars($message); ?>
        </div>
    <?php endif; ?>

    <!-- Summary Metrics Grid -->
    <div class="metrics-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;">
        <div class="metric-card">
            <div class="metric-title">Total Candidates</div>
            <div class="metric-value"><?php echo number_format($totalUsers); ?></div>
            <div class="metric-subtitle">Across all Indian states</div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Active Candidates</div>
            <div class="metric-value" style="color: var(--accent-emerald);"><?php echo number_format($activeUsers); ?></div>
            <div class="metric-subtitle">Eligible for practice & tests</div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Pro Subscriptions</div>
            <div class="metric-value" style="color: var(--accent-purple, #8b5cf6);"><?php echo number_format($subscribedUsers); ?></div>
            <div class="metric-subtitle">Active Premium Members</div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Verified Profiles</div>
            <div class="metric-value" style="color: var(--accent-blue);"><?php echo number_format($verifiedUsers); ?></div>
            <div class="metric-subtitle">Completed phone/OTP verification</div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Suspended Accounts</div>
            <div class="metric-value" style="color: var(--accent-danger);"><?php echo number_format($suspendedUsers); ?></div>
            <div class="metric-subtitle">Restricted from access</div>
        </div>
    </div>

    <!-- Filters and Search Bar -->
    <div class="table-card" style="padding: 1.25rem; background: #ffffff; border-radius: 12px; border: 1px solid var(--border-color, #e2e8f0); box-shadow: var(--shadow-sm);">
        <form method="get" action="index.php" style="display: flex; gap: 12px; flex-wrap: wrap; align-items: center; justify-content: space-between;">
            <input type="hidden" name="page" value="users">
            
            <div style="display: flex; gap: 12px; flex-wrap: wrap; flex: 1;">
                <div style="position: relative; min-width: 260px; flex: 1;">
                    <input type="text" name="search" value="<?php echo htmlspecialchars($search); ?>" 
                           placeholder="Search by candidate name, email, mobile, district..." 
                           style="width: 100%; box-sizing: border-box; background: #f8fafc; border: 1px solid #cbd5e1; color: #0f172a; padding: 10px 14px; border-radius: 8px; font-size: 13.5px; font-weight: 500;">
                </div>

                <select name="status" style="background: #f8fafc; border: 1px solid #cbd5e1; color: #0f172a; padding: 10px 14px; border-radius: 8px; font-size: 13px; font-weight: 500;">
                    <option value="">All Account Statuses</option>
                    <option value="active" <?php echo $statusFilter === 'active' ? 'selected' : ''; ?>>Active</option>
                    <option value="suspended" <?php echo $statusFilter === 'suspended' ? 'selected' : ''; ?>>Suspended</option>
                    <option value="pending" <?php echo $statusFilter === 'pending' ? 'selected' : ''; ?>>Pending</option>
                </select>

                <select name="state_id" style="background: #f8fafc; border: 1px solid #cbd5e1; color: #0f172a; padding: 10px 14px; border-radius: 8px; font-size: 13px; font-weight: 500;">
                    <option value="0">All States</option>
                    <?php foreach ($statesList as $st): ?>
                        <option value="<?php echo $st['id']; ?>" <?php echo $stateFilter == $st['id'] ? 'selected' : ''; ?>>
                            <?php echo htmlspecialchars($st['name']); ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <button type="submit" class="btn btn-primary" style="padding: 10px 20px; font-size: 13.5px; font-weight: 600; border-radius: 8px;">Filter Results</button>
                <?php if ($search !== '' || $statusFilter !== '' || $stateFilter > 0): ?>
                    <a href="index.php?page=users" class="btn" style="background: #e2e8f0; color: #475569; padding: 10px 16px; font-size: 13px; text-decoration: none; border-radius: 8px; font-weight: 600;">Clear Filters</a>
                <?php endif; ?>
            </div>
        </form>
    </div>

    <!-- Candidate Table Card with Bulk Action Support -->
    <div class="table-card" style="background: #ffffff; border-radius: 12px; border: 1px solid var(--border-color, #e2e8f0); box-shadow: var(--shadow-sm); overflow: hidden;">
        <form id="bulkForm" method="post" action="index.php?page=users">
            <input type="hidden" name="action" id="bulkActionInput" value="">
            <input type="hidden" name="new_status" id="bulkStatusInput" value="">

            <div class="table-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; padding: 1.25rem; border-bottom: 1px solid #f1f5f9;">
                <div>
                    <div class="table-title" style="font-size: 1.15rem; font-weight: 800; color: #0f172a;">👥 Registered Candidates Directory</div>
                    <div style="font-size: 12.5px; color: #64748b; margin-top: 2px;">
                        Showing <?php echo count($users); ?> candidate accounts • Click any candidate to view 360° exam history & subscription details
                    </div>
                </div>

                <!-- Floating / Top Bulk Actions Bar -->
                <div id="bulkActionsBar" style="display: none; align-items: center; gap: 10px; background: #0f172a; border: 1px solid #3b82f6; padding: 6px 14px; border-radius: 10px;">
                    <span id="selectedCountText" style="font-size: 12.5px; font-weight: 700; color: #60a5fa;">0 selected</span>
                    <button type="button" onclick="submitBulkStatus('active')" style="background: rgba(16,185,129,0.2); color: #34d399; border: 1px solid rgba(16,185,129,0.4); padding: 5px 12px; border-radius: 6px; font-size: 12px; font-weight: 700; cursor: pointer;">
                        ● Activate
                    </button>
                    <button type="button" onclick="submitBulkStatus('suspended')" style="background: rgba(245,158,11,0.2); color: #fbbf24; border: 1px solid rgba(245,158,11,0.4); padding: 5px 12px; border-radius: 6px; font-size: 12px; font-weight: 700; cursor: pointer;">
                        ⛔ Suspend
                    </button>
                    <button type="button" onclick="submitBulkDelete()" style="background: rgba(239,68,68,0.25); color: #f87171; border: 1px solid rgba(239,68,68,0.5); padding: 5px 14px; border-radius: 6px; font-size: 12px; font-weight: 700; cursor: pointer;">
                        🗑️ Delete Selected
                    </button>
                </div>
            </div>

            <div style="overflow-x: auto;">
                <table style="width: 100%; border-collapse: collapse; text-align: left;">
                    <thead>
                        <tr style="background: #f8fafc; border-bottom: 2px solid #e2e8f0;">
                            <th style="width: 40px; text-align: center; padding: 12px 14px;">
                                <input type="checkbox" id="selectAllCheckbox" onchange="toggleSelectAll(this)" title="Select All Candidates" style="width: 16px; height: 16px; cursor: pointer; accent-color: #2563eb;">
                            </th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase;">User ID</th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase;">Candidate Profile</th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase;">Contact Info</th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase;">State & Qualification</th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase;">Subscription</th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase;">Exams Attempted</th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase;">Status</th>
                            <th style="padding: 12px 14px; font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase; text-align: right;">360° View & Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($users)): ?>
                            <tr>
                                <td colspan="9" style="text-align: center; color: #64748b; padding: 40px; font-size: 14px;">
                                    No registered candidates found matching your criteria.
                                </td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($users as $u): ?>
                                <tr style="border-bottom: 1px solid #f1f5f9; transition: background 0.15s ease;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='#ffffff'">
                                    <td style="text-align: center; padding: 14px;">
                                        <input type="checkbox" name="selected_users[]" value="<?php echo $u['id']; ?>" class="user-row-checkbox" onchange="onCheckboxChange()" style="width: 16px; height: 16px; cursor: pointer; accent-color: #2563eb;">
                                    </td>
                                    <td style="padding: 14px;">
                                        <span style="font-weight: 800; color: #2563eb; font-family: monospace; font-size: 13px;">#USR-<?php echo sprintf('%05d', $u['id']); ?></span>
                                    </td>
                                    <td style="padding: 14px;">
                                        <div style="display: flex; align-items: center; gap: 12px; cursor: pointer;" onclick="openCandidate360(<?php echo $u['id']; ?>)">
                                            <div style="width: 38px; height: 38px; border-radius: 50%; background: linear-gradient(135deg, #4f46e5, #2563eb); display: flex; align-items: center; justify-content: center; font-weight: 800; color: #fff; font-size: 14px; flex-shrink: 0; box-shadow: 0 2px 6px rgba(37,99,235,0.25);">
                                                <?php echo strtoupper(substr($u['full_name'], 0, 1)); ?>
                                            </div>
                                            <div>
                                                <div style="font-weight: 700; color: #0f172a; font-size: 14px; line-height: 1.3;" title="Click to view full analytics">
                                                    <?php echo htmlspecialchars($u['full_name']); ?>
                                                </div>
                                                <div style="display: flex; align-items: center; gap: 6px; margin-top: 3px;">
                                                    <?php if ($u['is_verified']): ?>
                                                        <span style="font-size: 10.5px; color: #16a34a; background: #dcfce7; padding: 2px 6px; border-radius: 4px; font-weight: 700;">✓ Verified</span>
                                                    <?php else: ?>
                                                        <span style="font-size: 10.5px; color: #d97706; background: #fef3c7; padding: 2px 6px; border-radius: 4px; font-weight: 700;">Unverified</span>
                                                    <?php endif; ?>
                                                    <span style="font-size: 11px; color: #64748b;">Joined <?php echo date('M Y', strtotime($u['created_at'])); ?></span>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td style="padding: 14px;">
                                        <div style="font-size: 13.5px; color: #0f172a; font-weight: 600;"><?php echo htmlspecialchars($u['email']); ?></div>
                                        <div style="font-size: 12px; color: #64748b; margin-top: 2px; font-family: monospace;">📞 <?php echo htmlspecialchars($u['mobile']); ?></div>
                                    </td>
                                    <td style="padding: 14px;">
                                        <div style="font-size: 13px; color: #2563eb; font-weight: 700;">
                                            📍 <?php echo htmlspecialchars($u['state_name'] ?: 'All India'); ?>
                                            <?php if (!empty($u['district'])): ?>
                                                <span style="font-size: 12px; color: #1d4ed8; font-weight: 600;">(<?php echo htmlspecialchars($u['district']); ?>)</span>
                                            <?php endif; ?>
                                        </div>
                                        <div style="font-size: 12px; color: #475569; margin-top: 2px; font-weight: 500;">
                                            🎓 <?php echo htmlspecialchars($u['qualification_name'] ?: 'Not Specified'); ?>
                                        </div>
                                    </td>
                                    <td style="padding: 14px;">
                                        <?php if (!empty($u['active_plan_name'])): ?>
                                            <div>
                                                <span style="background: #f3e8ff; color: #7e22ce; border: 1px solid #d8b4fe; padding: 3px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px;">
                                                    ⭐ <?php echo htmlspecialchars($u['active_plan_name']); ?>
                                                </span>
                                                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">
                                                    Exp: <?php echo date('d M Y', strtotime($u['active_plan_expiry'])); ?>
                                                </div>
                                            </div>
                                        <?php else: ?>
                                            <span style="background: #f1f5f9; color: #64748b; padding: 3px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 600;">
                                                Free Tier
                                            </span>
                                        <?php endif; ?>
                                    </td>
                                    <td style="padding: 14px;">
                                        <span style="background: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe; font-size: 12px; padding: 4px 10px; border-radius: 12px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px;">
                                            📝 <?php echo number_format($u['total_attempts']); ?> Tests Taken
                                        </span>
                                    </td>
                                    <td style="padding: 14px;">
                                        <?php if ($u['status'] === 'active'): ?>
                                            <span style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700; display: inline-block;">
                                                ● Active
                                            </span>
                                        <?php else: ?>
                                            <span style="background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700; display: inline-block;">
                                                ⛔ Suspended
                                            </span>
                                        <?php endif; ?>
                                    </td>
                                    <td style="padding: 14px; text-align: right;">
                                        <div style="display: flex; gap: 6px; justify-content: flex-end; align-items: center;">
                                            <button type="button" onclick="openCandidate360(<?php echo $u['id']; ?>)" 
                                                    style="background: #2563eb; color: #ffffff; border: none; padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; gap: 4px; box-shadow: 0 1px 3px rgba(37,99,235,0.3);" title="View 360° Candidate Profile, Exam History & Subscriptions">
                                                👁️ View Details
                                            </button>

                                            <button type="button" onclick="singleToggleStatus(<?php echo $u['id']; ?>, '<?php echo $u['status'] === 'active' ? 'suspended' : 'active'; ?>', '<?php echo addslashes($u['full_name']); ?>')" 
                                                    style="background: <?php echo $u['status'] === 'active' ? '#fee2e2' : '#dcfce7'; ?>; color: <?php echo $u['status'] === 'active' ? '#b91c1c' : '#15803d'; ?>; border: 1px solid <?php echo $u['status'] === 'active' ? '#fca5a5' : '#86efac'; ?>; padding: 6px 10px; border-radius: 6px; font-size: 11.5px; font-weight: 700; cursor: pointer;">
                                                <?php echo $u['status'] === 'active' ? 'Suspend' : 'Activate'; ?>
                                            </button>

                                            <button type="button" onclick="singleDeleteUser(<?php echo $u['id']; ?>, '<?php echo addslashes($u['full_name']); ?>')" 
                                                    style="background: #f8fafc; color: #ef4444; border: 1px solid #cbd5e1; padding: 6px 8px; border-radius: 6px; font-size: 11px; cursor: pointer;" title="Delete User">
                                                🗑️
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </form>
    </div>

</div>

<!-- Single Action Hidden Form -->
<form id="singleActionForm" method="post" action="index.php?page=users" style="display:none;">
    <input type="hidden" name="action" id="singleActionInput" value="">
    <input type="hidden" name="user_id" id="singleUserIdInput" value="">
    <input type="hidden" name="new_status" id="singleNewStatusInput" value="">
</form>

<!-- =========================================================================
     CANDIDATE 360° PROFILE MODAL (EXAM HISTORY, SUBSCRIPTIONS & ANALYTICS)
     ========================================================================= -->
<div id="candidate360Modal" style="display: none; position: fixed; inset: 0; z-index: 9999; background: rgba(15, 23, 42, 0.7); backdrop-filter: blur(8px); align-items: center; justify-content: center; padding: 1.5rem;">
    <div style="background: #ffffff; width: 100%; max-width: 960px; max-height: 90vh; border-radius: 16px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); display: flex; flex-direction: column; overflow: hidden; animation: modalFadeIn 0.2s ease-out;">
        
        <!-- Modal Top Header -->
        <div style="background: linear-gradient(135deg, #00152e 0%, #0f172a 100%); color: #ffffff; padding: 1.5rem 1.75rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid rgba(255,255,255,0.1);">
            <div style="display: flex; align-items: center; gap: 14px;">
                <div id="modalAvatar" style="width: 48px; height: 48px; border-radius: 50%; background: linear-gradient(135deg, #3b82f6, #06b6d4); display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: 800; color: #ffffff; box-shadow: 0 4px 10px rgba(0,0,0,0.3);">
                    U
                </div>
                <div>
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <h2 id="modalCandidateName" style="font-size: 1.25rem; font-weight: 800; color: #ffffff; margin: 0;">Candidate Name</h2>
                        <span id="modalUserIdBadge" style="background: rgba(255,255,255,0.15); color: #93c5fd; padding: 2px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; font-family: monospace;">#USR-00000</span>
                        <span id="modalStatusBadge" style="background: #10b981; color: #ffffff; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;">Active</span>
                    </div>
                    <div id="modalCandidateMeta" style="font-size: 12.5px; color: #94a3b8; margin-top: 3px;">
                        Loading candidate information...
                    </div>
                </div>
            </div>
            <button type="button" onclick="closeCandidate360()" style="background: rgba(255,255,255,0.1); border: none; color: #ffffff; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; cursor: pointer; transition: background 0.2s;" onmouseover="this.style.background='rgba(255,255,255,0.2)'" onmouseout="this.style.background='rgba(255,255,255,0.1)'">
                ✕
            </button>
        </div>

        <!-- Tab Navigation Bar -->
        <div style="background: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 0 1.75rem; display: flex; gap: 1.5rem;">
            <button type="button" class="tab-btn active-tab" onclick="switchModalTab('tab-analytics')" id="btn-tab-analytics" style="padding: 12px 4px; font-size: 13.5px; font-weight: 700; color: #2563eb; background: none; border: none; border-bottom: 2px solid #2563eb; cursor: pointer;">
                📊 Exam Analytics & Stats
            </button>
            <button type="button" class="tab-btn" onclick="switchModalTab('tab-history')" id="btn-tab-history" style="padding: 12px 4px; font-size: 13.5px; font-weight: 600; color: #64748b; background: none; border: none; border-bottom: 2px solid transparent; cursor: pointer;">
                📝 Tests & Scorecards (<span id="tabCountTests">0</span>)
            </button>
            <button type="button" class="tab-btn" onclick="switchModalTab('tab-subscription')" id="btn-tab-subscription" style="padding: 12px 4px; font-size: 13.5px; font-weight: 600; color: #64748b; background: none; border: none; border-bottom: 2px solid transparent; cursor: pointer;">
                💳 Subscription & Plan
            </button>
            <button type="button" class="tab-btn" onclick="switchModalTab('tab-actions')" id="btn-tab-actions" style="padding: 12px 4px; font-size: 13.5px; font-weight: 600; color: #64748b; background: none; border: none; border-bottom: 2px solid transparent; cursor: pointer;">
                ⚡ Admin Actions & Alerts
            </button>
        </div>

        <!-- Modal Body Content Container -->
        <div style="padding: 1.5rem 1.75rem; overflow-y: auto; flex: 1; background: #ffffff;">
            
            <div id="modalLoadingSpinner" style="text-align: center; padding: 60px 20px;">
                <div style="display: inline-block; width: 36px; height: 36px; border: 3px solid #e2e8f0; border-top-color: #2563eb; border-radius: 50%; animation: spin 0.8s linear infinite;"></div>
                <div style="font-size: 13.5px; color: #64748b; margin-top: 12px; font-weight: 600;">Loading 360° Candidate Data...</div>
            </div>

            <!-- TAB 1: EXAM PERFORMANCE & ANALYTICS -->
            <div id="tab-analytics" class="modal-tab-content" style="display: none;">
                <!-- 4 Performance Metric Cards -->
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 12px; margin-bottom: 1.5rem;">
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px;">
                        <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase;">Tests Completed</div>
                        <div id="mStatCompletedTests" style="font-size: 22px; font-weight: 800; color: #0f172a; margin-top: 4px;">0</div>
                        <div id="mStatTotalAttempts" style="font-size: 11.5px; color: #64748b; margin-top: 2px;">0 total attempts started</div>
                    </div>
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px;">
                        <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase;">Avg / Highest Score</div>
                        <div id="mStatAvgScore" style="font-size: 22px; font-weight: 800; color: #2563eb; margin-top: 4px;">0.0 Mks</div>
                        <div id="mStatMaxScore" style="font-size: 11.5px; color: #64748b; margin-top: 2px;">Max: 0.0 Mks</div>
                    </div>
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px;">
                        <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase;">Overall Accuracy</div>
                        <div id="mStatAccuracy" style="font-size: 22px; font-weight: 800; color: #16a34a; margin-top: 4px;">0.0%</div>
                        <div style="font-size: 11.5px; color: #64748b; margin-top: 2px;">Across all evaluated papers</div>
                    </div>
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px;">
                        <div style="font-size: 12px; font-weight: 700; color: #64748b; text-transform: uppercase;">Best Central AIR Rank</div>
                        <div id="mStatBestRank" style="font-size: 22px; font-weight: 800; color: #8b5cf6; margin-top: 4px;">—</div>
                        <div id="mStatBestStateRank" style="font-size: 11.5px; color: #64748b; margin-top: 2px;">State Rank: —</div>
                    </div>
                </div>

                <!-- Secondary Learning Insights (Questions, Mistakes, Referrals) -->
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px;">
                    <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px;">
                        <h4 style="font-size: 13.5px; font-weight: 700; color: #0f172a; margin-bottom: 12px;">🎯 Question Solving Accuracy</h4>
                        <div style="display: flex; justify-content: space-between; font-size: 12.5px; margin-bottom: 8px;">
                            <span style="color: #16a34a; font-weight: 700;">✓ Correct: <span id="mStatCorrectQ">0</span></span>
                            <span style="color: #dc2626; font-weight: 700;">✗ Wrong: <span id="mStatWrongQ">0</span></span>
                            <span style="color: #64748b; font-weight: 600;">○ Left: <span id="mStatUnattemptedQ">0</span></span>
                        </div>
                        <div style="background: #f1f5f9; border-radius: 6px; height: 10px; display: flex; overflow: hidden;">
                            <div id="mBarCorrect" style="background: #16a34a; width: 0%;"></div>
                            <div id="mBarWrong" style="background: #ef4444; width: 0%;"></div>
                            <div id="mBarUnattempted" style="background: #cbd5e1; width: 100%;"></div>
                        </div>
                    </div>

                    <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px;">
                        <h4 style="font-size: 13.5px; font-weight: 700; color: #0f172a; margin-bottom: 12px;">📚 Revision & App Engagement</h4>
                        <div style="display: flex; flex-direction: column; gap: 6px; font-size: 13px;">
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #475569;">Mistake Notebook Items:</span>
                                <span id="mStatNotebookCount" style="font-weight: 700; color: #0f172a;">0 questions</span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #475569;">Bookmarked Questions:</span>
                                <span id="mStatBookmarksCount" style="font-weight: 700; color: #0f172a;">0 saved</span>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #475569;">Referral Code / Friends:</span>
                                <span id="mStatReferrals" style="font-weight: 700; color: #2563eb;">—</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TAB 2: TEST ATTEMPTS & SCORECARDS LIST -->
            <div id="tab-history" class="modal-tab-content" style="display: none;">
                <div style="overflow-x: auto;">
                    <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
                        <thead>
                            <tr style="background: #f8fafc; border-bottom: 2px solid #e2e8f0; text-align: left;">
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569;">Test Title & Exam</th>
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569;">Date & Time</th>
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569;">Score</th>
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569;">Accuracy</th>
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569;">AIR Rank</th>
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569;">State Rank</th>
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569;">Time Taken</th>
                                <th style="padding: 10px 12px; font-weight: 700; color: #475569; text-align: right;">Status</th>
                            </tr>
                        </thead>
                        <tbody id="mAttemptsTableBody">
                            <!-- Populated via JavaScript -->
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- TAB 3: SUBSCRIPTION & MEMBERSHIP ENTITLEMENTS -->
            <div id="tab-subscription" class="modal-tab-content" style="display: none;">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                    <!-- Current Plan Card -->
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 18px;">
                        <h4 style="font-size: 13.5px; font-weight: 700; color: #64748b; text-transform: uppercase; margin-bottom: 12px;">Active Subscription Plan</h4>
                        <div id="mSubPlanName" style="font-size: 20px; font-weight: 800; color: #0f172a;">Free Trial</div>
                        <div id="mSubStatusBadge" style="display: inline-block; margin-top: 6px; padding: 3px 10px; border-radius: 12px; font-size: 11.5px; font-weight: 700; background: #e2e8f0; color: #475569;">
                            Active
                        </div>

                        <div style="margin-top: 14px; display: flex; flex-direction: column; gap: 8px; font-size: 13px; color: #475569;">
                            <div style="display: flex; justify-content: space-between;">
                                <span>Expiry Date:</span>
                                <strong id="mSubExpiry" style="color: #0f172a;">—</strong>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span>Days Remaining:</span>
                                <strong id="mSubDaysLeft" style="color: #2563eb;">—</strong>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span>Plan Price:</span>
                                <strong id="mSubPrice" style="color: #0f172a;">₹0</strong>
                            </div>
                        </div>
                    </div>

                    <!-- Grant / Extend Subscription Box -->
                    <div style="background: #ffffff; border: 1px solid #bfdbfe; border-radius: 12px; padding: 18px; box-shadow: 0 4px 6px -1px rgba(37,99,235,0.06);">
                        <h4 style="font-size: 14px; font-weight: 800; color: #1d4ed8; margin-bottom: 10px;">⭐ Grant or Extend Membership</h4>
                        <div style="font-size: 12px; color: #64748b; margin-bottom: 14px;">Select a plan and duration to immediately activate or extend this candidate's account.</div>

                        <div style="display: flex; flex-direction: column; gap: 10px;">
                            <div>
                                <label style="font-size: 12px; font-weight: 700; color: #334155; display: block; margin-bottom: 4px;">Choose Subscription Plan</label>
                                <select id="mGrantPlanSelect" style="width: 100%; padding: 8px 10px; border-radius: 8px; border: 1px solid #cbd5e1; font-size: 13px; background: #f8fafc; font-weight: 600;">
                                    <?php foreach ($plansList as $pl): ?>
                                        <option value="<?php echo $pl['id']; ?>"><?php echo htmlspecialchars($pl['name']); ?> (₹<?php echo number_format($pl['price']); ?> / <?php echo $pl['duration_days']; ?>d)</option>
                                    <?php endforeach; ?>
                                </select>
                            </div>

                            <div>
                                <label style="font-size: 12px; font-weight: 700; color: #334155; display: block; margin-bottom: 4px;">Duration (Days to Add)</label>
                                <select id="mGrantDaysSelect" style="width: 100%; padding: 8px 10px; border-radius: 8px; border: 1px solid #cbd5e1; font-size: 13px; background: #f8fafc; font-weight: 600;">
                                    <option value="30">+30 Days (1 Month)</option>
                                    <option value="90">+90 Days (3 Months)</option>
                                    <option value="180">+180 Days (6 Months)</option>
                                    <option value="365">+365 Days (1 Year)</option>
                                </select>
                            </div>

                            <button type="button" onclick="executeGrantSubscription()" style="margin-top: 6px; width: 100%; background: #2563eb; color: #ffffff; border: none; padding: 10px; border-radius: 8px; font-size: 13.5px; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px;">
                                🚀 Grant Subscription Plan
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- TAB 4: ADMIN ACTIONS & ALERTS -->
            <div id="tab-actions" class="modal-tab-content" style="display: none;">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                    <!-- Send Push/In-App Alert -->
                    <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 18px;">
                        <h4 style="font-size: 14px; font-weight: 700; color: #0f172a; margin-bottom: 10px;">🔔 Send Direct App Notification</h4>
                        <div style="font-size: 12px; color: #64748b; margin-bottom: 12px;">This message will appear instantly in the candidate's mobile app notification center.</div>

                        <div style="display: flex; flex-direction: column; gap: 10px;">
                            <input type="text" id="mNotifTitle" placeholder="Notification Title (e.g. Test Series Update)" style="width: 100%; padding: 8px 12px; border-radius: 8px; border: 1px solid #cbd5e1; font-size: 13px;">
                            <textarea id="mNotifMessage" placeholder="Message text for candidate..." rows="3" style="width: 100%; padding: 8px 12px; border-radius: 8px; border: 1px solid #cbd5e1; font-size: 13px;"></textarea>
                            <button type="button" onclick="executeSendNotification()" style="background: #0f172a; color: #ffffff; border: none; padding: 8px 14px; border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer;">
                                Send Notification ➔
                            </button>
                        </div>
                    </div>

                    <!-- Quick Status Change & Security -->
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 18px;">
                        <h4 style="font-size: 14px; font-weight: 700; color: #0f172a; margin-bottom: 10px;">🛡️ Account Security & Control</h4>
                        <div style="font-size: 12.5px; color: #64748b; margin-bottom: 16px;">Toggle account status or manage candidate authentication restrictions.</div>

                        <div style="display: flex; flex-direction: column; gap: 10px;">
                            <button type="button" id="mBtnToggleStatus" onclick="executeModalToggleStatus()" style="padding: 10px; border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer; border: 1px solid #e2e8f0; background: #ffffff;">
                                Toggle Status
                            </button>
                            <div style="font-size: 11.5px; color: #94a3b8; line-height: 1.4;">
                                ⚠️ Suspended accounts cannot start test attempts or access AI Exam-Twin features until reactivated by an admin.
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div>

        <!-- Modal Footer -->
        <div style="background: #f8fafc; border-top: 1px solid #e2e8f0; padding: 1rem 1.75rem; display: flex; justify-content: space-between; align-items: center;">
            <span style="font-size: 12px; color: #64748b;">EXAMVERSE Candidate Analytics System</span>
            <button type="button" onclick="closeCandidate360()" style="background: #e2e8f0; color: #334155; border: none; padding: 7px 18px; border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer;">
                Close Profile
            </button>
        </div>
    </div>
</div>

<style>
@keyframes modalFadeIn {
    from { opacity: 0; transform: scale(0.96); }
    to { opacity: 1; transform: scale(1); }
}
@keyframes spin {
    to { transform: rotate(360deg); }
}
.tab-btn {
    transition: all 0.15s ease;
}
.tab-btn.active-tab {
    color: #2563eb !important;
    border-bottom: 2px solid #2563eb !important;
    font-weight: 700 !important;
}
</style>

<script>
let currentModalCandidateId = 0;
let currentCandidateData = null;

function openCandidate360(userId) {
    currentModalCandidateId = userId;
    const modal = document.getElementById('candidate360Modal');
    modal.style.display = 'flex';

    // Show loading
    document.getElementById('modalLoadingSpinner').style.display = 'block';
    document.querySelectorAll('.modal-tab-content').forEach(el => el.style.display = 'none');

    // Switch to first tab
    switchModalTab('tab-analytics');

    fetch('ajax/user_detail.php?action=get_user_360&user_id=' + userId)
        .then(res => res.json())
        .then(json => {
            document.getElementById('modalLoadingSpinner').style.display = 'none';
            if (json.status !== 'success' || !json.data) {
                alert('Could not load candidate details: ' + (json.message || 'Unknown error'));
                closeCandidate360();
                return;
            }

            currentCandidateData = json.data;
            populateCandidateModal(json.data);
            document.getElementById('tab-analytics').style.display = 'block';
        })
        .catch(err => {
            document.getElementById('modalLoadingSpinner').style.display = 'none';
            alert('Network error loading candidate: ' + err);
            closeCandidate360();
        });
}

function closeCandidate360() {
    document.getElementById('candidate360Modal').style.display = 'none';
}

function switchModalTab(tabId) {
    document.querySelectorAll('.modal-tab-content').forEach(el => el.style.display = 'none');
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active-tab');
        btn.style.color = '#64748b';
        btn.style.borderBottomColor = 'transparent';
    });

    const activeTabEl = document.getElementById(tabId);
    if (activeTabEl && document.getElementById('modalLoadingSpinner').style.display === 'none') {
        activeTabEl.style.display = 'block';
    }

    const activeBtn = document.getElementById('btn-' + tabId);
    if (activeBtn) {
        activeBtn.classList.add('active-tab');
        activeBtn.style.color = '#2563eb';
        activeBtn.style.borderBottomColor = '#2563eb';
    }
}

function populateCandidateModal(data) {
    const u = data.user;
    const perf = data.performance;
    const sub = data.subscription;
    const attempts = data.attempts || [];

    // Header info
    document.getElementById('modalCandidateName').innerText = u.full_name || 'Candidate';
    document.getElementById('modalAvatar').innerText = (u.full_name || 'U')[0].toUpperCase();
    document.getElementById('modalUserIdBadge').innerText = '#USR-' + String(u.id).padStart(5, '0');
    
    const statusBadge = document.getElementById('modalStatusBadge');
    statusBadge.innerText = (u.status || 'active').toUpperCase();
    statusBadge.style.background = u.status === 'active' ? '#10b981' : '#ef4444';

    document.getElementById('modalCandidateMeta').innerHTML = 
        `📧 ${u.email} • 📞 ${u.mobile || 'No Mobile'} • 📍 ${u.state_name || 'All India'} ${u.district ? '('+u.district+')' : ''} • 🎓 ${u.qualification_name || 'General'}`;

    // Tab counts
    document.getElementById('tabCountTests').innerText = attempts.length;

    // Tab 1: Analytics & Performance Metrics
    document.getElementById('mStatCompletedTests').innerText = perf.completed_attempts;
    document.getElementById('mStatTotalAttempts').innerText = perf.total_attempts + ' total attempts started';
    document.getElementById('mStatAvgScore').innerText = perf.avg_score + ' Mks';
    document.getElementById('mStatMaxScore').innerText = 'Highest: ' + perf.max_score + ' Mks';
    document.getElementById('mStatAccuracy').innerText = perf.avg_accuracy + '%';
    document.getElementById('mStatBestRank').innerText = perf.best_air_rank ? '#' + perf.best_air_rank : '—';
    document.getElementById('mStatBestStateRank').innerText = 'State Rank: ' + (perf.best_state_rank ? '#' + perf.best_state_rank : '—');

    document.getElementById('mStatCorrectQ').innerText = perf.total_correct;
    document.getElementById('mStatWrongQ').innerText = perf.total_wrong;
    document.getElementById('mStatUnattemptedQ').innerText = perf.total_unattempted;

    const totalQ = (perf.total_correct + perf.total_wrong + perf.total_unattempted) || 1;
    document.getElementById('mBarCorrect').style.width = ((perf.total_correct / totalQ) * 100) + '%';
    document.getElementById('mBarWrong').style.width = ((perf.total_wrong / totalQ) * 100) + '%';
    document.getElementById('mBarUnattempted').style.width = ((perf.total_unattempted / totalQ) * 100) + '%';

    document.getElementById('mStatNotebookCount').innerText = perf.wrong_notebook_items + ' questions';
    document.getElementById('mStatBookmarksCount').innerText = perf.bookmarks_count + ' saved';
    document.getElementById('mStatReferrals').innerText = perf.referral_code + ' (' + perf.invited_friends + ' invited)';

    // Tab 2: Test Attempts Table
    const tbody = document.getElementById('mAttemptsTableBody');
    tbody.innerHTML = '';
    if (attempts.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center; padding:30px; color:#64748b;">No test attempts recorded for this candidate yet.</td></tr>';
    } else {
        attempts.forEach(att => {
            const tr = document.createElement('tr');
            tr.style.borderBottom = '1px solid #f1f5f9';
            
            const mins = Math.floor((att.total_time_spent_seconds || 0) / 60);
            const secs = (att.total_time_spent_seconds || 0) % 60;
            const timeStr = `${mins}m ${secs}s`;
            const dateStr = att.submitted_at || att.started_at || '—';

            tr.innerHTML = `
                <td style="padding:10px 12px;">
                    <strong style="color:#0f172a;">${att.test_title}</strong>
                    <div style="font-size:11.5px; color:#64748b;">${att.exam_title || 'Mock Test'} • ${att.total_questions || 0} Questions</div>
                </td>
                <td style="padding:10px 12px; color:#64748b; font-size:12px;">${dateStr}</td>
                <td style="padding:10px 12px; font-weight:800; color:#2563eb;">${parseFloat(att.score || 0).toFixed(1)} Mks</td>
                <td style="padding:10px 12px; font-weight:700; color:#16a34a;">${parseFloat(att.accuracy_percentage || 0).toFixed(1)}%</td>
                <td style="padding:10px 12px; font-weight:800; color:#8b5cf6;">${att.central_rank ? '#' + att.central_rank : '—'}</td>
                <td style="padding:10px 12px; font-weight:700; color:#0f172a;">${att.state_rank ? '#' + att.state_rank : '—'}</td>
                <td style="padding:10px 12px; color:#64748b;">${timeStr}</td>
                <td style="padding:10px 12px; text-align:right;">
                    <span style="background:${att.status === 'evaluated' ? '#dcfce7' : '#fef3c7'}; color:${att.status === 'evaluated' ? '#15803d' : '#b45309'}; padding:2px 8px; border-radius:4px; font-size:11px; font-weight:700;">
                        ${att.status}
                    </span>
                </td>
            `;
            tbody.appendChild(tr);
        });
    }

    // Tab 3: Subscription details
    if (sub) {
        document.getElementById('mSubPlanName').innerText = sub.plan_name;
        const subBadge = document.getElementById('mSubStatusBadge');
        subBadge.innerText = sub.is_expired ? 'EXPIRED' : (sub.status.toUpperCase());
        subBadge.style.background = sub.is_expired ? '#fee2e2' : '#dcfce7';
        subBadge.style.color = sub.is_expired ? '#b91c1c' : '#15803d';

        document.getElementById('mSubExpiry').innerText = sub.expiry_date;
        document.getElementById('mSubDaysLeft').innerText = sub.is_expired ? '0 days (Expired)' : (sub.days_left + ' days remaining');
        document.getElementById('mSubPrice').innerText = '₹' + sub.price;
    } else {
        document.getElementById('mSubPlanName').innerText = 'Free Tier (No active sub)';
        document.getElementById('mSubStatusBadge').innerText = 'FREE';
        document.getElementById('mSubStatusBadge').style.background = '#f1f5f9';
        document.getElementById('mSubStatusBadge').style.color = '#64748b';
        document.getElementById('mSubExpiry').innerText = '—';
        document.getElementById('mSubDaysLeft').innerText = '—';
        document.getElementById('mSubPrice').innerText = '₹0';
    }

    // Tab 4: Admin Quick Tools
    const btnToggle = document.getElementById('mBtnToggleStatus');
    if (u.status === 'active') {
        btnToggle.innerText = '⛔ Suspend Candidate Account';
        btnToggle.style.color = '#b91c1c';
        btnToggle.style.borderColor = '#fca5a5';
        btnToggle.style.background = '#fee2e2';
    } else {
        btnToggle.innerText = '● Reactivate Candidate Account';
        btnToggle.style.color = '#15803d';
        btnToggle.style.borderColor = '#86efac';
        btnToggle.style.background = '#dcfce7';
    }
}

function executeGrantSubscription() {
    if (!currentModalCandidateId) return;
    const planId = document.getElementById('mGrantPlanSelect').value;
    const days = document.getElementById('mGrantDaysSelect').value;

    fetch('ajax/user_detail.php?action=grant_subscription', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            user_id: currentModalCandidateId,
            plan_id: planId,
            days: days,
            csrf_token: '<?php echo htmlspecialchars(adminCsrfToken(), ENT_QUOTES); ?>'
        })
    })
    .then(res => res.json())
    .then(json => {
        if (json.status === 'success') {
            alert('✓ ' + json.message);
            openCandidate360(currentModalCandidateId);
        } else {
            alert('Error: ' + (json.message || 'Failed to grant subscription'));
        }
    })
    .catch(err => alert('Request failed: ' + err));
}

function executeSendNotification() {
    if (!currentModalCandidateId) return;
    const title = document.getElementById('mNotifTitle').value.trim();
    const message = document.getElementById('mNotifMessage').value.trim();
    if (!title || !message) {
        alert('Please fill in both title and message.');
        return;
    }

    fetch('ajax/user_detail.php?action=send_notification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            user_id: currentModalCandidateId,
            title: title,
            message: message,
            csrf_token: '<?php echo htmlspecialchars(adminCsrfToken(), ENT_QUOTES); ?>'
        })
    })
    .then(res => res.json())
    .then(json => {
        if (json.status === 'success') {
            alert('✓ Notification sent to candidate mobile app!');
            document.getElementById('mNotifTitle').value = '';
            document.getElementById('mNotifMessage').value = '';
        } else {
            alert('Error: ' + (json.message || 'Failed to send notification'));
        }
    })
    .catch(err => alert('Request failed: ' + err));
}

function executeModalToggleStatus() {
    if (!currentModalCandidateId || !currentCandidateData) return;
    const u = currentCandidateData.user;
    const newStatus = u.status === 'active' ? 'suspended' : 'active';
    singleToggleStatus(currentModalCandidateId, newStatus, u.full_name);
}

// Bulk Selection Helpers
function toggleSelectAll(masterCheckbox) {
    const checkboxes = document.querySelectorAll('.user-row-checkbox');
    checkboxes.forEach(cb => cb.checked = masterCheckbox.checked);
    onCheckboxChange();
}

function onCheckboxChange() {
    const checkboxes = document.querySelectorAll('.user-row-checkbox');
    const checked = document.querySelectorAll('.user-row-checkbox:checked');
    const master = document.getElementById('selectAllCheckbox');
    const bar = document.getElementById('bulkActionsBar');
    const countText = document.getElementById('selectedCountText');

    if (master && checkboxes.length > 0) {
        master.checked = checked.length === checkboxes.length;
    }

    if (checked.length > 0) {
        bar.style.display = 'flex';
        countText.innerText = checked.length + ' student' + (checked.length > 1 ? 's' : '') + ' selected';
    } else {
        bar.style.display = 'none';
    }
}

function submitBulkDelete() {
    const checked = document.querySelectorAll('.user-row-checkbox:checked');
    if (checked.length === 0) return;
    if (confirm('Are you sure you want to PERMANENTLY DELETE ' + checked.length + ' selected candidate account(s)? This action cannot be undone.')) {
        document.getElementById('bulkActionInput').value = 'bulk_delete';
        document.getElementById('bulkForm').submit();
    }
}

function submitBulkStatus(newStatus) {
    const checked = document.querySelectorAll('.user-row-checkbox:checked');
    if (checked.length === 0) return;
    if (confirm('Change status to ' + newStatus.toUpperCase() + ' for ' + checked.length + ' candidate(s)?')) {
        document.getElementById('bulkActionInput').value = 'bulk_status';
        document.getElementById('bulkStatusInput').value = newStatus;
        document.getElementById('bulkForm').submit();
    }
}

function singleToggleStatus(userId, newStatus, name) {
    if (confirm('Change status for ' + name + ' to ' + newStatus.toUpperCase() + '?')) {
        document.getElementById('singleActionInput').value = 'toggle_status';
        document.getElementById('singleUserIdInput').value = userId;
        document.getElementById('singleNewStatusInput').value = newStatus;
        document.getElementById('singleActionForm').submit();
    }
}

function singleDeleteUser(userId, name) {
    if (confirm('PERMANENTLY DELETE candidate ' + name + '?')) {
        document.getElementById('singleActionInput').value = 'delete_user';
        document.getElementById('singleUserIdInput').value = userId;
        document.getElementById('singleActionForm').submit();
    }
}
</script>
