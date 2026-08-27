<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$message = '';
$messageType = '';

// Handle Status Change (Suspend / Activate / Delete)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['action']) && isset($_POST['user_id'])) {
        $userId = intval($_POST['user_id']);
        $action = trim($_POST['action']);

        if ($action === 'toggle_status') {
            $newStatus = trim($_POST['new_status']);
            if (in_array($newStatus, ['active', 'suspended', 'pending'])) {
                $stmt = $db->prepare("UPDATE users SET status = :status WHERE id = :id");
                $stmt->execute(['status' => $newStatus, 'id' => $userId]);
                $message = "User #USR-" . sprintf('%05d', $userId) . " status updated to " . ucfirst($newStatus);
                $messageType = "success";
            }
        } elseif ($action === 'delete_user') {
            // Delete user attempts and user
            $db->prepare("DELETE FROM test_attempts WHERE user_id = :id")->execute(['id' => $userId]);
            $stmt = $db->prepare("DELETE FROM users WHERE id = :id");
            $stmt->execute(['id' => $userId]);
            $message = "User #USR-" . sprintf('%05d', $userId) . " deleted successfully.";
            $messageType = "success";
        }
    }
}

// Search & Filter Parameters
$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$statusFilter = isset($_GET['status']) ? trim($_GET['status']) : '';
$stateFilter = isset($_GET['state_id']) ? intval($_GET['state_id']) : 0;

// Base queries for metrics
$totalUsers = $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
$activeUsers = $db->query("SELECT COUNT(*) FROM users WHERE status = 'active'")->fetchColumn();
$suspendedUsers = $db->query("SELECT COUNT(*) FROM users WHERE status = 'suspended'")->fetchColumn();
$verifiedUsers = $db->query("SELECT COUNT(*) FROM users WHERE is_verified = 1")->fetchColumn();

// Build SQL Query for Users Table
$whereClauses = [];
$params = [];

