<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$usersCount = $db->query("SELECT COUNT(*) FROM users")->fetchColumn();
$testsCount = $db->query("SELECT COUNT(*) FROM tests")->fetchColumn();
$attemptsCount = $db->query("SELECT COUNT(*) FROM test_attempts")->fetchColumn();
$questionsCount = $db->query("SELECT COUNT(*) FROM questions")->fetchColumn();
$activeChallenges = $db->query("SELECT COUNT(*) FROM monthly_challenges WHERE status = 'live'")->fetchColumn();

$recentAttempts = $db->query("
    SELECT att.id, att.score, att.accuracy_percentage, att.started_at, u.full_name, t.title as test_title 
    FROM test_attempts att
    JOIN users u ON att.user_id = u.id
    JOIN tests t ON att.test_id = t.id
    ORDER BY att.id DESC LIMIT 5
")->fetchAll();
?>

<div class="metrics-grid">
    <a href="index.php?page=users" class="metric-card" style="text-decoration: none; transition: transform 0.2s;" onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
        <div class="metric-title">Total Candidates</div>
        <div class="metric-value" style="color: var(--accent-blue);"><?php echo number_format($usersCount); ?></div>
    </a>
    <div class="metric-card">
        <div class="metric-title">Published Tests</div>
        <div class="metric-value"><?php echo number_format($testsCount); ?></div>
    </div>
    <div class="metric-card">
        <div class="metric-title">Test Attempts</div>
        <div class="metric-value"><?php echo number_format($attemptsCount); ?></div>
    </div>
    <div class="metric-card">
        <div class="metric-title">Question Bank Size</div>
        <div class="metric-value"><?php echo number_format($questionsCount); ?></div>
    </div>
    <div class="metric-card">
        <div class="metric-title">Live Monthly Challenges</div>
        <div class="metric-value" style="color:var(--accent-emerald);"><?php echo number_format($activeChallenges); ?></div>
    </div>
</div>

<div class="table-card">
    <div class="table-header">
        <div class="table-title">Recent Candidate Test Attempts</div>
        <a href="index.php?page=tests" class="btn btn-primary">Manage Tests</a>
    </div>
    <table>
        <thead>
            <tr>
                <th>Attempt ID</th>
                <th>Candidate Name</th>
                <th>Test Title</th>
                <th>Score</th>
                <th>Accuracy</th>
                <th>Attempt Time</th>
            </tr>
        </thead>
        <tbody>
            <?php if (empty($recentAttempts)): ?>
                <tr><td colspan="6" style="text-align:center; color:var(--text-muted);">No attempts recorded yet.</td></tr>
            <?php else: ?>
                <?php foreach ($recentAttempts as $att): ?>
                    <tr>
                        <td>#ATT-<?php echo sprintf('%05d', $att['id']); ?></td>
                        <td style="font-weight:600;"><?php echo htmlspecialchars($att['full_name']); ?></td>
                        <td><?php echo htmlspecialchars($att['test_title']); ?></td>
                        <td><span class="badge badge-success"><?php echo number_format($att['score'], 2); ?> Marks</span></td>
                        <td><?php echo number_format($att['accuracy_percentage'], 1); ?>%</td>
                        <td style="color:var(--text-muted);"><?php echo $att['started_at']; ?></td>
                    </tr>
                <?php endforeach; ?>
            <?php endif; ?>
        </tbody>
    </table>
</div>
