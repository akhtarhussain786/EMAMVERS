<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$successMsg = '';
$errorMsg = '';

// Seed default plans if empty
$planCount = $db->query("SELECT COUNT(*) FROM subscription_plans")->fetchColumn();
if ($planCount == 0) {
    $seedPlans = [
        ['Free Referral / Trial Pass', 30, 0.00, 'Complimentary 30-day access for new invited aspirants', 1],
        ['Pro Monthly Pass', 30, 299.00, 'Unlimited mock tests, AI Exam-Twin, step-by-step solutions & shortcut tricks', 1],
        ['Pro Quarterly Sprint', 90, 699.00, 'Complete tier access for 3 months with priority test series', 1],
        ['ExamVerse Elite Annual', 365, 1999.00, 'All-inclusive annual pass for all exams, pyqs, map learning & mentor notes', 1],
    ];
    $stmtSeed = $db->prepare("INSERT INTO subscription_plans (name, duration_days, price, description, is_active) VALUES (?, ?, ?, ?, ?)");
    foreach ($seedPlans as $p) {
        $stmtSeed->execute($p);
    }
}

// Handle POST actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!adminCsrfValid($_POST['csrf_token'] ?? null)) {
        $errorMsg = 'Security validation failed (CSRF expired).';
    } else {
        $action = $_POST['action'] ?? '';

        if ($action === 'create_plan') {
            $name = trim($_POST['name'] ?? '');
            $duration = (int)($_POST['duration_days'] ?? 30);
            $price = (float)($_POST['price'] ?? 0.0);
            $description = trim($_POST['description'] ?? '');
            $isActive = isset($_POST['is_active']) ? 1 : 0;

            if (empty($name)) {
                $errorMsg = 'Plan name is required.';
            } else {
                $stmt = $db->prepare("INSERT INTO subscription_plans (name, duration_days, price, description, is_active) VALUES (?, ?, ?, ?, ?)");
                $stmt->execute([$name, $duration, $price, $description, $isActive]);
                $successMsg = 'Subscription plan created successfully.';
            }
        } elseif ($action === 'toggle_plan') {
            $planId = (int)($_POST['plan_id'] ?? 0);
            $newStatus = (int)($_POST['new_status'] ?? 0);
            $stmt = $db->prepare("UPDATE subscription_plans SET is_active = ? WHERE id = ?");
            $stmt->execute([$newStatus, $planId]);
            $successMsg = 'Plan status updated.';
        } elseif ($action === 'grant_subscription') {
            $userId = (int)($_POST['user_id'] ?? 0);
            $planId = (int)($_POST['plan_id'] ?? 1);
            $days = (int)($_POST['days'] ?? 30);
            $status = $_POST['status'] ?? 'active';

            if ($userId <= 0) {
                $errorMsg = 'Valid user ID is required.';
            } else {
                // Check if user has active sub
                $stmtCur = $db->prepare("SELECT id, expiry_date FROM user_subscriptions WHERE user_id = ? AND status IN ('active', 'trial', 'expiring') ORDER BY expiry_date DESC LIMIT 1");
                $stmtCur->execute([$userId]);
                $cur = $stmtCur->fetch();

                if ($cur) {
                    $baseTime = strtotime($cur['expiry_date']) > time() ? strtotime($cur['expiry_date']) : time();
                    $newExpiry = date('Y-m-d H:i:s', $baseTime + ($days * 86400));
                    $stmtUp = $db->prepare("UPDATE user_subscriptions SET expiry_date = ?, plan_id = ?, status = ? WHERE id = ?");
                    $stmtUp->execute([$newExpiry, $planId, $status, $cur['id']]);
                } else {
                    $newExpiry = date('Y-m-d H:i:s', time() + ($days * 86400));
                    $stmtIns = $db->prepare("INSERT INTO user_subscriptions (user_id, plan_id, status, expiry_date) VALUES (?, ?, ?, ?)");
                    $stmtIns->execute([$userId, $planId, $status, $newExpiry]);
                }

                // Send user notification
                try {
                    $stmtNotif = $db->prepare("INSERT INTO user_notifications (user_id, title, message, type, is_read) VALUES (?, ?, ?, 'subscription', 0)");
                    $stmtNotif->execute([$userId, '🌟 Pro Membership Updated', "Your ExamVerse membership has been extended by $days days. Valid until " . date('d M Y', strtotime($newExpiry)) . "."]);
                } catch (Exception $e) {}

                $successMsg = "Subscription successfully granted/extended for User #$userId ($days days).";
            }
        } elseif ($action === 'cancel_subscription') {
            $subId = (int)($_POST['sub_id'] ?? 0);
            $stmt = $db->prepare("UPDATE user_subscriptions SET status = 'cancelled' WHERE id = ?");
            $stmt->execute([$subId]);
            $successMsg = 'Subscription cancelled.';
        }
    }
}