if ($search !== '') {
    $whereClauses[] = "(u.full_name LIKE :search OR u.email LIKE :search OR u.mobile LIKE :search)";
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
        <div style="padding: 12px 20px; border-radius: 10px; font-size: 14px; font-weight: 600; background: <?php echo $messageType === 'success' ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)'; ?>; color: <?php echo $messageType === 'success' ? '#10b981' : '#ef4444'; ?>; border: 1px solid <?php echo $messageType === 'success' ? 'rgba(16, 185, 129, 0.3)' : 'rgba(239, 68, 68, 0.3)'; ?>;">
            ✓ <?php echo htmlspecialchars($message); ?>
        </div>
    <?php endif; ?>

    <!-- Summary Metrics Grid -->
    <div class="metrics-grid">
        <div class="metric-card">
            <div class="metric-title">Total Registered Candidates</div>
            <div class="metric-value"><?php echo number_format($totalUsers); ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Active Candidates</div>
            <div class="metric-value" style="color: #10b981;"><?php echo number_format($activeUsers); ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Suspended Accounts</div>
            <div class="metric-value" style="color: #ef4444;"><?php echo number_format($suspendedUsers); ?></div>
        </div>
        <div class="metric-card">
            <div class="metric-title">Verified Profiles</div>
            <div class="metric-value" style="color: #38bdf8;"><?php echo number_format($verifiedUsers); ?></div>
        </div>
    </div>

    <!-- Filters & Search Bar -->
    <div class="table-card" style="padding: 16px 24px;">
        <form method="get" action="index.php" style="display: flex; flex-wrap: wrap; gap: 12px; align-items: center; justify-content: space-between;">
            <input type="hidden" name="page" value="users">
            
            <div style="display: flex; gap: 12px; flex-wrap: wrap; flex: 1;">
                <input type="text" name="search" placeholder="Search by Candidate Name, Email, or Mobile..." value="<?php echo htmlspecialchars($search); ?>" 
                       style="background: var(--bg-dark); border: 1px solid var(--border-glass); color: #fff; padding: 10px 16px; border-radius: 10px; font-size: 13px; min-width: 280px; flex: 1;">

                <select name="status" style="background: var(--bg-dark); border: 1px solid var(--border-glass); color: #fff; padding: 10px 14px; border-radius: 10px; font-size: 13px;">
                    <option value="">All Statuses</option>
                    <option value="active" <?php echo $statusFilter === 'active' ? 'selected' : ''; ?>>Active Only</option>
                    <option value="suspended" <?php echo $statusFilter === 'suspended' ? 'selected' : ''; ?>>Suspended Only</option>
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

    <!-- Candidate Table Card -->
    <div class="table-card">
        <div class="table-header" style="display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div class="table-title">👥 Registered Candidates Directory</div>
                <div style="font-size: 12px; color: var(--text-secondary); margin-top: 2px;">
                    Showing <?php echo count($users); ?> candidate accounts
                </div>
            </div>
        </div>

        <table style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr>
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
                        <td colspan="8" style="text-align: center; color: var(--text-muted); padding: 40px;">
                            No registered candidates found matching your criteria.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($users as $u): ?>
                        <tr>
                            <td>
                                <span style="font-weight: 700; color: #38bdf8; font-family: monospace;">#USR-<?php echo sprintf('%05d', $u['id']); ?></span>
                            </td>
                            <td>
                                <div style="display: flex; align-items: center; gap: 12px;">
                                    <div style="width: 36px; height: 36px; border-radius: 50%; background: linear-gradient(135deg, #6366f1, #38bdf8); display: flex; align-items: center; justify-content: center; font-weight: 700; color: #fff; font-size: 14px;">
                                        <?php echo strtoupper(substr($u['full_name'], 0, 1)); ?>
                                    </div>
                                    <div>
                                        <div style="font-weight: 700; color: #ffffff; font-size: 14px;"><?php echo htmlspecialchars($u['full_name']); ?></div>
                                        <?php if ($u['is_verified']): ?>
                                            <span style="font-size: 10px; color: #10b981; background: rgba(16, 185, 129, 0.15); padding: 2px 6px; border-radius: 4px; font-weight: 600;">✓ Verified</span>
                                        <?php else: ?>
                                            <span style="font-size: 10px; color: #f59e0b; background: rgba(245, 158, 11, 0.15); padding: 2px 6px; border-radius: 4px; font-weight: 600;">Unverified</span>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div style="font-size: 13px; color: #f8fafc; font-weight: 500;"><?php echo htmlspecialchars($u['email']); ?></div>
                                <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;">📞 <?php echo htmlspecialchars($u['mobile']); ?></div>
                            </td>
                            <td>
                                <div style="font-size: 12px; color: #38bdf8; font-weight: 600;"><?php echo htmlspecialchars($u['state_name'] ?: 'Not Specified'); ?></div>
                                <div style="font-size: 11px; color: #94a3b8; margin-top: 2px;"><?php echo htmlspecialchars($u['qualification_name'] ?: 'N/A'); ?></div>
                            </td>
                            <td>
                                <span class="badge badge-info" style="font-size: 12px; padding: 4px 10px;">
                                    <?php echo number_format($u['total_attempts']); ?> Tests Taken
                                </span>
                            </td>
                            <td>
                                <?php if ($u['status'] === 'active'): ?>
                                    <span style="background: rgba(16, 185, 129, 0.15); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.3); padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; display: inline-block;">
                                        ● Active
                                    </span>
                                <?php else: ?>
                                    <span style="background: rgba(239, 68, 68, 0.15); color: #ef4444; border: 1px solid rgba(239, 68, 68, 0.3); padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; display: inline-block;">
                                        ⛔ Suspended
                                    </span>
                                <?php endif; ?>
                            </td>
                            <td style="font-size: 12px; color: #94a3b8;">
                                <?php echo date('M d, Y H:i', strtotime($u['created_at'])); ?>
                            </td>
                            <td style="text-align: right;">
                                <div style="display: flex; gap: 6px; justify-content: flex-end;">
                                    <form method="post" style="display: inline;" onsubmit="return confirm('Change status for <?php echo addslashes($u['full_name']); ?>?');">
                                        <input type="hidden" name="action" value="toggle_status">
                                        <input type="hidden" name="user_id" value="<?php echo $u['id']; ?>">
                                        <?php if ($u['status'] === 'active'): ?>
                                            <input type="hidden" name="new_status" value="suspended">
                                            <button type="submit" style="background: rgba(239,68,68,0.15); color: #ef4444; border: 1px solid rgba(239,68,68,0.3); padding: 6px 12px; border-radius: 8px; font-size: 11px; font-weight: 600; cursor: pointer;">
                                                Suspend
                                            </button>
                                        <?php else: ?>
                                            <input type="hidden" name="new_status" value="active">
                                            <button type="submit" style="background: rgba(16,185,129,0.15); color: #10b981; border: 1px solid rgba(16,185,129,0.3); padding: 6px 12px; border-radius: 8px; font-size: 11px; font-weight: 600; cursor: pointer;">
                                                Activate
                                            </button>
                                        <?php endif; ?>
                                    </form>

                                    <form method="post" style="display: inline;" onsubmit="return confirm('PERMANENTLY DELETE candidate <?php echo addslashes($u['full_name']); ?>?');">
                                        <input type="hidden" name="action" value="delete_user">
                                        <input type="hidden" name="user_id" value="<?php echo $u['id']; ?>">
                                        <button type="submit" style="background: rgba(255,255,255,0.05); color: #64748b; border: 1px solid rgba(255,255,255,0.1); padding: 6px 10px; border-radius: 8px; font-size: 11px; cursor: pointer;">
                                            🗑️
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>

</div>
