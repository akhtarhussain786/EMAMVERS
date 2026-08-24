<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

$message = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['create_exam'])) {
    $title = trim($_POST['title']);
    $categoryId = intval($_POST['category_id']);
    $slug = trim($_POST['slug']);
    $shortDesc = trim($_POST['short_description']);

    if ($title && $categoryId) {
        $stmt = $db->prepare("INSERT INTO exams (category_id, title, slug, short_description, status) VALUES (:cid, :title, :slug, :desc, 'active')");
        $stmt->execute(['cid' => $categoryId, 'title' => $title, 'slug' => $slug ?: strtolower(str_replace(' ', '-', $title)), 'desc' => $shortDesc]);
        $message = 'Exam created successfully!';
    }
}

$categories = $db->query("SELECT * FROM exam_categories ORDER BY sort_order ASC")->fetchAll();
$exams = $db->query("
    SELECT e.*, c.name as category_name, o.short_name as org_name 
    FROM exams e 
    JOIN exam_categories c ON e.category_id = c.id 
    LEFT JOIN organizations o ON e.organization_id = o.id 
    ORDER BY e.id DESC
")->fetchAll();
?>

<?php if ($message): ?>
    <div style="background:rgba(16, 185, 129, 0.2); color:var(--accent-emerald); padding:1rem; border-radius:var(--radius-sm); margin-bottom:1.5rem; font-weight:600;">
        <?php echo htmlspecialchars($message); ?>
    </div>
<?php endif; ?>

<div style="display:grid; grid-template-columns: 1fr 2fr; gap:1.5rem;">
    <!-- Create Exam Form -->
    <div class="table-card">
        <div class="table-title" style="margin-bottom:1rem;">Add New Exam</div>
        <form method="POST">
            <input type="hidden" name="create_exam" value="1">
            <div class="form-group">
                <label class="form-label">Category</label>
                <select name="category_id" class="form-control" required>
                    <?php foreach ($categories as $cat): ?>
                        <option value="<?php echo $cat['id']; ?>"><?php echo htmlspecialchars($cat['name']); ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">Exam Title</label>
                <input type="text" name="title" class="form-control" placeholder="e.g. SSC CHSL 2026" required>
            </div>
            <div class="form-group">
                <label class="form-label">URL Slug</label>
                <input type="text" name="slug" class="form-control" placeholder="e.g. ssc-chsl-2026">
            </div>
            <div class="form-group">
                <label class="form-label">Short Description</label>
                <textarea name="short_description" class="form-control" rows="3" placeholder="Brief exam summary..."></textarea>
            </div>
            <button type="submit" class="btn btn-primary" style="width:100%; justify-content:center;">Create Exam</button>
        </form>
    </div>

    <!-- Exam List -->
    <div class="table-card">
        <div class="table-header">
            <div class="table-title">Configured Exam Taxonomy</div>
        </div>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Exam Title</th>
                    <th>Category</th>
                    <th>Organization</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($exams as $ex): ?>
                    <tr>
                        <td>#<?php echo $ex['id']; ?></td>
                        <td style="font-weight:600;"><?php echo htmlspecialchars($ex['title']); ?></td>
                        <td><span class="badge badge-info"><?php echo htmlspecialchars($ex['category_name']); ?></span></td>
                        <td><?php echo htmlspecialchars($ex['org_name'] ?? 'N/A'); ?></td>
                        <td><span class="badge badge-success"><?php echo ucfirst($ex['status']); ?></span></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
