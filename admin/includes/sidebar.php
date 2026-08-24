<?php
$currentPage = isset($page) ? $page : 'dashboard';
?>
<aside class="sidebar" id="sidebar">
    <div class="brand">
        EXAM<span style="color:var(--accent)">VERSE</span>
        <span class="brand-badge">Admin</span>
    </div>
    <ul class="nav-menu">
        <li>
            <a href="index.php?page=dashboard" class="nav-link <?php echo $currentPage==='dashboard'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
                Dashboard
            </a>
        </li>

        <li class="nav-section-label">Content</li>

        <li>
            <a href="index.php?page=taxonomy" class="nav-link <?php echo $currentPage==='taxonomy'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
                Exam Taxonomy
            </a>
        </li>
        <li>
            <a href="index.php?page=patterns" class="nav-link <?php echo $currentPage==='patterns'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                Pattern Builder
            </a>
        </li>
        <li>
            <a href="index.php?page=questions" class="nav-link <?php echo $currentPage==='questions'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                Question Bank
            </a>
        </li>
        <li>
            <a href="index.php?page=tests" class="nav-link <?php echo $currentPage==='tests'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                Test Builder
            </a>
        </li>
        <li>
            <a href="index.php?page=challenges" class="nav-link <?php echo $currentPage==='challenges'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"/></svg>
                Monthly Challenges
            </a>
        </li>
        <li>
            <a href="index.php?page=cms" class="nav-link <?php echo $currentPage==='cms'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/></svg>
                Content CMS
            </a>
        </li>

        <li class="nav-section-label">AI & Creator</li>

        <li>
            <a href="index.php?page=ai_generator" class="nav-link <?php echo $currentPage==='ai_generator'?'active':'';?>" id="nav-ai-gen">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17H3a2 2 0 01-2-2V5a2 2 0 012-2h16a2 2 0 012 2v10a2 2 0 01-2 2h-2m-4-3h.01"/></svg>
                AI Question Generator
                <span class="nav-badge new">NEW</span>
            </a>
        </li>
        <li>
            <a href="index.php?page=marketplace" class="nav-link <?php echo $currentPage==='marketplace'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"/></svg>
                Study Marketplace
                <span class="nav-badge new">NEW</span>
            </a>
        </li>
        <li>
            <a href="index.php?page=creators" class="nav-link <?php echo $currentPage==='creators'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                Creators Hub
                <span class="nav-badge new">NEW</span>
            </a>
        </li>

        <li class="nav-section-label">System</li>

        <li>
            <a href="index.php?page=audits" class="nav-link <?php echo $currentPage==='audits'?'active':'';?>">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                Audit Logs
            </a>
        </li>
    </ul>

    <div class="sidebar-footer">
        <a href="login.php?logout=1" class="logout-btn">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
            Logout
        </a>
    </div>
</aside>

<style>
.nav-section-label {
    padding: 12px 20px 4px;
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 1px;
    text-transform: uppercase;
    color: rgba(255,255,255,0.3);
    list-style: none;
}
.nav-badge {
    display: inline-block;
    margin-left: auto;
    padding: 2px 6px;
    border-radius: 6px;
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.5px;
}
.nav-badge.new {
    background: linear-gradient(135deg, #6366f1, #a855f7);
    color: white;
}
.sidebar-footer {
    margin-top: auto;
    padding: 16px;
    border-top: 1px solid rgba(255,255,255,0.08);
}
.logout-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    color: rgba(255,255,255,0.5);
    text-decoration: none;
    padding: 8px 12px;
    border-radius: 8px;
    font-size: 13px;
    transition: all 0.2s;
}
.logout-btn:hover { color: #ef4444; background: rgba(239,68,68,0.1); }
.logout-btn svg { width: 16px; height: 16px; }
</style>