// Fetch Metrics
$totalActiveSubs = (int)$db->query("SELECT COUNT(*) FROM user_subscriptions WHERE status IN ('active', 'trial', 'expiring') AND expiry_date > NOW()")->fetchColumn();
$totalTrials = (int)$db->query("SELECT COUNT(*) FROM user_subscriptions WHERE status = 'trial' AND expiry_date > NOW()")->fetchColumn();
$expiringSoon = (int)$db->query("SELECT COUNT(*) FROM user_subscriptions WHERE status IN ('active', 'trial', 'expiring') AND expiry_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)")->fetchColumn();
$totalPlans = (int)$db->query("SELECT COUNT(*) FROM subscription_plans WHERE is_active = 1")->fetchColumn();

// Fetch Plans
$plans = $db->query("SELECT p.*, (SELECT COUNT(*) FROM user_subscriptions us WHERE us.plan_id = p.id AND us.status IN ('active', 'trial') AND us.expiry_date > NOW()) as active_users_count FROM subscription_plans p ORDER BY price ASC")->fetchAll();

// Fetch Subscriptions List
$filterStatus = $_GET['status'] ?? 'all';
$search = trim($_GET['search'] ?? '');

$query = "
    SELECT us.*, u.full_name, u.email, u.mobile, p.name as plan_name, p.price as plan_price,
           DATEDIFF(us.expiry_date, NOW()) as days_left
    FROM user_subscriptions us
    JOIN users u ON us.user_id = u.id
    LEFT JOIN subscription_plans p ON us.plan_id = p.id
    WHERE 1=1
";
$params = [];

if ($filterStatus !== 'all') {
    $query .= " AND us.status = ?";
    $params[] = $filterStatus;
}
if (!empty($search)) {
    $query .= " AND (u.full_name LIKE ? OR u.email LIKE ? OR u.mobile LIKE ?)";
    $params[] = "%$search%";
    $params[] = "%$search%";
    $params[] = "%$search%";
}

$query .= " ORDER BY us.created_at DESC LIMIT 50";
$stmtSubs = $db->prepare($query);
$stmtSubs->execute($params);
$subscriptions = $stmtSubs->fetchAll();

// Users list for Grant modal dropdown (recent 50)
$candidates = $db->query("SELECT id, full_name, email, mobile FROM users ORDER BY id DESC LIMIT 50")->fetchAll();
?>

<?php if ($successMsg): ?>
    <div style="background:rgba(21,128,61,0.15);border:1px solid #15803d;color:#15803d;padding:12px 16px;border-radius:8px;margin-bottom:20px;font-weight:600;">
        ✓ <?php echo htmlspecialchars($successMsg); ?>
    </div>
<?php endif; ?>

<?php if ($errorMsg): ?>
    <div style="background:rgba(185,28,28,0.15);border:1px solid #b91c1c;color:#b91c1c;padding:12px 16px;border-radius:8px;margin-bottom:20px;font-weight:600;">
        ⚠ <?php echo htmlspecialchars($errorMsg); ?>
    </div>
<?php endif; ?>

