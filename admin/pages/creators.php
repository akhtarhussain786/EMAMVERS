<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$filter = $_GET['filter'] ?? 'pending';
$validFilters = ['pending','approved','all','suspended'];
if (!in_array($filter, $validFilters)) $filter = 'pending';

$whereMap = [
    'pending'   => "c.verification_status='pending'",
    'approved'  => "c.verification_status='approved'",
    'suspended' => "c.verification_status='suspended'",
    'all'       => '1=1'
];

$creators = $db->query("
    SELECT c.*,
           u.full_name, u.email, u.mobile, u.status as user_status, u.created_at as user_joined,
           (SELECT COUNT(*) FROM study_materials WHERE creator_id=c.id AND status='approved') as approved_materials,
           (SELECT COUNT(*) FROM study_materials WHERE creator_id=c.id AND status='pending_review') as pending_materials,
           (SELECT COUNT(*) FROM material_purchases mp JOIN study_materials sm ON mp.material_id=sm.id WHERE sm.creator_id=c.id AND mp.payment_status='completed') as total_sales
    FROM creators c
    JOIN users u ON c.user_id=u.id
    WHERE {$whereMap[$filter]}
    ORDER BY c.created_at DESC
")->fetchAll(PDO::FETCH_ASSOC);

$counts = $db->query("
    SELECT
        SUM(verification_status='pending') as pending,
        SUM(verification_status='approved') as approved,
        SUM(verification_status='suspended') as suspended,
        COUNT(*) as total
    FROM creators
")->fetch(PDO::FETCH_ASSOC);

// Pending payouts
$payouts = $db->query("
    SELECT cp.*, c.display_name, u.email, c.upi_id
    FROM creator_payouts cp
    JOIN creators c ON cp.creator_id=c.id
    JOIN users u ON c.user_id=u.id
    WHERE cp.status='requested'
    ORDER BY cp.requested_at ASC
")->fetchAll(PDO::FETCH_ASSOC);
?>

<div class="creators-page">

    <!-- Summary Stats -->
    <div class="stats-row">
        <div class="stat-card stat-purple">
            <div class="stat-val"><?php echo $counts['total']; ?></div>
            <div class="stat-lbl">Total Creators</div>
        </div>
        <div class="stat-card stat-green">
            <div class="stat-val"><?php echo $counts['approved']; ?></div>
            <div class="stat-lbl">Active Creators</div>
        </div>
        <div class="stat-card stat-orange">
            <div class="stat-val"><?php echo $counts['pending']; ?></div>
            <div class="stat-lbl">Pending Approval</div>
        </div>
        <div class="stat-card stat-red">
            <div class="stat-val"><?php echo count($payouts); ?></div>
            <div class="stat-lbl">Payout Requests</div>
        </div>
    </div>

    <!-- Pending Payouts -->
    <?php if ($payouts): ?>
    <div class="section-card">
        <h3 class="section-card-title">💰 Pending Payout Requests</h3>
        <div class="table-wrap">
            <table class="admin-table">
                <thead><tr><th>Creator</th><th>UPI ID</th><th>Amount</th><th>Requested</th><th>Action</th></tr></thead>
                <tbody>
                <?php foreach ($payouts as $p): ?>
                <tr>
                    <td>
                        <div><?php echo htmlspecialchars($p['display_name']); ?></div>
                        <div class="sub-text"><?php echo htmlspecialchars($p['email']); ?></div>
                    </td>
                    <td><?php echo htmlspecialchars($p['upi_id'] ?: 'Not set'); ?></td>
                    <td class="price-tag">₹<?php echo number_format($p['amount_requested'],2); ?></td>
                    <td><?php echo date('d M Y', strtotime($p['requested_at'])); ?></td>
                    <td>
                        <button class="btn-xs btn-activate" onclick="processPayout(<?php echo $p['id']; ?>)">✓ Mark Paid</button>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
    <?php endif; ?>

    <!-- Filter Tabs -->
    <div class="filter-tabs">
        <?php foreach (['pending'=>'⏳ Pending ('.$counts['pending'].')', 'approved'=>'✓ Approved ('.$counts['approved'].')', 'suspended'=>'🚫 Suspended ('.$counts['suspended'].')', 'all'=>'All ('.$counts['total'].')'] as $val=>$label): ?>
        <a href="?page=creators&filter=<?php echo $val; ?>" class="filter-tab <?php echo $filter===$val?'active':''; ?>"><?php echo $label; ?></a>
        <?php endforeach; ?>
    </div>

    <!-- Creators Table -->
    <div class="table-card">
        <?php if (empty($creators)): ?>
        <div class="empty-state">No creator accounts found.</div>
        <?php else: ?>
        <div class="table-wrap">
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>Creator</th>
                        <th>Contact</th>
                        <th>Materials</th>
                        <th>Sales</th>
                        <th>Earnings</th>
                        <th>Pending Payout</th>
                        <th>Status</th>
                        <th>Joined</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($creators as $c): ?>
                <tr id="crow-<?php echo $c['id']; ?>">
                    <td>
                        <div class="creator-name"><?php echo htmlspecialchars($c['display_name']); ?></div>
                        <div class="sub-text"><?php echo htmlspecialchars($c['full_name']); ?></div>
                    </td>
                    <td>
                        <div><?php echo htmlspecialchars($c['email']); ?></div>
                        <div class="sub-text"><?php echo htmlspecialchars($c['mobile']); ?></div>
                    </td>
                    <td>
                        <span class="badge badge-success"><?php echo $c['approved_materials']; ?> live</span>
                        <?php if ($c['pending_materials'] > 0): ?>
                        <span class="badge badge-warning ml-4"><?php echo $c['pending_materials']; ?> pending</span>
                        <?php endif; ?>
                    </td>
                    <td><?php echo number_format($c['total_sales']); ?></td>
                    <td class="price-tag">₹<?php echo number_format($c['total_earnings'],0); ?></td>
                    <td>
                        <?php if ($c['pending_payout'] > 0): ?>
                        <span style="color:#fbbf24; font-weight:700;">₹<?php echo number_format($c['pending_payout'],0); ?></span>
                        <?php else: ?>—<?php endif; ?>
                    </td>
                    <td>
                        <span class="badge badge-<?php
                            echo match($c['verification_status']){
                                'approved'=>'success',
                                'suspended'=>'danger',
                                'pending'=>'warning',
                                default=>'neutral'
                            };
                        ?>"><?php echo ucfirst($c['verification_status']); ?></span>
                    </td>
                    <td><?php echo date('d M Y', strtotime($c['created_at'])); ?></td>
                    <td>
                        <div class="actions-cell">
                            <?php if ($c['verification_status'] === 'pending'): ?>
                            <button class="btn-xs btn-activate" onclick="approveCreator(<?php echo $c['id']; ?>)">✓ Approve</button>
                            <button class="btn-xs btn-danger-xs" onclick="suspendCreator(<?php echo $c['id']; ?>)">Reject</button>
                            <?php elseif ($c['verification_status'] === 'approved'): ?>
                            <button class="btn-xs btn-danger-xs" onclick="suspendCreator(<?php echo $c['id']; ?>)">Suspend</button>
                            <?php else: ?>
                            <button class="btn-xs btn-activate" onclick="approveCreator(<?php echo $c['id']; ?>)">Restore</button>
                            <?php endif; ?>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
        <?php endif; ?>
    </div>
</div>

<style>
.creators-page { display:flex; flex-direction:column; gap:20px; }
.stats-row { display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr)); gap:14px; }
.stat-card { padding:18px; border-radius:14px; text-align:center; }
.stat-purple { background:linear-gradient(135deg,rgba(99,102,241,.2),rgba(168,85,247,.1)); border:1px solid rgba(99,102,241,.3); }
.stat-green  { background:linear-gradient(135deg,rgba(21,128,61,.15),rgba(16,185,129,.1)); border:1px solid rgba(21,128,61,.25); }
.stat-orange { background:linear-gradient(135deg,rgba(249,115,22,.15),rgba(251,191,36,.1)); border:1px solid rgba(249,115,22,.25); }
.stat-red    { background:linear-gradient(135deg,rgba(239,68,68,.15),rgba(239,68,68,.05)); border:1px solid rgba(239,68,68,.2); }
.stat-val { font-size:24px; font-weight:800; margin-bottom:4px; }
.stat-lbl { font-size:11px; color:rgba(255,255,255,.5); text-transform:uppercase; letter-spacing:.5px; }
.section-card { background:rgba(255,255,255,.03); border:1px solid rgba(99,102,241,.25); border-radius:14px; padding:20px; }
.section-card-title { font-size:15px; font-weight:700; margin:0 0 16px; }
.filter-tabs { display:flex; gap:8px; flex-wrap:wrap; }
.filter-tab { padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600; color:rgba(255,255,255,.5); text-decoration:none; background:rgba(255,255,255,.05); border:1px solid rgba(255,255,255,.07); transition:all .2s; }
.filter-tab.active,.filter-tab:hover { background:rgba(99,102,241,.2); color:var(--accent-blue); border-color:rgba(99,102,241,.4); }
.table-card { background:rgba(255,255,255,.03); border:1px solid rgba(255,255,255,.07); border-radius:14px; overflow:hidden; }
.table-wrap { overflow-x:auto; }
.admin-table { width:100%; border-collapse:collapse; font-size:13px; }
.admin-table th { padding:12px; text-align:left; font-size:10px; font-weight:700; color:rgba(255,255,255,.35); text-transform:uppercase; background:rgba(255,255,255,.03); border-bottom:1px solid rgba(255,255,255,.06); }
.admin-table td { padding:12px; border-bottom:1px solid rgba(255,255,255,.04); color:rgba(255,255,255,.8); vertical-align:top; }
.creator-name { font-weight:700; font-size:14px; }
.sub-text { font-size:11px; color:rgba(255,255,255,.4); margin-top:2px; }
.price-tag { color:#4ade80; font-weight:700; }
.actions-cell { display:flex; gap:6px; flex-wrap:wrap; }
.badge { padding:3px 8px; border-radius:5px; font-size:11px; font-weight:600; }
.badge-success { background:rgba(21,128,61,.15); color:#4ade80; }
.badge-warning { background:rgba(251,191,36,.15); color:#fbbf24; }
.badge-danger  { background:rgba(239,68,68,.12); color:#f87171; }
.badge-neutral { background:rgba(255,255,255,.08); color:rgba(255,255,255,.5); }
.btn-xs { padding:5px 12px; border-radius:6px; font-size:11px; font-weight:600; cursor:pointer; border:none; }
.btn-activate { background:rgba(21,128,61,.15); color:#4ade80; }
.btn-activate:hover { background:rgba(21,128,61,.25); }
.btn-danger-xs { background:rgba(239,68,68,.1); color:#f87171; }
.btn-danger-xs:hover { background:rgba(239,68,68,.2); }
.empty-state { padding:40px; text-align:center; color:rgba(255,255,255,.3); }
.ml-4 { margin-left:4px; }
</style>

<script>
const AJAX = '/EXAMVERSE/admin/ajax/admin_actions.php';

async function approveCreator(id) {
    const res  = await fetch(`${AJAX}?action=approve_creator&id=${id}`);
    const data = await res.json();
    if (data.status === 'success') { showToast(data.message, 'success'); setTimeout(() => location.reload(), 800); }
    else showToast(data.message || 'Failed', 'error');
}

async function suspendCreator(id) {
    if (!confirm('Suspend/reject this creator? They will lose upload access.')) return;
    const res  = await fetch(`${AJAX}?action=suspend_creator&id=${id}`);
    const data = await res.json();
    if (data.status === 'success') { showToast(data.message, 'success'); setTimeout(() => location.reload(), 800); }
    else showToast(data.message || 'Failed', 'error');
}

async function processPayout(id) {
    const txn = prompt('Enter transaction reference / UTR number (optional):') || 'MANUAL_' + Date.now();
    const res  = await fetch(`${AJAX}?action=process_payout&id=${id}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ transaction_reference: txn })
    });
    const data = await res.json();
    if (data.status === 'success') { showToast('✓ Payout marked as paid!', 'success'); setTimeout(() => location.reload(), 800); }
    else showToast(data.message || 'Failed', 'error');
}

function showToast(msg, type = 'success') {
    const existing = document.getElementById('ev-toast');
    if (existing) existing.remove();
    const t = document.createElement('div');
    t.id = 'ev-toast';
    t.textContent = msg;
    Object.assign(t.style, {
        position:'fixed', bottom:'28px', right:'28px', zIndex:'9999',
        background: type==='success' ? 'rgba(21,128,61,0.95)' : 'rgba(239,68,68,0.95)',
        color:'white', padding:'14px 22px', borderRadius:'12px',
        fontWeight:'600', fontSize:'14px', maxWidth:'380px',
        boxShadow:'0 8px 32px rgba(0,0,0,0.4)'
    });
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 4000);
}
</script>
