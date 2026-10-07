<?php
$adminUser = isset($currentAdmin) ? $currentAdmin : ($_SESSION['admin_user'] ?? [
    'full_name' => 'Admin User',
    'email' => 'admin@examverse.com',
    'role' => 'Super Admin'
]);
$initial = strtoupper(substr($adminUser['full_name'] ?? 'A', 0, 1));
?>
<header class="top-bar">
    <div style="display:flex; align-items:center; gap:16px;">
        <button class="icon-button" id="toggle-sidebar-btn" style="border:none;">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:20px;height:20px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
        </button>
        <div class="search-box">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:16px;height:16px;color:#94a3b8;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
            <input type="text" placeholder="Search users, tests, questions, teachers...">
            <span class="search-shortcut">Ctrl + K</span>
        </div>
    </div>

    <div class="header-actions">
        <button class="btn-quick-action" onclick="alert('Quick Actions: Create Test, Add Question, Grant Pro, Review KYC');">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:16px;height:16px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/></svg>
            Quick Action
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:12px;height:12px;margin-left:2px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        </button>

        <button class="icon-button" title="Notifications">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
            <span class="icon-badge">12</span>
        </button>

        <button class="icon-button" title="Help & Docs">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        </button>

        <div class="user-profile" onclick="if(confirm('Log out from Admin Panel?')) window.location.href='login.php?action=logout';">
            <div class="avatar" style="background:#dbeafe;color:#1d4ed8;display:flex;align-items:center;justify-content:center;font-weight:700;">
                <?php echo $initial; ?>
            </div>
            <div style="font-size:0.85rem;">
                <div style="font-weight:700;color:var(--text-primary);"><?php echo htmlspecialchars($adminUser['full_name']); ?></div>
                <div style="color:var(--text-muted);font-size:0.75rem;"><?php echo htmlspecialchars($adminUser['role'] ?? 'Super Admin'); ?></div>
            </div>
        </div>
    </div>
</header>

<script>
/*
 * CSRF token for admin AJAX.
 *
 * admin/ajax/_guard.php rejects any non-read-only action without a token, but
 * several pages (AI generator, creators, marketplace, question bank, question
 * review) called those endpoints with no token at all, so every button on them
 * answered 403. Rather than thread the token through two dozen call sites, the
 * header is attached here to requests aimed at admin/ajax/ — and only those,
 * so calls to the public API or to third parties are left untouched.
 */
window.ADMIN_CSRF_TOKEN = '<?php echo htmlspecialchars(adminCsrfToken(), ENT_QUOTES); ?>';
(function () {
    const nativeFetch = window.fetch.bind(window);
    const isAdminAjax = (url) => {
        try {
            return new URL(url, window.location.href).pathname.includes('/admin/ajax/');
        } catch (e) {
            return false;
        }
    };

    window.fetch = function (resource, init) {
        const url = (typeof resource === 'string') ? resource
                  : (resource && resource.url) ? resource.url : '';
        if (!isAdminAjax(url)) {
            return nativeFetch(resource, init);
        }
        const options = Object.assign({}, init || {});
        const headers = new Headers(options.headers || {});
        if (!headers.has('X-CSRF-Token')) {
            headers.set('X-CSRF-Token', window.ADMIN_CSRF_TOKEN);
        }
        options.headers = headers;
        return nativeFetch(resource, options);
    };
})();
</script>