<!-- 1. METRICS OVERVIEW -->
<div class="metrics-grid" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); margin-bottom: 24px;">
    <div class="metric-card">
        <div class="metric-title">Active Subscribers</div>
        <div class="metric-value" style="color:var(--accent);"><?php echo number_format($totalActiveSubs); ?></div>
        <div class="metric-sub">Accessing Pro Mock Tests & AI</div>
    </div>
    <div class="metric-card">
        <div class="metric-title">Free Trial / Referral Pass</div>
        <div class="metric-value" style="color:#15803d;"><?php echo number_format($totalTrials); ?></div>
        <div class="metric-sub">Acquisition & Growth users</div>
    </div>
    <div class="metric-card">
        <div class="metric-title">Expiring Soon (≤ 7 Days)</div>
        <div class="metric-value" style="color:#b45309;"><?php echo number_format($expiringSoon); ?></div>
        <div class="metric-sub">Target for renewal prompts</div>
    </div>
    <div class="metric-card">
        <div class="metric-title">Active Plans</div>
        <div class="metric-value" style="color:#6d28d9;"><?php echo $totalPlans; ?></div>
        <div class="metric-sub">Catalog tier offerings</div>
    </div>
</div>

<!-- 2. SUBSCRIPTION PLANS CATALOG -->
<div class="card" style="margin-bottom: 24px;">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;flex-wrap:wrap;gap:12px;">
        <div>
            <h3 style="margin:0;font-size:18px;font-weight:700;">💳 Subscription Plans & Pricing Catalog</h3>
            <p style="margin:4px 0 0 0;font-size:13px;color:var(--text-muted);">Manage platform membership tiers, pricing, and durations.</p>
        </div>
        <div style="display:flex;gap:10px;">
            <button class="btn btn-outline" onclick="openGrantModal()">➕ Grant Membership to User</button>
            <button class="btn btn-primary" onclick="openCreatePlanModal()">➕ Create New Plan</button>
        </div>
    </div>

    <div style="display:grid;grid-template-columns:repeat(auto-fit, minmax(260px, 1fr));gap:16px;">
        <?php foreach ($plans as $plan): ?>
            <div style="background:var(--surface-elevated, #f5f0e1);border:1px solid var(--card-border, #e3dbc5);border-radius:12px;padding:18px;display:flex;flex-direction:column;justify-content:space-between;">
                <div>
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                        <span style="font-weight:700;font-size:16px;color:var(--text);"><?php echo htmlspecialchars($plan['name']); ?></span>
                        <span class="badge <?php echo $plan['is_active'] ? 'badge-success' : 'badge-danger'; ?>" style="font-size:10px;">
                            <?php echo $plan['is_active'] ? 'ACTIVE' : 'INACTIVE'; ?>
                        </span>
                    </div>
                    <div style="font-size:24px;font-weight:800;color:var(--accent);margin-bottom:6px;">
                        <?php echo $plan['price'] > 0 ? '₹' . number_format($plan['price'], 2) : 'FREE'; ?>
                        <span style="font-size:12px;font-weight:500;color:var(--text-muted);"> / <?php echo $plan['duration_days']; ?> Days</span>
                    </div>
                    <p style="font-size:12.5px;color:var(--text-muted);line-height:1.4;margin:0 0 12px 0;">
                        <?php echo htmlspecialchars($plan['description'] ?? 'No description.'); ?>
                    </p>
                </div>
                <div style="border-top:1px solid var(--card-border, #e3dbc5);padding-top:12px;display:flex;justify-content:space-between;align-items:center;">
                    <span style="font-size:12px;color:var(--text-muted);"><strong><?php echo (int)$plan['active_users_count']; ?></strong> active subscribers</span>
                    <form method="POST" style="margin:0;">
                        <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars(adminCsrfToken()); ?>">
                        <input type="hidden" name="action" value="toggle_plan">
                        <input type="hidden" name="plan_id" value="<?php echo $plan['id']; ?>">
                        <input type="hidden" name="new_status" value="<?php echo $plan['is_active'] ? '0' : '1'; ?>">
                        <button type="submit" class="btn btn-sm <?php echo $plan['is_active'] ? 'btn-outline' : 'btn-primary'; ?>" style="padding:4px 10px;font-size:11px;">
                            <?php echo $plan['is_active'] ? 'Deactivate' : 'Activate'; ?>
                        </button>
                    </form>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
