<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$statusFilter = $_GET['status'] ?? 'pending_review';
$validStatuses = ['pending_review','approved','rejected','all'];
if (!in_array($statusFilter, $validStatuses)) $statusFilter = 'pending_review';

$whereClause = $statusFilter === 'all' ? '' : "WHERE sm.status='$statusFilter'";

$materials = $db->query("
    SELECT sm.id, sm.title, sm.price, sm.is_free, sm.status, sm.created_at, sm.file_size_kb,
           sm.total_downloads, sm.total_revenue, sm.total_pages, sm.language,
           sm.rejection_reason, sm.tags,
           c.display_name as creator_name, c.id as creator_id,
           u.email as creator_email,
           e.title as exam_title, s.name as subject_name
    FROM study_materials sm
    JOIN creators c ON sm.creator_id=c.id
    JOIN users u ON c.user_id=u.id
    LEFT JOIN exams e ON sm.exam_id=e.id
    LEFT JOIN subjects s ON sm.subject_id=s.id
    $whereClause
    ORDER BY sm.created_at DESC
")->fetchAll(PDO::FETCH_ASSOC);

// Platform stats
$stats = $db->query("
    SELECT
        COUNT(DISTINCT mp.id) as total_sales,
        COALESCE(SUM(mp.amount_paid),0) as total_revenue,
        COALESCE(SUM(mp.platform_fee),0) as platform_earnings,
        COALESCE(SUM(mp.creator_earning),0) as creator_payouts
    FROM material_purchases mp WHERE mp.payment_status='completed'
")->fetch(PDO::FETCH_ASSOC);

$counts = $db->query("
    SELECT
        SUM(status='pending_review') as pending,
        SUM(status='approved') as approved,
        SUM(status='rejected') as rejected,
        COUNT(*) as total
    FROM study_materials
")->fetch(PDO::FETCH_ASSOC);
?>

<div class="mkt-page">

    <!-- Stats Row -->
    <div class="stats-row">
        <div class="stat-card stat-purple">
            <div class="stat-val">₹<?php echo number_format($stats['total_revenue'],0); ?></div>
            <div class="stat-lbl">Total GMV</div>
        </div>
        <div class="stat-card stat-green">
            <div class="stat-val">₹<?php echo number_format($stats['platform_earnings'],0); ?></div>
            <div class="stat-lbl">Platform Revenue (20%)</div>
        </div>
        <div class="stat-card stat-blue">
            <div class="stat-val">₹<?php echo number_format($stats['creator_payouts'],0); ?></div>
            <div class="stat-lbl">Creator Earnings (80%)</div>
        </div>
        <div class="stat-card stat-orange">
            <div class="stat-val"><?php echo number_format($stats['total_sales']); ?></div>
            <div class="stat-lbl">Total Sales</div>
        </div>
        <div class="stat-card stat-red">
            <div class="stat-val"><?php echo $counts['pending'] ?? 0; ?></div>
            <div class="stat-lbl">Pending Review</div>
        </div>
    </div>

    <!-- Filter Tabs -->
    <div class="filter-tabs">
        <?php foreach (['pending_review'=>'⏳ Pending ('.$counts['pending'].')', 'approved'=>'✓ Approved ('.$counts['approved'].')', 'rejected'=>'✗ Rejected ('.$counts['rejected'].')', 'all'=>'All ('.$counts['total'].')'] as $val=>$label): ?>
        <a href="?page=marketplace&status=<?php echo $val; ?>" class="filter-tab <?php echo $statusFilter===$val?'active':''; ?>"><?php echo $label; ?></a>
        <?php endforeach; ?>
    </div>

    <!-- Materials Table -->
    <div class="table-card">
        <?php if (empty($materials)): ?>
        <div class="empty-state">No materials found in this category.</div>
        <?php else: ?>
        <div class="table-wrap">
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Title</th>
                        <th>Creator</th>
                        <th>Exam / Subject</th>
                        <th>Price</th>
                        <th>Size</th>
                        <th>Status</th>
                        <th>Submitted</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach ($materials as $m): ?>
                <tr id="row-<?php echo $m['id']; ?>">
                    <td><?php echo $m['id']; ?></td>
                    <td>
                        <div class="mat-title"><?php echo htmlspecialchars($m['title']); ?></div>
                        <?php if ($m['tags']): ?>
                        <div class="mat-tags"><?php echo htmlspecialchars($m['tags']); ?></div>
                        <?php endif; ?>
                    </td>
                    <td>
                        <div class="creator-info">
                            <div class="creator-name"><?php echo htmlspecialchars($m['creator_name']); ?></div>
                            <div class="creator-email"><?php echo htmlspecialchars($m['creator_email']); ?></div>
                        </div>
                    </td>
                    <td>
                        <div><?php echo htmlspecialchars($m['exam_title'] ?? '—'); ?></div>
                        <div class="sub-text"><?php echo htmlspecialchars($m['subject_name'] ?? '—'); ?></div>
                    </td>
                    <td>
                        <?php if ($m['is_free']): ?>
                        <span class="badge badge-success">FREE</span>
                        <?php else: ?>
                        <span class="price-tag">₹<?php echo number_format($m['price'],0); ?></span>
                        <?php endif; ?>
                    </td>
                    <td><?php echo $m['file_size_kb'] < 1024 ? $m['file_size_kb'].'KB' : round($m['file_size_kb']/1024,1).'MB'; ?></td>
                    <td>
                        <span class="badge badge-<?php
                            echo match($m['status']){
                                'approved'=>'success',
                                'rejected'=>'danger',
                                'pending_review'=>'warning',
                                default=>'neutral'
                            };
                        ?>"><?php echo str_replace('_',' ',ucfirst($m['status'])); ?></span>
                    </td>
                    <td><?php echo date('d M Y', strtotime($m['created_at'])); ?></td>
                    <td>
                        <div class="actions-cell">
                            <?php if ($m['status'] === 'pending_review'): ?>
                            <button class="btn-xs btn-activate" onclick="approveMaterial(<?php echo $m['id']; ?>)">✓ Approve</button>
                            <button class="btn-xs btn-danger-xs" onclick="showRejectModal(<?php echo $m['id']; ?>)">✗ Reject</button>
                            <?php elseif ($m['status'] === 'approved'): ?>
                            <button class="btn-xs btn-danger-xs" onclick="showRejectModal(<?php echo $m['id']; ?>)">Revoke</button>
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

<!-- Reject Modal -->
<div id="rejectModal" class="modal-overlay hidden">
    <div class="modal-box">
        <h3 class="modal-title">Reject Material</h3>
        <input type="hidden" id="rejectId">
        <label class="modal-label">Reason for rejection</label>
        <textarea id="rejectReason" class="modal-textarea" placeholder="e.g. Content quality is too low, incorrect information..."></textarea>
        <div class="modal-actions">
            <button class="btn-xs" onclick="hideRejectModal()" style="background:rgba(255,255,255,0.08);color:white">Cancel</button>
            <button class="btn-xs btn-danger-xs" onclick="confirmReject()">Confirm Reject</button>
        </div>
    </div>
</div>

<style>
.mkt-page { display:flex; flex-direction:column; gap:20px; }
.stats-row { display:grid; grid-template-columns:repeat(auto-fit,minmax(150px,1fr)); gap:14px; }
.stat-card { padding:18px; border-radius:14px; text-align:center; background:#ffffff; box-shadow:0 1px 3px rgba(0,0,0,0.05); }
.stat-purple { background:#faf5ff; border:1.5px solid #e9d5ff; }
.stat-green  { background:#f0fdf4; border:1.5px solid #bbf7d0; }
.stat-blue   { background:#eff6ff; border:1.5px solid #bfdbfe; }
.stat-orange { background:#fff7ed; border:1.5px solid #fed7aa; }
.stat-red    { background:#fef2f2; border:1.5px solid #fecaca; }
.stat-val { font-size:24px; font-weight:800; color:#0f172a; margin-bottom:4px; }
.stat-lbl { font-size:11px; color:#475569; font-weight:700; text-transform:uppercase; letter-spacing:.5px; }
.filter-tabs { display:flex; gap:8px; flex-wrap:wrap; }
.filter-tab { padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600; color:#475569; text-decoration:none; background:#ffffff; border:1.5px solid #cbd5e1; transition:all .2s; }
.filter-tab.active,.filter-tab:hover { background:#e0e7ff; color:#4338ca; border-color:#818cf8; }
.table-card { background:#ffffff; border:1px solid #e2e8f0; border-radius:14px; overflow:hidden; box-shadow:0 1px 3px rgba(0,0,0,0.05); }
.table-wrap { overflow-x:auto; }
.admin-table { width:100%; border-collapse:collapse; font-size:13px; }
.admin-table th { padding:12px; text-align:left; font-size:11px; font-weight:700; color:#475569; text-transform:uppercase; background:#f8fafc; border-bottom:2px solid #e2e8f0; letter-spacing:0.5px; }
.admin-table td { padding:12px; border-bottom:1px solid #f1f5f9; color:#1e293b; font-weight:500; vertical-align:top; }
.mat-title { font-weight:600; color:#0f172a; }
.mat-tags { font-size:11px; color:#64748b; margin-top:3px; }
.creator-name { font-weight:600; font-size:13px; color:#0f172a; }
.creator-email { font-size:11px; color:#64748b; }
.sub-text { font-size:11px; color:#64748b; margin-top:2px; }
.price-tag { font-weight:700; color:#15803d; font-size:14px; }
.actions-cell { display:flex; gap:6px; align-items:center; }
.badge { padding:4px 9px; border-radius:6px; font-size:11px; font-weight:600; }
.badge-success { background:#dcfce7; color:#15803d; border:1px solid #bbf7d0; }
.badge-warning { background:#fef3c7; color:#b45309; border:1px solid #fde68a; }
.badge-danger  { background:#fee2e2; color:#b91c1c; border:1px solid #fecaca; }
.badge-neutral { background:#f1f5f9; color:#475569; border:1px solid #e2e8f0; }
.btn-xs { padding:5px 12px; border-radius:6px; font-size:11px; font-weight:600; cursor:pointer; border:none; }
.btn-activate { background:#dcfce7; color:#15803d; border:1px solid #bbf7d0; }
.btn-activate:hover { background:#bbf7d0; }
.btn-danger-xs { background:#fee2e2; color:#b91c1c; border:1px solid #fecaca; }
.btn-danger-xs:hover { background:#fecaca; }
.empty-state { padding:40px; text-align:center; color:#64748b; font-size:14px; }
/* Modal */
.modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,.6); z-index:1000; display:flex; align-items:center; justify-content:center; backdrop-filter:blur(4px); }
.modal-box { background:#ffffff; border:1px solid #e2e8f0; border-radius:16px; padding:28px; width:400px; max-width:90vw; box-shadow:0 10px 25px rgba(0,0,0,0.15); }
.modal-title { font-size:18px; font-weight:700; color:#0f172a; margin:0 0 18px; }
.modal-label { display:block; font-size:12px; font-weight:600; color:#334155; margin-bottom:6px; text-transform:uppercase; }
.modal-textarea { width:100%; background:#ffffff; border:1.5px solid #cbd5e1; border-radius:8px; padding:10px 12px; color:#0f172a; font-size:13px; height:90px; resize:vertical; box-sizing:border-box; }
.modal-textarea:focus { outline:none; border-color:#4f46e5; }
.modal-actions { display:flex; gap:10px; justify-content:flex-end; margin-top:16px; }
.hidden { display:none!important; }
</style>

<script>
const AJAX = '/EXAMVERSE/admin/ajax/admin_actions.php';

async function approveMaterial(id) {
    const res  = await fetch(`${AJAX}?action=approve_material&id=${id}`);
    const data = await res.json();
    if (data.status === 'success') {
        document.getElementById('row-'+id).style.opacity = '0.4';
        showToast(data.message, 'success');
        setTimeout(() => location.reload(), 800);
    } else {
        showToast(data.message || 'Failed to approve', 'error');
    }
}

function showRejectModal(id) {
    document.getElementById('rejectId').value = id;
    document.getElementById('rejectModal').classList.remove('hidden');
}
function hideRejectModal() { document.getElementById('rejectModal').classList.add('hidden'); }

async function confirmReject() {
    const id     = document.getElementById('rejectId').value;
    const reason = document.getElementById('rejectReason').value.trim() || 'Does not meet quality standards';
    const res    = await fetch(`${AJAX}?action=reject_material&id=${id}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ reason })
    });
    const data = await res.json();
    if (data.status === 'success') {
        hideRejectModal();
        showToast(data.message, 'success');
        setTimeout(() => location.reload(), 800);
    } else {
        showToast(data.message || 'Failed', 'error');
    }
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
