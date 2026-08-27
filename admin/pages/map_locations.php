<?php
require_once __DIR__ . '/../../api/config/db.php';
$db = Database::getConnection();

// Handle add location form submit
$message = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'add_location') {
    $name = trim($_POST['name']);
    $category_id = intval($_POST['category_id']);
    $state = trim($_POST['state']);
    $country = trim($_POST['country']) ?: 'India';
    $lat = floatval($_POST['latitude']);
    $lng = floatval($_POST['longitude']);
    $desc = trim($_POST['short_description']);
    $facts = trim($_POST['important_facts']);
    $relevance = trim($_POST['exam_relevance']);
    $pyqs = intval($_POST['pyq_count']);

    $slug = strtolower(trim(preg_replace('/[^A-Za-z0-9-]+/', '-', $name)));

    try {
        $stmt = $db->prepare("INSERT INTO map_locations (category_id, name, slug, country, state, latitude, longitude, short_description, important_facts, exam_relevance, pyq_count) 
                              VALUES (:cat, :name, :slug, :country, :state, :lat, :lng, :desc, :facts, :relevance, :pyqs)");
        $stmt->execute([
            'cat' => $category_id, 'name' => $name, 'slug' => $slug, 'country' => $country, 'state' => $state,
            'lat' => $lat, 'lng' => $lng, 'desc' => $desc, 'facts' => $facts, 'relevance' => $relevance, 'pyqs' => $pyqs
        ]);
        $message = "Location '$name' added successfully!";
    } catch (Exception $e) {
        $message = "Error: " . $e->getMessage();
    }
}

$locations = $db->query("
    SELECT l.*, c.name as category_name 
    FROM map_locations l
    JOIN map_categories c ON l.category_id = c.id
    ORDER BY l.id DESC
")->fetchAll();

$categories = $db->query("SELECT * FROM map_categories ORDER BY name ASC")->fetchAll();
?>

<?php if ($message): ?>
<div style="padding: 12px; margin-bottom: 20px; background: rgba(56, 189, 248, 0.15); border: 1px solid #38bdf8; border-radius: 8px; color: #38bdf8;">
    <?php echo htmlspecialchars($message); ?>
</div>
<?php endif; ?>

<div class="table-card" style="margin-bottom: 30px;">
    <div class="table-header">
        <div class="table-title">Add New Map Learning Location</div>
    </div>
    <form method="POST" action="" style="padding: 20px;">
        <input type="hidden" name="action" value="add_location">
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px;">
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Location Name *</label>
                <input type="text" name="name" required style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
            </div>
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Category *</label>
                <select name="category_id" required style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
                    <?php foreach ($categories as $cat): ?>
                        <option value="<?php echo $cat['id']; ?>"><?php echo htmlspecialchars($cat['name']); ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">State / Region</label>
                <input type="text" name="state" placeholder="e.g. Gujarat" style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
            </div>
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Country</label>
                <input type="text" name="country" value="India" style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
            </div>
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Latitude *</label>
                <input type="number" step="any" name="latitude" required placeholder="e.g. 21.1243" style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
            </div>
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Longitude *</label>
                <input type="number" step="any" name="longitude" required placeholder="e.g. 70.8242" style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
            </div>
        </div>

        <div style="margin-bottom: 16px;">
            <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Short Description</label>
            <input type="text" name="short_description" placeholder="Short 1-line overview" style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
        </div>

        <div style="margin-bottom: 16px;">
            <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Important Facts (Dot separated)</label>
            <textarea name="important_facts" rows="2" placeholder="Fact 1. Fact 2. Fact 3." style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;"></textarea>
        </div>

        <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 16px; margin-bottom: 16px;">
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">Exam Relevance</label>
                <input type="text" name="exam_relevance" placeholder="High — Asked 14 times in SSC CGL" style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
            </div>
            <div>
                <label style="color: #94a3b8; display: block; margin-bottom: 6px;">PYQ Count</label>
                <input type="number" name="pyq_count" value="10" style="width: 100%; padding: 10px; background: #080d18; border: 1px solid rgba(148,163,184,0.2); color: white; border-radius: 6px;">
            </div>
        </div>

        <button type="submit" style="padding: 10px 24px; background: linear-gradient(135deg, #38bdf8, #0284c7); color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer;">
            + Save Location
        </button>
    </form>
</div>

<div class="table-card">
    <div class="table-header">
        <div class="table-title">Map Locations Library (<?php echo count($locations); ?> Locations)</div>
    </div>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Category</th>
                <th>State / Country</th>
                <th>Coordinates</th>
                <th>PYQs</th>
                <th>Relevance</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($locations as $loc): ?>
            <tr>
                <td>#<?php echo $loc['id']; ?></td>
                <td><strong><?php echo htmlspecialchars($loc['name']); ?></strong></td>
                <td><span style="padding: 3px 8px; background: rgba(56,189,248,0.15); color: #38bdf8; border-radius: 4px; font-size: 12px;"><?php echo htmlspecialchars($loc['category_name']); ?></span></td>
                <td><?php echo htmlspecialchars($loc['state'] ? $loc['state'] . ', ' . $loc['country'] : $loc['country']); ?></td>
                <td style="font-family: monospace; font-size: 12px; color: #94a3b8;"><?php echo $loc['latitude']; ?>, <?php echo $loc['longitude']; ?></td>
                <td><span style="color: #22c55e; font-weight: bold;"><?php echo $loc['pyq_count']; ?> PYQs</span></td>
                <td style="font-size: 12px; color: #94a3b8;"><?php echo htmlspecialchars($loc['exam_relevance']); ?></td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