</div>

<!-- 3. USER SUBSCRIPTIONS DIRECTORY -->
<div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;flex-wrap:wrap;gap:12px;">
        <div>
            <h3 style="margin:0;font-size:18px;font-weight:700;">👥 Candidate Subscriptions & Entitlement Ledger</h3>
            <p style="margin:4px 0 0 0;font-size:13px;color:var(--text-muted);">Live status of candidate Pro memberships, referral rewards & extensions.</p>
        </div>
        <form method="GET" style="display:flex;gap:10px;margin:0;flex-wrap:wrap;">
            <input type="hidden" name="page" value="subscriptions">
            <select name="status" class="form-control" style="width:auto;font-size:13px;" onchange="this.form.submit()">
                <option value="all" <?php echo $filterStatus==='all'?'selected':'';?>>All Statuses</option>
                <option value="active" <?php echo $filterStatus==='active'?'selected':'';?>>Active</option>
                <option value="trial" <?php echo $filterStatus==='trial'?'selected':'';?>>Trial</option>
                <option value="expiring" <?php echo $filterStatus==='expiring'?'selected':'';?>>Expiring Soon</option>
                <option value="expired" <?php echo $filterStatus==='expired'?'selected':'';?>>Expired</option>
                <option value="cancelled" <?php echo $filterStatus==='cancelled'?'selected':'';?>>Cancelled</option>
            </select>
            <input type="text" name="search" class="form-control" placeholder="Search candidate..." value="<?php echo htmlspecialchars($search); ?>" style="width:200px;font-size:13px;">
            <button type="submit" class="btn btn-primary" style="padding:6px 14px;font-size:13px;">Search</button>
        </form>
    </div>

    <div class="table-responsive">
        <table class="table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Candidate</th>
                    <th>Contact</th>
                    <th>Current Plan</th>
                    <th>Status</th>
                    <th>Expiry Date</th>
                    <th>Time Remaining</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php if (empty($subscriptions)): ?>
                    <tr>
                        <td colspan="8" style="text-align:center;padding:32px;color:var(--text-muted);">
                            No subscriptions found matching your query.
                        </td>
                    </tr>
                <?php else: ?>
                    <?php foreach ($subscriptions as $sub): ?>
                        <tr>
                            <td>#<?php echo $sub['id']; ?></td>
                            <td>
                                <strong><?php echo htmlspecialchars($sub['full_name']); ?></strong><br>
                                <small style="color:var(--text-muted);">User #<?php echo $sub['user_id']; ?></small>
                            </td>
                            <td>
                                <div style="font-size:12px;"><?php echo htmlspecialchars($sub['email']); ?></div>
                                <div style="font-size:11px;color:var(--text-muted);"><?php echo htmlspecialchars($sub['mobile'] ?? '—'); ?></div>
                            </td>
                            <td>
                                <span style="font-weight:600;"><?php echo htmlspecialchars($sub['plan_name'] ?? 'Custom Pro'); ?></span>
                            </td>
                            <td>
                                <?php
                                    $statusClass = 'badge-secondary';
                                    if ($sub['status'] === 'active') $statusClass = 'badge-success';
                                    elseif ($sub['status'] === 'trial') $statusClass = 'badge-primary';
                                    elseif ($sub['status'] === 'expiring') $statusClass = 'badge-warning';
                                    elseif ($sub['status'] === 'expired' || $sub['status'] === 'cancelled') $statusClass = 'badge-danger';
                                ?>
                                <span class="badge <?php echo $statusClass; ?>">
                                    <?php echo strtoupper($sub['status']); ?>
                                </span>
                            </td>
                            <td>
                                <?php echo date('d M Y, h:i A', strtotime($sub['expiry_date'])); ?>
                            </td>
                            <td>
                                <?php if ($sub['days_left'] > 0): ?>
                                    <span style="color:#15803d;font-weight:600;">⏳ <?php echo $sub['days_left']; ?> days</span>
                                <?php else: ?>
                                    <span style="color:#b91c1c;font-weight:600;">Expired</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <div style="display:flex;gap:6px;">
                                    <button class="btn btn-sm btn-outline" onclick="openExtendModal(<?php echo $sub['user_id']; ?>, '<?php echo htmlspecialchars($sub['full_name']); ?>', <?php echo $sub['plan_id'] ?? 1; ?>)">
                                        + Extend
                                    </button>
                                    <?php if ($sub['status'] !== 'cancelled'): ?>
                                        <form method="POST" style="margin:0;" onsubmit="return confirm('Are you sure you want to cancel this subscription?');">
                                            <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars(adminCsrfToken()); ?>">
                                            <input type="hidden" name="action" value="cancel_subscription">
                                            <input type="hidden" name="sub_id" value="<?php echo $sub['id']; ?>">
                                            <button type="submit" class="btn btn-sm btn-danger" style="padding:4px 8px;font-size:11px;">Cancel</button>
                                        </form>
                                    <?php endif; ?>
                                </div>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- CREATE PLAN MODAL -->
