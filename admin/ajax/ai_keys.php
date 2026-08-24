<?php
/**
 * Admin AJAX: AI API Key Management
 * URL: /EXAMVERSE/admin/ajax/ai_keys.php?action=list|save|delete|toggle
 * Auth: PHP Session (admin panel login required)
 */
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';

$db  = Database::getConnection();
$action = $_GET['action'] ?? 'list';

switch ($action) {

    // ── LIST KEYS ──────────────────────────────────────────────────────
    case 'list':
        $stmt = $db->query(
            "SELECT id, label, provider, is_active, usage_count, last_used_at, created_at,
             CONCAT(SUBSTR(api_key_encrypted,1,8),'••••••••••••••',SUBSTR(api_key_encrypted,-4)) AS masked_key
             FROM ai_api_keys ORDER BY created_at DESC"
        );
        ajaxOk($stmt->fetchAll(PDO::FETCH_ASSOC), 'Keys fetched');
        break;

    // ── SAVE NEW KEY ───────────────────────────────────────────────────
    case 'save':
        $body     = getBody();
        $label    = trim($body['label'] ?? '');
        $provider = $body['provider'] ?? 'gemini';
        $apiKey   = trim($body['api_key'] ?? '');

        if (!$label)   ajaxErr('label is required', 422);
        if (!$apiKey)  ajaxErr('api_key is required', 422);
        if (!in_array($provider, ['gemini','openai'])) ajaxErr('provider must be gemini or openai', 422);

        // Deactivate existing keys for this provider
        $db->prepare("UPDATE ai_api_keys SET is_active=0 WHERE provider=?")->execute([$provider]);

        $encrypted = base64_encode($apiKey);
        $stmt = $db->prepare(
            "INSERT INTO ai_api_keys (label, provider, api_key_encrypted, is_active, created_by)
             VALUES (?,?,?,1,?)"
        );
        $admin = $_SESSION['admin_user']['username'] ?? 'admin';
        $stmt->execute([$label, $provider, $encrypted, $admin]);

        ajaxOk(['id' => $db->lastInsertId()], "✓ $provider API key saved and activated!", 201);
        break;

    // ── DELETE KEY ─────────────────────────────────────────────────────
    case 'delete':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('id required', 422);
        $db->prepare("DELETE FROM ai_api_keys WHERE id=?")->execute([$id]);
        ajaxOk(null, 'Key deleted');
        break;

    // ── TOGGLE ACTIVE ──────────────────────────────────────────────────
    case 'toggle':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('id required', 422);
        $stmt = $db->prepare("SELECT is_active, provider FROM ai_api_keys WHERE id=?");
        $stmt->execute([$id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) ajaxErr('Key not found', 404);

        $new = $row['is_active'] ? 0 : 1;
        // If activating, deactivate others of same provider first
        if ($new === 1) {
            $db->prepare("UPDATE ai_api_keys SET is_active=0 WHERE provider=?")->execute([$row['provider']]);
        }
        $db->prepare("UPDATE ai_api_keys SET is_active=? WHERE id=?")->execute([$new, $id]);
        ajaxOk(['is_active' => $new], $new ? '✓ Key activated' : 'Key deactivated');
        break;

    default:
        ajaxErr("Unknown action: $action", 400);
}
