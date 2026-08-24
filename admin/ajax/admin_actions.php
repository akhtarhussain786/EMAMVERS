<?php
/**
 * Admin AJAX: Marketplace & Creator Management
 * URL: /EXAMVERSE/admin/ajax/admin_actions.php?action=...
 * Auth: PHP Session
 */
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';

$db     = Database::getConnection();
$action = $_GET['action'] ?? '';

switch ($action) {

    // ── APPROVE MATERIAL ───────────────────────────────────────────────
    case 'approve_material':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('id required', 422);
        $db->prepare("UPDATE study_materials SET status='approved' WHERE id=?")->execute([$id]);
        ajaxOk(null, 'Material approved and now live on Marketplace!');
        break;

    // ── REJECT MATERIAL ────────────────────────────────────────────────
    case 'reject_material':
        $id     = intval($_GET['id'] ?? 0);
        $body   = getBody();
        $reason = trim($body['reason'] ?? 'Does not meet quality standards');
        if (!$id) ajaxErr('id required', 422);
        $db->prepare("UPDATE study_materials SET status='rejected', rejection_reason=? WHERE id=?")->execute([$reason, $id]);
        ajaxOk(null, 'Material rejected');
        break;

    // ── APPROVE CREATOR ────────────────────────────────────────────────
    case 'approve_creator':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('id required', 422);
        $db->prepare("UPDATE creators SET verification_status='approved', verified_at=NOW() WHERE id=?")->execute([$id]);
        ajaxOk(null, 'Creator approved! They can now upload study materials.');
        break;

    // ── SUSPEND CREATOR ────────────────────────────────────────────────
    case 'suspend_creator':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('id required', 422);
        $db->prepare("UPDATE creators SET verification_status='suspended' WHERE id=?")->execute([$id]);
        ajaxOk(null, 'Creator suspended');
        break;

    // ── PROCESS PAYOUT ─────────────────────────────────────────────────
    case 'process_payout':
        $id   = intval($_GET['id'] ?? 0);
        $body = getBody();
        $txn  = trim($body['transaction_reference'] ?? 'MANUAL_' . date('YmdHis'));
        if (!$id) ajaxErr('id required', 422);

        $pStmt = $db->prepare("SELECT * FROM creator_payouts WHERE id=?");
        $pStmt->execute([$id]);
        $payout = $pStmt->fetch(PDO::FETCH_ASSOC);
        if (!$payout) ajaxErr('Payout not found', 404);

        $db->prepare("UPDATE creator_payouts SET status='completed', amount_paid=amount_requested, transaction_reference=?, processed_at=NOW() WHERE id=?")->execute([$txn, $id]);
        $db->prepare("UPDATE creators SET pending_payout=pending_payout-?, paid_out=paid_out+? WHERE id=?")->execute([$payout['amount_requested'], $payout['amount_requested'], $payout['creator_id']]);

        ajaxOk(['transaction_reference' => $txn], 'Payout marked as paid! ✓');
        break;

    // ── MARKETPLACE STATS ──────────────────────────────────────────────
    case 'marketplace_stats':
        $stats = $db->query("SELECT
            COUNT(DISTINCT mp.id) as total_sales,
            COALESCE(SUM(mp.amount_paid),0) as total_revenue,
            COALESCE(SUM(mp.platform_fee),0) as platform_earnings,
            COALESCE(SUM(mp.creator_earning),0) as creator_payouts
            FROM material_purchases mp WHERE mp.payment_status='completed'"
        )->fetch(PDO::FETCH_ASSOC);
        ajaxOk($stats, 'Stats fetched');
        break;

    default:
        ajaxErr("Unknown action: $action", 400);
}
