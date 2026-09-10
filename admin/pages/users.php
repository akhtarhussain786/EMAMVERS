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
           (SELECT COUNT(*) FROM test_attempts WHERE user_id = u.id) as total_attempts
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
?>

<div style="display: flex; flex-direction: column; gap: 1.5rem;">

    <?php if ($message): ?>
        <div style="padding: 12px 20px; border-radius: 10px; font-size: 14px; font-weight: 600; background: <?php echo $messageType === 'success' ? 'rgba(21, 128, 61, 0.15)' : 'rgba(239, 68, 68, 0.15)'; ?>; color: <?php echo $messageType === 'success' ? 'var(--accent-emerald)' : 'var(--accent-danger)'; ?>; border: 1px solid <?php echo $messageType === 'success' ? 'rgba(21, 128, 61, 0.3)' : 'rgba(239, 68, 68, 0.3)'; ?>;">
            ✓ <?php echo htmlspecialchars($message); ?>
        </div>
    <?php endif; ?>

    <!-- Summary Metrics Grid -->
    <div class="metrics-grid">
        <div class="metric-card">
            <div class="metric-title">Total Registered Candidates</div>
            <div class="metric-value"><?php echo number_format($totalUsers); ?></div>
            <div class="metric-subtitle">Across all Indian states</div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Active Candidates</div>
            <div class="metric-value" style="color: var(--accent-emerald);"><?php echo number_format($activeUsers); ?></div>
            <div class="metric-subtitle">Eligible for practice & tests</div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Verified Profiles</div>
            <div class="metric-value" style="color: var(--accent-blue);"><?php echo number_format($verifiedUsers); ?></div>
            <div class="metric-subtitle">Completed OTP / profile verification</div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Suspended Accounts</div>
            <div class="metric-value" style="color: var(--accent-danger);"><?php echo number_format($suspendedUsers); ?></div>
            <div class="metric-subtitle">Restricted from platform access</div>
        </div>
    </div>

    <!-- Filters and Search Bar -->
    <div class="table-card" style="padding: 1.25rem;">
        <form method="get" action="index.php" style="display: flex; gap: 12px; flex-wrap: wrap; align-items: center; justify-content: space-between;">
            <input type="hidden" name="page" value="users">
            
            <div style="display: flex; gap: 12px; flex-wrap: wrap; flex: 1;">
                <div style="position: relative; min-width: 260px; flex: 1;">
                    <input type="text" name="search" value="<?php echo htmlspecialchars($search); ?>" 
                           placeholder="Search by name, email, mobile, district..." 
                           style="width: 100%; box-sizing: border-box; background: var(--bg-dark); border: 1px solid var(--border-glass); color: #fff; padding: 10px 14px; border-radius: 10px; font-size: 13px;">
                </div>

                <select name="status" style="background: var(--bg-dark); border: 1px solid var(--border-glass); color: #fff; padding: 10px 14px; border-radius: 10px; font-size: 13px;">
                    <option value="">All Account Statuses</option>
                    <option value="active" <?php echo $statusFilter === 'active' ? 'selected' : ''; ?>>Active</option>
                    <option value="suspended" <?php echo $statusFilter === 'suspended' ? 'selected' : ''; ?>>Suspended</option>
                    <option value="pending" <?php echo $statusFilter === 'pending' ? 'selected' : ''; ?>>Pending</option>
                </select>

                <select name="state_id" style="background: var(--bg-dark); border: 1px solid var(--border-glass); color: #fff; padding: 10px 14px; border-radius: 10px; font-size: 13px;">
                    <option value="0">All States</option>
                    <?php foreach ($statesList as $st): ?>
                        <option value="<?php echo $st['id']; ?>" <?php echo $stateFilter == $st['id'] ? 'selected' : ''; ?>>
                            <?php echo htmlspecialchars($st['name']); ?>
                        </option>
                    <?php endforeach; ?>
                </select>

                <button type="submit" class="btn btn-primary" style="padding: 10px 20px; font-size: 13px;">Filter Results</button>
                <?php if ($search !== '' || $statusFilter !== '' || $stateFilter > 0): ?>
                    <a href="index.php?page=users" class="btn" style="background: rgba(255,255,255,0.08); color: #94a3b8; padding: 10px 16px; font-size: 13px; text-decoration: none; border-radius: 10px;">Clear Filters</a>
                <?php endif; ?>
            </div>
        </form>
    </div>

    <!-- Candidate Table Card with Bulk Action Support -->
    <div class="table-card">
        <form id="bulkForm" method="post" action="index.php?page=users">
            <input type="hidden" name="action" id="bulkActionInput" value="">
            <input type="hidden" name="new_status" id="bulkStatusInput" value="">

            <div class="table-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                <div>
                    <div class="table-title">👥 Registered Candidates Directory</div>
                    <div style="font-size: 12px; color: var(--text-secondary); margin-top: 2px;">
                        Showing <?php echo count($users); ?> candidate accounts
                    </div>
                </div>

                <!-- Floating / Top Bulk Actions Bar -->
                <div id="bulkActionsBar" style="display: none; align-items: center; gap: 10px; background: rgba(30, 41, 59, 0.9); border: 1px solid #3b82f6; padding: 6px 14px; border-radius: 10px;">
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

            <table style="width: 100%; border-collapse: collapse;">
                <thead>
                    <tr>
                        <th style="width: 40px; text-align: center;">
                            <input type="checkbox" id="selectAllCheckbox" onchange="toggleSelectAll(this)" title="Select All Candidates" style="width: 16px; height: 16px; cursor: pointer; accent-color: #2563eb;">
                        </th>
                        <th>User ID</th>
                        <th>Candidate Profile</th>
                        <th>Contact Info</th>
                        <th>State & Qualification</th>
                        <th>Test Attempts</th>
                        <th>Status</th>
                        <th>Registered On</th>
                        <th style="text-align: right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($users)): ?>
                        <tr>
                            <td colspan="9" style="text-align: center; color: var(--text-muted); padding: 40px;">
                                No registered candidates found matching your criteria.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($users as $u): ?>
                            <tr>
                                <td style="text-align: center;">
                                    <input type="checkbox" name="selected_users[]" value="<?php echo $u['id']; ?>" class="user-row-checkbox" onchange="onCheckboxChange()" style="width: 16px; height: 16px; cursor: pointer; accent-color: #2563eb;">
                                </td>
                                <td>
                                    <span style="font-weight: 700; color: var(--accent-blue); font-family: monospace;">#USR-<?php echo sprintf('%05d', $u['id']); ?></span>
                                </td>
                                <td>
                                    <div style="display: flex; align-items: center; gap: 12px;">
                                        <div style="width: 36px; height: 36px; border-radius: 50%; background: linear-gradient(135deg, var(--accent-indigo), var(--accent-blue)); display: flex; align-items: center; justify-content: center; font-weight: 700; color: #fff; font-size: 14px;">
                                            <?php echo strtoupper(substr($u['full_name'], 0, 1)); ?>
                                        </div>
                                        <div>
                                            <div style="font-weight: 700; color: #ffffff; font-size: 14px;"><?php echo htmlspecialchars($u['full_name']); ?></div>
                                            <?php if ($u['is_verified']): ?>
                                                <span style="font-size: 10px; color: var(--accent-emerald); background: rgba(21, 128, 61, 0.15); padding: 2px 6px; border-radius: 4px; font-weight: 600;">✓ Verified</span>
                                            <?php else: ?>
                                                <span style="font-size: 10px; color: var(--accent-amber); background: rgba(245, 158, 11, 0.15); padding: 2px 6px; border-radius: 4px; font-weight: 600;">Unverified</span>
                                            <?php endif; ?>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div style="font-size: 13px; color: #f8fafc; font-weight: 500;"><?php echo htmlspecialchars($u['email']); ?></div>
                                    <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">📞 <?php echo htmlspecialchars($u['mobile']); ?></div>
                                </td>
                                <td>
                                    <div style="font-size: 13px; color: var(--accent-blue); font-weight: 700;">
                                        📍 <?php echo htmlspecialchars($u['state_name'] ?: 'All India'); ?>
                                        <?php if (!empty($u['district'])): ?>
                                            <span style="font-size: 12px; color: #60a5fa; font-weight: 600;">(<?php echo htmlspecialchars($u['district']); ?>)</span>
                                        <?php endif; ?>
                                    </div>
                                    <div style="font-size: 11.5px; color: #94a3b8; margin-top: 2px;">
                                        🎓 <?php echo htmlspecialchars($u['qualification_name'] ?: 'Not Specified'); ?>
                                    </div>
                                </td>
                                <td>
                                    <span class="badge badge-info" style="font-size: 12px; padding: 4px 10px;">
                                        <?php echo number_format($u['total_attempts']); ?> Tests Taken
                                    </span>
                                </td>
                                <td>
                                    <?php if ($u['status'] === 'active'): ?>
                                        <span style="background: rgba(21, 128, 61, 0.15); color: var(--accent-emerald); border: 1px solid rgba(21, 128, 61, 0.3); padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; display: inline-block;">
                                            ● Active
                                        </span>
                                    <?php else: ?>
                                        <span style="background: rgba(239, 68, 68, 0.15); color: var(--accent-danger); border: 1px solid rgba(239, 68, 68, 0.3); padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; display: inline-block;">
                                            ⛔ Suspended
                                        </span>
                                    <?php endif; ?>
                                </td>
                                <td style="font-size: 12px; color: #94a3b8;">
                                    <?php echo date('M d, Y H:i', strtotime($u['created_at'])); ?>
                                </td>
                                <td style="text-align: right;">
                                    <div style="display: flex; gap: 6px; justify-content: flex-end;">
                                        <button type="button" onclick="singleToggleStatus(<?php echo $u['id']; ?>, '<?php echo $u['status'] === 'active' ? 'suspended' : 'active'; ?>', '<?php echo addslashes($u['full_name']); ?>')" 
                                                style="background: <?php echo $u['status'] === 'active' ? 'rgba(239,68,68,0.15)' : 'rgba(16,185,129,0.15)'; ?>; color: <?php echo $u['status'] === 'active' ? 'var(--accent-danger)' : 'var(--accent-emerald)'; ?>; border: 1px solid <?php echo $u['status'] === 'active' ? 'rgba(239,68,68,0.3)' : 'rgba(16,185,129,0.3)'; ?>; padding: 6px 12px; border-radius: 8px; font-size: 11px; font-weight: 600; cursor: pointer;">
                                            <?php echo $u['status'] === 'active' ? 'Suspend' : 'Activate'; ?>
                                        </button>

                                        <button type="button" onclick="singleDeleteUser(<?php echo $u['id']; ?>, '<?php echo addslashes($u['full_name']); ?>')" 
                                                style="background: rgba(255,255,255,0.05); color: #ef4444; border: 1px solid rgba(239,68,68,0.25); padding: 6px 10px; border-radius: 8px; font-size: 11px; cursor: pointer;" title="Delete User">
                                            🗑️
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </form>
    </div>

</div>

<!-- Single Action Hidden Form -->
<form id="singleActionForm" method="post" action="index.php?page=users" style="display:none;">
    <input type="hidden" name="action" id="singleActionInput" value="">
    <input type="hidden" name="user_id" id="singleUserIdInput" value="">
    <input type="hidden" name="new_status" id="singleNewStatusInput" value="">
</form>

<script>
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
