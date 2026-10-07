<?php
/**
 * Admin page guard — every file in admin/pages/ must require this first.
 *
 * Pages are normally reached through admin/index.php, which authenticates
 * before including them. They were also reachable directly
 * (admin/pages/users.php), and that path ran no authentication at all, so a
 * plain GET rendered the full page: candidate names, emails and mobile
 * numbers, teacher KYC records, audit logs and revenue figures.
 *
 * Enforcing the session here closes that path without depending on how the
 * page was reached. Requests that arrive through index.php are already logged
 * in and pass straight through.
 */
require_once __DIR__ . '/session.php';

adminSessionStart();

if (!adminIsLoggedIn()) {
    // A page fragment is not a document; send the browser to the login screen
    // and give anything else a bare 401 rather than a half-rendered panel.
    if (!headers_sent()) {
        http_response_code(401);
        header('Location: ../login.php');
    }
    exit;
}
