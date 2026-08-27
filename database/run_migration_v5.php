<?php
require_once __DIR__ . '/../api/config/db.php';

try {
    $db = Database::getConnection();
    $sql = file_get_contents(__DIR__ . '/migration_v5.sql');
    $db->exec($sql);
    echo "Migration v5 tables created successfully.\n";

    // 1. Seed Map Categories
    $categories = [
        ['name' => 'National Parks', 'slug' => 'national-parks', 'icon' => 'park', 'sort_order' => 1],
        ['name' => 'Rivers & Lakes', 'slug' => 'rivers-lakes', 'icon' => 'water', 'sort_order' => 2],
        ['name' => 'Dams & Reservoirs', 'slug' => 'dams-reservoirs', 'icon' => 'water_damage', 'sort_order' => 3],
        ['name' => 'Historical Sites', 'slug' => 'historical-sites', 'icon' => 'account_balance', 'sort_order' => 4],
        ['name' => 'World Geography', 'slug' => 'world-geography', 'icon' => 'public', 'sort_order' => 5],
    ];

    $stmtCat = $db->prepare("INSERT IGNORE INTO map_categories (name, slug, icon, sort_order) VALUES (:name, :slug, :icon, :sort_order)");
    foreach ($categories as $cat) {
        $stmtCat->execute($cat);
    }
    echo "Map Categories seeded.\n";

    // Get Category IDs
    $catMap = [];
    $rows = $db->query("SELECT id, slug FROM map_categories")->fetchAll();
    foreach ($rows as $r) {
        $catMap[$r['slug']] = $r['id'];
    }

    // 2. Seed Locations
    $locations = [
        [
            'category_id' => $catMap['national-parks'],
            'name' => 'Gir National Park',
            'slug' => 'gir-national-park',
            'country' => 'India',
            'state' => 'Gujarat',
            'latitude' => 21.1243,
            'longitude' => 70.8242,
            'short_description' => 'Sole natural habitat of Asiatic Lions in Gujarat.',
            'important_facts' => 'Established in 1965. Home to Asiatic lions, leopards, and chinkara. Located in Kathiawar region.',
            'exam_relevance' => 'High — Asked 14 times in SSC CGL & UPSC CSAT',
            'pyq_count' => 14
        ],
        [
            'category_id' => $catMap['national-parks'],
            'name' => 'Kaziranga National Park',
            'slug' => 'kaziranga-national-park',
            'country' => 'India',
            'state' => 'Assam',
            'latitude' => 26.5775,
            'longitude' => 93.1711,
            'short_description' => 'UNESCO World Heritage Site famous for One-horned Rhinoceros.',
            'important_facts' => 'Located on Brahmaputra river plain. Hosts two-thirds of the worlds Great One-Horned Rhinoceroses.',
            'exam_relevance' => 'Very High — Frequently asked in UPSC & Railway Exams',
            'pyq_count' => 22
        ],
        [
            'category_id' => $catMap['rivers-lakes'],
            'name' => 'River Narmada',
            'slug' => 'river-narmada',
            'country' => 'India',
            'state' => 'Madhya Pradesh',
            'latitude' => 22.7533,
            'longitude' => 81.7582,
            'short_description' => 'West-flowing river originating from Amarkantak Plateau.',
            'important_facts' => 'Flows through rift valley between Vindhya and Satpura ranges. Drains into Arabian Sea at Gulf of Khambhat.',
            'exam_relevance' => 'High — SSC CGL & BPSC favorite rift valley question',
            'pyq_count' => 18
        ],
        [
            'category_id' => $catMap['rivers-lakes'],
            'name' => 'Chilika Lake',
            'slug' => 'chilika-lake',
            'country' => 'India',
            'state' => 'Odisha',
            'latitude' => 19.6800,
            'longitude' => 85.3300,
            'short_description' => 'Largest brackish water lagoon in Asia & first Ramsar site of India.',
            'important_facts' => 'Designated first Ramsar wetland in 1981. Famous for Irrawaddy dolphins and winter migratory birds.',
            'exam_relevance' => 'High — Environment & Ecology PYQ staple',
            'pyq_count' => 16
        ],
        [
            'category_id' => $catMap['dams-reservoirs'],
            'name' => 'Tehri Dam',
            'slug' => 'tehri-dam',
            'country' => 'India',
            'state' => 'Uttarakhand',
            'latitude' => 30.3781,
            'longitude' => 78.4803,
            'short_description' => 'Tallest dam in India constructed on Bhagirathi River.',
            'important_facts' => 'Height of 260.5 meters. Multipurpose rock and earth-fill embankment dam located in Garhwal region.',
            'exam_relevance' => 'High — Static GK & Geography core question',
            'pyq_count' => 12
        ],
        [
            'category_id' => $catMap['historical-sites'],
            'name' => 'Nalanda Mahavihara',
            'slug' => 'nalanda-mahavihara',
            'country' => 'India',
            'state' => 'Bihar',
            'latitude' => 25.1357,
            'longitude' => 85.4446,
            'short_description' => 'Ancient Mahavihara & Buddhist monastery established during Gupta Empire.',
            'important_facts' => 'Founded in 5th century CE under Kumaragupta I. Visited by Hiuen Tsang. UNESCO World Heritage Site.',
            'exam_relevance' => 'Very High — History PYQ for BPSC & SSC CGL',
            'pyq_count' => 25
        ],
        [
            'category_id' => $catMap['world-geography'],
            'name' => 'Suez Canal',
            'slug' => 'suez-canal',
            'country' => 'Egypt',
            'state' => 'Suez',
            'latitude' => 30.5852,
            'longitude' => 32.2654,
            'short_description' => 'Artificial sea-level waterway connecting Mediterranean Sea to Red Sea.',
            'important_facts' => 'Opened in November 1869. Separates African continent from Sinai Peninsula. Shortcut between Europe & Asia.',
            'exam_relevance' => 'High — World Geography & Trade Routes PYQ',
            'pyq_count' => 19
        ],
    ];

    $stmtLoc = $db->prepare("INSERT IGNORE INTO map_locations (category_id, name, slug, country, state, latitude, longitude, short_description, important_facts, exam_relevance, pyq_count) 
                             VALUES (:category_id, :name, :slug, :country, :state, :latitude, :longitude, :short_description, :important_facts, :exam_relevance, :pyq_count)");

    foreach ($locations as $loc) {
        $stmtLoc->execute($loc);
    }
    echo "Map Locations seeded successfully.\n";

} catch (PDOException $e) {
    echo "Migration failed: " . $e->getMessage() . "\n";
}