<div id="createPlanModal" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:9999;align-items:center;justify-content:center;">
    <div style="background:var(--card-bg, #ffffff);border-radius:14px;padding:24px;width:90%;max-width:480px;box-shadow:0 20px 25px -5px rgba(0,0,0,0.2);">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
            <h4 style="margin:0;font-weight:700;">➕ Create Subscription Tier Plan</h4>
            <button onclick="closeModal('createPlanModal')" style="background:none;border:none;font-size:18px;cursor:pointer;">✕</button>
        </div>
        <form method="POST">
            <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars(adminCsrfToken()); ?>">
            <input type="hidden" name="action" value="create_plan">

            <div class="form-group" style="margin-bottom:12px;">
                <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Plan Name</label>
                <input type="text" name="name" class="form-control" placeholder="e.g. Pro Half-Yearly Pass" required>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px;">
                <div class="form-group">
                    <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Duration (Days)</label>
                    <input type="number" name="duration_days" class="form-control" value="30" min="1" required>
                </div>
                <div class="form-group">
                    <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Price (₹)</label>
                    <input type="number" step="0.01" name="price" class="form-control" value="299.00" min="0" required>
                </div>
            </div>
            <div class="form-group" style="margin-bottom:14px;">
                <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Description / Features</label>
                <textarea name="description" class="form-control" rows="3" placeholder="Includes unlimited tests, AI analytics, video solutions..."></textarea>
            </div>
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:18px;">
                <input type="checkbox" id="is_active_check" name="is_active" value="1" checked>
                <label for="is_active_check" style="font-size:13px;font-weight:500;">Active immediately in marketplace</label>
            </div>

            <div style="display:flex;justify-content:flex-end;gap:10px;">
                <button type="button" class="btn btn-outline" onclick="closeModal('createPlanModal')">Cancel</button>
                <button type="submit" class="btn btn-primary">Save Plan</button>
            </div>
        </form>
    </div>
</div>

