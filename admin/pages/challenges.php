<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$challenges = $db->query("
    SELECT mc.*, e.title as exam_title, t.title as test_title,
           (SELECT COUNT(*) FROM challenge_registrations cr WHERE cr.challenge_id = mc.id) as total_registered
    FROM monthly_challenges mc
    JOIN exams e ON mc.exam_id = e.id
    JOIN tests t ON mc.test_id = t.id
    ORDER BY mc.id DESC
")->fetchAll();
?>

<div class="table-card">
    <div class="table-header">
        <div class="table-title">Monthly National Flagship Challenges</div>
    </div>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Challenge Title</th>
                <th>Exam</th>
                <th>Month/Year</th>
                <th>Registered Candidates</th>
                <th>Window Period</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($challenges as $c): ?>
                <tr>
                    <td>#MC-<?php echo $c['id']; ?></td>
                    <td style="font-weight:600;"><?php echo htmlspecialchars($c['title']); ?></td>
                    <td><?php echo htmlspecialchars($c['exam_title']); ?></td>
                    <td><span class="badge badge-info"><?php echo htmlspecialchars($c['month_year']); ?></span></td>
                    <td style="font-weight:700; color:var(--accent-blue);"><?php echo number_format($c['total_registered']); ?> Registered</td>
                    <td style="font-size:0.8rem; color:var(--text-muted);"><?php echo $c['start_window']; ?> to <?php echo $c['end_window']; ?></td>
                    <td><span class="badge badge-success"><?php echo strtoupper($c['status']); ?></span></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
