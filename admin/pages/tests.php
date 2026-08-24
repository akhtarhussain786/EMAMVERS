<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$tests = $db->query("
    SELECT t.*, e.title as exam_title, ep.name as pattern_name, ep.total_questions, ep.total_marks
    FROM tests t
    JOIN exams e ON t.exam_id = e.id
    JOIN exam_patterns ep ON t.pattern_id = ep.id
    ORDER BY t.id DESC
")->fetchAll();
?>

<div class="table-card">
    <div class="table-header">
        <div class="table-title">Published & Scheduled Test Series</div>
    </div>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Test Title</th>
                <th>Exam</th>
                <th>Test Type</th>
                <th>Pattern</th>
                <th>Questions</th>
                <th>Marks</th>
                <th>Access</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($tests as $t): ?>
                <tr>
                    <td>#TEST-<?php echo $t['id']; ?></td>
                    <td style="font-weight:600;"><?php echo htmlspecialchars($t['title']); ?></td>
                    <td><?php echo htmlspecialchars($t['exam_title']); ?></td>
                    <td><span class="badge badge-info"><?php echo $t['test_type']; ?></span></td>
                    <td><?php echo htmlspecialchars($t['pattern_name']); ?></td>
                    <td><?php echo $t['total_questions']; ?> Qs</td>
                    <td><?php echo number_format($t['total_marks'], 2); ?> Marks</td>
                    <td><?php echo $t['is_paid'] ? 'Paid (₹'.$t['price'].')' : 'Free'; ?></td>
                    <td><span class="badge badge-success"><?php echo ucfirst($t['status']); ?></span></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
