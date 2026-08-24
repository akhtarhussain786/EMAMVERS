<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$audits = $db->query("
    SELECT al.*, a.username, a.full_name 
    FROM admin_audit_logs al 
    JOIN admins a ON al.admin_id = a.id 
    ORDER BY al.id DESC LIMIT 50
")->fetchAll();
?>

<div class="table-card">
    <div class="table-header">
        <div class="table-title">System Audit & Administrative Activity Trail</div>
    </div>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Admin User</th>
                <th>Action</th>
                <th>Entity Type</th>
                <th>Details</th>
                <th>Timestamp</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($audits as $audit): ?>
                <tr>
                    <td>#AUD-<?php echo $audit['id']; ?></td>
                    <td style="font-weight:600;"><?php echo htmlspecialchars($audit['full_name']); ?> (<?php echo htmlspecialchars($audit['username']); ?>)</td>
                    <td><span class="badge badge-info"><?php echo htmlspecialchars($audit['action']); ?></span></td>
                    <td><?php echo htmlspecialchars($audit['entity_type']); ?></td>
                    <td><?php echo htmlspecialchars($audit['details']); ?></td>
                    <td style="color:var(--text-muted); font-size:0.8rem;"><?php echo $audit['created_at']; ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
