<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

// Summary metrics
$counts = $db->query("
    SELECT
        COUNT(*) AS total_attributions,
        SUM(status = 'rewarded') AS total_rewarded,
        SUM(status = 'attributed') AS pending_qualification,
        (SELECT COUNT(DISTINCT user_id) FROM referral_codes) AS active_promoters,
        (SELECT SUM(reward_days) FROM referral_rewards WHERE status = 'issued') AS total_days_granted
    FROM referrals
")->fetch(PDO::FETCH_ASSOC);

// Top Referrers
$topReferrers = $db->query("
    SELECT u.id, u.full_name, u.email, rc.code,
           COUNT(r.id) AS referred_count,
           SUM(r.status = 'rewarded') AS qualified_count,
           COALESCE(SUM(rr.reward_days), 0) AS total_bonus_days
    FROM referral_codes rc
    JOIN users u ON rc.user_id = u.id
    LEFT JOIN referrals r ON rc.user_id = r.referrer_user_id
    LEFT JOIN referral_rewards rr ON r.id = rr.referral_id AND rr.beneficiary_user_id = u.id
    GROUP BY rc.user_id
    ORDER BY referred_count DESC, qualified_count DESC
    LIMIT 20
")->fetchAll(PDO::FETCH_ASSOC);

// Recent Referral Events
$recentEvents = $db->query("
    SELECT r.*,
           ur.full_name AS referrer_name, ur.email AS referrer_email,
           uf.full_name AS friend_name, uf.email AS friend_email
    FROM referrals r
    JOIN users ur ON r.referrer_user_id = ur.id
    JOIN users uf ON r.referred_user_id = uf.id
    ORDER BY r.created_at DESC
    LIMIT 30
")->fetchAll(PDO::FETCH_ASSOC);
?>

<div class="referrals-page">
    <div class="page-header mb-4">
        <div>
            <h1 class="h3 font-weight-bold">Referral & Growth Platform Dashboard</h1>
            <p class="text-muted">PRD §17: Single-tier referral campaigns, anti-fraud qualification tracking, and reward ledger analytics.</p>
        </div>
    </div>

    <!-- Stats Row -->
    <div class="stats-row mb-4">
        <div class="stat-card stat-purple">
            <div class="stat-val"><?php echo (int)($counts['total_attributions'] ?? 0); ?></div>
            <div class="stat-lbl">Total Attributions</div>
        </div>
        <div class="stat-card stat-green">
            <div class="stat-val"><?php echo (int)($counts['total_rewarded'] ?? 0); ?></div>
            <div class="stat-lbl">Qualified & Rewarded</div>
        </div>
        <div class="stat-card stat-orange">
            <div class="stat-val"><?php echo (int)($counts['active_promoters'] ?? 0); ?></div>
            <div class="stat-lbl">Active Referrers</div>
        </div>
        <div class="stat-card stat-red">
            <div class="stat-val"><?php echo (int)($counts['total_days_granted'] ?? 0); ?>d</div>
            <div class="stat-lbl">Premium Days Granted</div>
        </div>
    </div>

    <div class="row">
        <!-- Top Promoters -->
        <div class="col-md-5">
            <div class="card shadow-sm border-0 mb-4">
                <div class="card-header bg-white py-3 border-bottom">
                    <h5 class="mb-0 font-weight-bold">🏆 Top Student Promoters</h5>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead class="thead-light">
                                <tr>
                                    <th>Promoter</th>
                                    <th>Code</th>
                                    <th>Invites</th>
                                    <th>Days</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (empty($topReferrers)): ?>
                                <tr><td colspan="4" class="text-center p-3 text-muted">No referrers active yet</td></tr>
                                <?php else: ?>
                                    <?php foreach ($topReferrers as $top): ?>
                                    <tr>
                                        <td>
                                            <div class="font-weight-bold"><?php echo htmlspecialchars($top['full_name']); ?></div>
                                            <small class="text-muted"><?php echo htmlspecialchars($top['email']); ?></small>
                                        </td>
                                        <td><code><?php echo htmlspecialchars($top['code']); ?></code></td>
                                        <td>
                                            <span class="badge badge-primary"><?php echo $top['referred_count']; ?></span>
                                            <small class="text-success">(<?php echo $top['qualified_count']; ?> ✓)</small>
                                        </td>
                                        <td>
                                            <span class="badge badge-success">+<?php echo $top['total_bonus_days']; ?>d</span>
                                        </td>
                                    </tr>
                                    <?php endforeach; ?>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!-- Recent Referral Stream -->
        <div class="col-md-7">
            <div class="card shadow-sm border-0 mb-4">
                <div class="card-header bg-white py-3 border-bottom">
                    <h5 class="mb-0 font-weight-bold">⚡ Recent Referral Events</h5>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead class="thead-light">
                                <tr>
                                    <th>Referrer</th>
                                    <th>Referred Friend</th>
                                    <th>Status</th>
                                    <th>Time</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (empty($recentEvents)): ?>
                                <tr><td colspan="4" class="text-center p-4 text-muted">No referral events recorded yet</td></tr>
                                <?php else: ?>
                                    <?php foreach ($recentEvents as $ev):
                                        $badgeColor = [
                                            'attributed'            => 'badge-warning',
                                            'pending_qualification' => 'badge-info',
                                            'qualified'             => 'badge-primary',
                                            'rewarded'              => 'badge-success',
                                            'fraud_flagged'         => 'badge-danger'
                                        ][$ev['status']] ?? 'badge-secondary';
                                    ?>
                                    <tr>
                                        <td>
                                            <div class="font-weight-bold"><?php echo htmlspecialchars($ev['referrer_name']); ?></div>
                                            <small class="text-muted"><?php echo htmlspecialchars($ev['referrer_email']); ?></small>
                                        </td>
                                        <td>
                                            <div class="font-weight-bold"><?php echo htmlspecialchars($ev['friend_name']); ?></div>
                                            <small class="text-muted"><?php echo htmlspecialchars($ev['friend_email']); ?></small>
                                        </td>
                                        <td>
                                            <span class="badge <?php echo $badgeColor; ?>"><?php echo strtoupper($ev['status']); ?></span>
                                        </td>
                                        <td>
                                            <small class="text-muted"><?php echo date('d M, h:i A', strtotime($ev['created_at'])); ?></small>
                                        </td>
                                    </tr>
                                    <?php endforeach; ?>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
