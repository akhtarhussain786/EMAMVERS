<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$patterns = $db->query("
    SELECT ep.*, e.title as exam_title 
    FROM exam_patterns ep 
    JOIN exams e ON ep.exam_id = e.id 
    ORDER BY ep.id DESC
")->fetchAll();
?>

<div class="table-card">
    <div class="table-header">
        <div class="table-title">Universal Exam Test Patterns</div>
    </div>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Exam Title</th>
                <th>Pattern Name</th>
                <th>Timer Mode</th>
                <th>Duration</th>
                <th>Questions</th>
                <th>Total Marks</th>
                <th>Marking Scheme</th>
                <th>Navigation</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($patterns as $p): ?>
                <tr>
                    <td>#<?php echo $p['id']; ?></td>
                    <td style="font-weight:600;"><?php echo htmlspecialchars($p['exam_title']); ?></td>
                    <td><?php echo htmlspecialchars($p['name']); ?></td>
                    <td><span class="badge badge-info"><?php echo $p['timer_mode']; ?></span></td>
                    <td><?php echo round($p['total_duration_seconds'] / 60); ?> Mins</td>
                    <td><?php echo $p['total_questions']; ?> Qs</td>
                    <td><?php echo number_format($p['total_marks'], 2); ?> Marks</td>
                    <td>+<?php echo $p['default_positive_marks']; ?> / -<?php echo $p['default_negative_marks']; ?></td>
                    <td><span class="badge badge-warning"><?php echo $p['navigation_policy']; ?></span></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
