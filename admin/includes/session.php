<?php
/**
 * Shared admin session bootstrap: hardened cookie flags, idle timeout,
 * and CSRF token issue/verify helpers.
 *
 * Every admin page and AJAX entry point must include this before doing anything.
 */
require_once __DIR__ . '/../../api/config/config.php';

const ADMIN_IDLE_TIMEOUT = 3600; // seconds

function adminSessionStart(): void {
    if (session_status() !== PHP_SESSION_NONE) return;

    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
          || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');

    session_set_cookie_params([
        'lifetime' => 0,
        'path'     => '/',
        'httponly' => true,
        'secure'   => $https,
        'samesite' => 'Lax',
    ]);
    session_name('EXAMVERSE_ADMIN');
    session_start();

    // Expire idle sessions rather than leaving them valid for the cookie's life.
    if (isset($_SESSION['admin_last_seen']) && (time() - $_SESSION['admin_last_seen']) > ADMIN_IDLE_TIMEOUT) {
        $_SESSION = [];
        session_destroy();
        session_start();
    }
    $_SESSION['admin_last_seen'] = time();
}

function adminIsLoggedIn(): bool {
    return isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
}

/** Current CSRF token, generated on first use. */
function adminCsrfToken(): string {
    if (empty($_SESSION['admin_csrf'])) {
        $_SESSION['admin_csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['admin_csrf'];
}

function adminCsrfValid(?string $candidate): bool {
    return is_string($candidate)
        && !empty($_SESSION['admin_csrf'])
        && hash_equals($_SESSION['admin_csrf'], $candidate);
}

/** Reads the CSRF token from the request header or body. */
function adminCsrfFromRequest(array $body = []): ?string {
    foreach (['HTTP_X_CSRF_TOKEN', 'HTTP_X_XSRF_TOKEN'] as $header) {
        if (!empty($_SERVER[$header])) return $_SERVER[$header];
    }
    if (!empty($_POST['csrf_token'])) return $_POST['csrf_token'];
    if (!empty($body['csrf_token'])) return $body['csrf_token'];
    return null;
}