<!-- GRANT / EXTEND MODAL -->
<div id="grantSubModal" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:9999;align-items:center;justify-content:center;">
    <div style="background:var(--card-bg, #ffffff);border-radius:14px;padding:24px;width:90%;max-width:500px;box-shadow:0 20px 25px -5px rgba(0,0,0,0.2);">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
            <h4 style="margin:0;font-weight:700;" id="grantModalTitle">🌟 Grant / Extend Pro Membership</h4>
            <button onclick="closeModal('grantSubModal')" style="background:none;border:none;font-size:18px;cursor:pointer;">✕</button>
        </div>
        <form method="POST">
            <input type="hidden" name="csrf_token" value="<?php echo htmlspecialchars(adminCsrfToken()); ?>">
            <input type="hidden" name="action" value="grant_subscription">
            <input type="hidden" name="user_id" id="grantUserId" value="">

            <div class="form-group" id="candidateSelectGroup" style="margin-bottom:14px;">
                <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Select Candidate</label>
                <select id="userSelect" class="form-control" onchange="document.getElementById('grantUserId').value = this.value;">
                    <option value="">-- Choose Candidate --</option>
                    <?php foreach ($candidates as $c): ?>
                        <option value="<?php echo $c['id']; ?>">
                            <?php echo htmlspecialchars($c['full_name']); ?> (#<?php echo $c['id']; ?> - <?php echo htmlspecialchars($c['email']); ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div id="candidateNameDisplay" style="display:none;margin-bottom:14px;padding:10px;background:var(--surface-elevated, #f5f0e1);border-radius:8px;font-size:13px;font-weight:600;">
            </div>

            <div class="form-group" style="margin-bottom:14px;">
                <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Plan Tier</label>
                <select name="plan_id" id="grantPlanSelect" class="form-control">
                    <?php foreach ($plans as $p): ?>
                        <option value="<?php echo $p['id']; ?>" data-days="<?php echo $p['duration_days']; ?>">
                            <?php echo htmlspecialchars($p['name']); ?> (<?php echo $p['duration_days']; ?> Days - ₹<?php echo number_format($p['price'], 2); ?>)
                        </option>
                    <?php endforeach; ?>
                </select>
            </div>

            <div class="form-group" style="margin-bottom:14px;">
                <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Duration to Add</label>
                <div style="display:flex;gap:8px;margin-bottom:8px;">
                    <button type="button" class="btn btn-sm btn-outline" onclick="setGrantDays(7)">+7 Days</button>
                    <button type="button" class="btn btn-sm btn-outline" onclick="setGrantDays(30)">+30 Days</button>
                    <button type="button" class="btn btn-sm btn-outline" onclick="setGrantDays(90)">+90 Days</button>
                    <button type="button" class="btn btn-sm btn-outline" onclick="setGrantDays(365)">+365 Days</button>
                </div>
                <input type="number" id="grantDaysInput" name="days" class="form-control" value="30" min="1" required>
            </div>

            <div class="form-group" style="margin-bottom:18px;">
                <label style="font-size:12px;font-weight:600;display:block;margin-bottom:4px;">Entitlement Status</label>
                <select name="status" class="form-control">
                    <option value="active" selected>Active (Paid / Full Pro)</option>
                    <option value="trial">Trial (Promotional / Referral)</option>
                </select>
            </div>

            <div style="display:flex;justify-content:flex-end;gap:10px;">
                <button type="button" class="btn btn-outline" onclick="closeModal('grantSubModal')">Cancel</button>
                <button type="submit" class="btn btn-primary">Apply Extension</button>
            </div>
        </form>
    </div>
</div>

<script>
function openCreatePlanModal() {
    document.getElementById('createPlanModal').style.display = 'flex';
}
function openGrantModal() {
    document.getElementById('grantModalTitle').innerText = '🌟 Grant Membership Access';
    document.getElementById('candidateSelectGroup').style.display = 'block';
    document.getElementById('candidateNameDisplay').style.display = 'none';
    document.getElementById('grantUserId').value = document.getElementById('userSelect').value;
    document.getElementById('grantSubModal').style.display = 'flex';
}
function openExtendModal(userId, userName, planId) {
    document.getElementById('grantModalTitle').innerText = '🌟 Extend Subscription for ' + userName;
    document.getElementById('candidateSelectGroup').style.display = 'none';
    document.getElementById('candidateNameDisplay').style.display = 'block';
    document.getElementById('candidateNameDisplay').innerText = 'Extending for: ' + userName + ' (ID #' + userId + ')';
    document.getElementById('grantUserId').value = userId;
    if (planId) document.getElementById('grantPlanSelect').value = planId;
    document.getElementById('grantSubModal').style.display = 'flex';
}
function setGrantDays(days) {
    document.getElementById('grantDaysInput').value = days;
}
function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}
</script>
