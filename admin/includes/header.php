<?php
$adminUser = isset($currentAdmin) ? $currentAdmin : ($_SESSION['admin_user'] ?? [
    'full_name' => 'Super Administrator',
    'email' => 'admin@examverse.com',
    'role' => 'super_admin'
]);
$initial = strtoupper(substr($adminUser['full_name'] ?? 'A', 0, 1));
?>
<header class="top-bar">
    <div class="page-title">
        <?php echo isset($title) ? htmlspecialchars($title) : 'Admin Dashboard'; ?>
    </div>
    <div style="display:flex; align-items:center; gap:1.5rem;">
        <div class="user-profile">
            <div class="avatar"><?php echo $initial; ?></div>
            <div style="font-size:0.85rem;">
                <div style="font-weight:600;"><?php echo htmlspecialchars($adminUser['full_name']); ?></div>
                <div style="color:var(--text-muted); font-size:0.75rem;"><?php echo htmlspecialchars($adminUser['email']); ?></div>
            </div>
        </div>
        <a href="login.php?action=logout" class="btn" style="background:rgba(239, 68, 68, 0.15); color:var(--accent-danger); font-size:0.8rem; padding:0.4rem 0.8rem; border:1px solid rgba(239,68,68,0.3);">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:16px; height:16px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
            Log Out
        </a>
    </div>
</header>
