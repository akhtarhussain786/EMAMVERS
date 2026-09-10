<?php
require_once __DIR__ . '/../utils/auth_token.php';
require_once __DIR__ . '/../utils/response.php';

class AuthMiddleware {
    /** Roles that are treated as staff for the 'admin' requirement. */
    /** Staff roles, matching the admins.role ENUM in schema.sql plus admin token alias. */
    private static $adminRoles = ['admin', 'super_admin', 'content_operator', 'reviewer', 'finance_operator'];

    /**
     * Requires a valid bearer token. Returns the normalised claim set
     * (see AuthToken::verify) or terminates with 401/403.
     */
    public static function getAuthenticatedUser($requiredType = null) {
        $token = AuthToken::tokenFromRequest();
        if (!$token) {
            $session = self::adminSessionClaims($requiredType);
            if ($session) return $session;
            Response::error('Unauthorized: Missing or malformed token', 401);
        }

        $payload = AuthToken::verify($token);
        if (!$payload) {
            $session = self::adminSessionClaims($requiredType);
            if ($session) return $session;
            Response::error('Unauthorized: Invalid or expired token', 401);
        }

        if ($requiredType !== null && !self::satisfies($payload['type'], $requiredType)) {
            Response::error('Forbidden: Insufficient privileges', 403);
        }

        return $payload;
    }

    /**
     * Claims derived from a live admin-panel session, for API calls made from
     * the panel itself (which authenticates by cookie, not bearer token).
     *
     * Returns null unless the session carries a real admin id and role — an
     * incomplete session must fail closed rather than default to super_admin.
     */
    private static function adminSessionClaims($requiredType) {
        if ($requiredType !== 'admin' || !self::hasAdminPanelSession()) return null;

        $user = $_SESSION['admin_user'] ?? [];
        $id   = isset($user['id']) ? (int)$user['id'] : 0;
        $role = $user['role'] ?? null;

        if ($id <= 0 || !in_array($role, self::$adminRoles, true)) {
            error_log('EXAMVERSE: admin session present but incomplete; refusing to authenticate.');
            return null;
        }

        return [
            'sub'     => $id,
            'id'      => $id,
            'user_id' => $id,
            'type'    => $role,
            'extra'   => $user,
            'payload' => $user,
        ];
    }

    /**
     * Returns the claim set when a valid token is present, or null when the
     * request is anonymous. Never falls back to an implicit user id.
     */
    public static function getOptionalUser() {
        $token = AuthToken::tokenFromRequest();
        if (!$token) return null;
        $payload = AuthToken::verify($token);
        return $payload ?: null;
    }

    /**
     * True when the caller holds a live admin-panel session cookie.
     * The session cookie is SameSite=Lax, so a cross-site POST cannot carry it.
     */
    public static function hasAdminPanelSession() {
        if (session_status() === PHP_SESSION_NONE) {
            if (empty($_COOKIE['EXAMVERSE_ADMIN'])) return false;
            session_name('EXAMVERSE_ADMIN');
            @session_start();
        }
        return !empty($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
    }

    /**
     * Requires either a signed-in user (bearer token) or an admin-panel
     * session. Returns ['is_admin' => bool, 'user_id' => int|null].
     */
    public static function requireUserOrAdminSession() {
        $user = self::getOptionalUser();
        if ($user) {
            return [
                'is_admin' => in_array($user['type'], self::$adminRoles, true),
                'user_id'  => $user['sub'],
            ];
        }
        if (self::hasAdminPanelSession()) {
            return ['is_admin' => true, 'user_id' => null];
        }
        Response::error('Unauthorized: Sign in to use this feature', 401);
    }

    private static function satisfies($actualType, $requiredType) {
        if ($requiredType === 'admin') {
            return in_array($actualType, self::$adminRoles, true);
        }
        // Staff tokens are not interchangeable with student tokens: a student
        // resource is scoped to a student account.
        return $actualType === $requiredType;
    }
}
