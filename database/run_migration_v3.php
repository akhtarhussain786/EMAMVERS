<?php
if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit("This maintenance script can only be run from the command line.\n");
}

require_once __DIR__ . '/../api/config/db.php';

try {
    $db = Database::getConnection();
    echo "=== Running Migration v3: Current Affairs & AI Quizzes ===\n";

    // 1. Add columns to current_affairs
    $columns = [
        'summary' => 'TEXT NULL',
        'exam_relevance' => 'VARCHAR(255) NULL',
        'source_name' => 'VARCHAR(150) NULL',
        'image_url' => 'VARCHAR(500) NULL',
        'tags' => 'VARCHAR(255) NULL',
        'read_time_minutes' => 'INT DEFAULT 3'
    ];

    foreach ($columns as $col => $type) {
        $check = $db->query("SHOW COLUMNS FROM `current_affairs` LIKE '$col'")->fetch();
        if (!$check) {
            $db->exec("ALTER TABLE `current_affairs` ADD COLUMN `$col` $type");
            echo "Added column `$col` to `current_affairs`\n";
        } else {
            echo "Column `$col` already exists\n";
        }
    }

    // 2. Create current_affairs_quizzes table
    $db->exec("
        CREATE TABLE IF NOT EXISTS `current_affairs_quizzes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `article_id` INT NOT NULL,
            `question_text` TEXT NOT NULL,
            `option_a` TEXT NOT NULL,
            `option_b` TEXT NOT NULL,
            `option_c` TEXT NOT NULL,
            `option_d` TEXT NOT NULL,
            `correct_option` ENUM('A','B','C','D') NOT NULL,
            `explanation` TEXT NOT NULL,
            `difficulty` ENUM('easy','medium','hard') DEFAULT 'medium',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`article_id`) REFERENCES `current_affairs`(`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");
    echo "Table `current_affairs_quizzes` verified/created.\n";

    // 3. Seed comprehensive daily current affairs
    $articles = [
        [
            'title' => 'Reserve Bank of India Keeps Repo Rate Unchanged at 6.5% for Ninth Consecutive Time',
            'category' => 'Banking & Economy',
            'publish_date' => date('Y-m-d'),
            'summary' => 'The Monetary Policy Committee (MPC) of the Reserve Bank of India, headed by Governor Shaktikanta Das, decided by a 4:2 majority to keep the benchmark policy repo rate unchanged at 6.50%. The standing deposit facility (SDF) rate remains at 6.25% and marginal standing facility (MSF) at 6.75%. Inflation target remains anchored at 4%.',
            'content_body' => "The Reserve Bank of India's (RBI) Monetary Policy Committee (MPC) announced its bi-monthly monetary policy decision, keeping the policy repo rate unchanged at 6.50% for the ninth consecutive meeting.\n\nKey Highlights of the Policy:\n1. Repo Rate & Stance: Repo rate stays at 6.50%. The standing deposit facility (SDF) rate remains at 6.25%, and the marginal standing facility (MSF) rate and Bank Rate at 6.75%. The committee decided to remain focused on the 'Withdrawal of Accommodation' to ensure that inflation aligns with the target while supporting growth.\n\n2. Inflation & GDP Forecast: Real GDP growth for FY25 is projected at 7.2%, with Q1 at 7.1%, Q2 at 7.2%, Q3 at 7.3%, and Q4 at 7.2%. CPI inflation for FY25 is projected at 4.5%.\n\n3. Regulatory Announcements: The RBI announced an increase in the limit for tax payments through UPI from ₹1 lakh to ₹5 lakh per transaction to enhance digital adoption.\n\n4. Global Context: The decision comes amidst persistent food inflation pressures in the domestic market and economic uncertainties across advanced economies.",
            'exam_relevance' => 'UPSC CSE (GS-3 Economy), RBI Grade B, SBI PO, IBPS PO, SSC CGL',
            'source_name' => 'RBI Official Press Release / The Hindu',
            'image_url' => 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800',
            'tags' => 'Monetary Policy, Repo Rate, RBI, Inflation, Banking',
            'read_time_minutes' => 3
        ],
        [
            'title' => 'ISRO Successfully Tests Human-Rated Cryogenic Stage for Gaganyaan Mission',
            'category' => 'Science & Technology',
            'publish_date' => date('Y-m-d'),
            'summary' => 'The Indian Space Research Organisation (ISRO) has achieved a major milestone by human-rating its CE20 cryogenic engine that powers the cryogenic stage of the human-rated LVM3 launch vehicle for India\'s maiden human spaceflight mission, Gaganyaan.',
            'content_body' => "The Indian Space Research Organisation (ISRO) has accomplished the critical human-rating qualification for the CE20 cryogenic engine, paving the way for the maiden uncrewed and subsequent crewed Gaganyaan missions.\n\nTechnical Overview:\n1. Engine & Testing: The CE20 cryogenic engine was tested at the ISRO Propulsion Complex (IPRC) in Mahendragiri, Tamil Nadu. The engine underwent rigorous vacuum testing, hot tests for extended durations, and simulated flight acceptance tests.\n\n2. Crew Module Readiness: The Gaganyaan project envisages demonstrating human spaceflight capability to Low Earth Orbit (LEO) of 400 km for a 3-day mission with a crew of 3 members, safely returning them to Indian waters.\n\n3. Significance: India aims to become only the fourth nation in the world—after the United States, Russia, and China—to send humans into space independently.",
            'exam_relevance' => 'UPSC CSE (GS-3 Space & Tech), SSC CGL Science, State PSCs, NDA/CDS',
            'source_name' => 'ISRO / Press Information Bureau',
            'image_url' => 'https://images.unsplash.com/photo-1517976487504-59a1a04d20d6?w=800',
            'tags' => 'ISRO, Gaganyaan, Space Technology, Cryogenic Engine, LVM3',
            'read_time_minutes' => 4
        ],
        [
            'title' => 'India and European Union Launch 8th Round of Free Trade Agreement (FTA) Negotiations in Brussels',
            'category' => 'International Relations',
            'publish_date' => date('Y-m-d', strtotime('-1 day')),
            'summary' => 'India and the European Union concluded extensive discussions during the 8th round of negotiations for the comprehensive Free Trade Agreement (FTA), Investment Protection Agreement (IPA), and Geographical Indications (GIs) Agreement in Brussels.',
            'content_body' => "Negotiators from India and the European Union held the eighth round of talks for the proposed India-EU Free Trade Agreement (FTA) in Brussels, focusing on goods, services, rules of origin, and digital trade.\n\nCore Discussion Areas:\n1. Market Access & Tariff Reduction: Discussions covered tariff reductions on key Indian exports, including textiles, leather, marine products, and chemicals, alongside European automobiles, wines, and spirits.\n\n2. Carbon Border Adjustment Mechanism (CBAM): India raised concerns regarding the EU's Carbon Border Adjustment Mechanism and its potential impact on Indian steel and aluminum exports.\n\n3. Strategic Partnership: The EU is India's second-largest trading partner after the US. Concluding the FTA will significantly boost bilateral trade beyond the current \$130+ billion threshold and strengthen supply chain resilience.",
            'exam_relevance' => 'UPSC CSE (GS-2 International Relations), SSC CGL, State PSCs',
            'source_name' => 'Ministry of Commerce & Industry / Reuters',
            'image_url' => 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=800',
            'tags' => 'India-EU, Free Trade Agreement, International Trade, CBAM, Diplomacy',
            'read_time_minutes' => 4
        ],
        [
            'title' => 'India Adds 3 New Ramsar Sites, Taking Total Wetland Count to 85',
            'category' => 'Environment & Ecology',
            'publish_date' => date('Y-m-d', strtotime('-2 days')),
            'summary' => 'India has expanded its network of protected wetlands under the Ramsar Convention by designating three new wetlands in Tamil Nadu and Karnataka, bringing the total number of Ramsar sites in India to 85, the highest in Asia.',
            'content_body' => "India's Ministry of Environment, Forest and Climate Change announced the designation of three additional wetlands under the Ramsar Convention on Wetlands of International Importance.\n\nKey Details of the New Sites:\n1. Nanjarayan Bird Sanctuary: Located in Tirupur district, Tamil Nadu, home to over 130 bird species and a critical stopover on the Central Asian Flyway.\n\n2. Kazhuveli Bird Sanctuary: Located in Villupuram district, Tamil Nadu, recognized as one of the largest brackish water wetlands in South India.\n\n3. Tawa Reservoir: Located in Narmadapuram district, Madhya Pradesh / Karnataka borders, providing critical habitat for vulnerable fish species and migratory waterbirds.\n\nConservation Significance:\nWith 85 Ramsar sites covering over 1.35 million hectares, India continues to lead Asia in wetland conservation efforts, aligning with the Amrit Dharohar initiative launched by the Government of India.",
            'exam_relevance' => 'UPSC CSE (GS-3 Environment & Biodiversity), State PSCs, SSC CGL',
            'source_name' => 'Ministry of Environment, Forest and Climate Change',
            'image_url' => 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
            'tags' => 'Ramsar Sites, Wetlands, Biodiversity, Environment, Amrit Dharohar',
            'read_time_minutes' => 3
        ],
        [
            'title' => 'Cabinet Approves Unified Pension Scheme (UPS) for Central Government Employees',
            'category' => 'Governance & Policy',
            'publish_date' => date('Y-m-d', strtotime('-3 days')),
            'summary' => 'The Union Cabinet has approved the Unified Pension Scheme (UPS) for Central Government employees, guaranteeing 50% of the average basic pay drawn over the last 12 months as pension for those completing a minimum qualifying service of 25 years.',
            'content_body' => "The Union Cabinet chaired by the Prime Minister approved the landmark Unified Pension Scheme (UPS), which harmonizes features of the Old Pension Scheme (OPS) and the National Pension System (NPS).\n\nPillars of the Unified Pension Scheme:\n1. Assured Pension: 50% of the average basic pay drawn in the last 12 months before superannuation for a minimum qualifying service of 25 years. Proportionate pension for service between 10 and 25 years.\n\n2. Assured Family Pension: 60% of the pension of the employee immediately before their demise.\n\n3. Assured Minimum Pension: ₹10,000 per month on superannuation after a minimum of 10 years of service.\n\n4. Inflation Indexation: Dearness Relief (DR) will be provided on the assured pension, family pension, and minimum pension, indexed to the All India Consumer Price Index for Industrial Workers (AICPI-IW).\n\n5. Lump Sum on Superannuation: In addition to gratuity, a lump sum payment based on 1/10th of monthly emoluments for every completed six months of service.",
            'exam_relevance' => 'UPSC CSE (GS-2 Governance & Welfare), SSC CGL, Banking, State PSCs',
            'source_name' => 'Cabinet Secretariat / PIB',
            'image_url' => 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800',
            'tags' => 'Unified Pension Scheme, UPS, Governance, NPS, Central Government',
            'read_time_minutes' => 4
        ]
    ];

    foreach ($articles as $art) {
        $existing = $db->prepare("SELECT id FROM `current_affairs` WHERE `title`=?");
        $existing->execute([$art['title']]);
        if ($existing->fetch()) {
            // Update
            $u = $db->prepare("UPDATE `current_affairs` SET `category`=?, `publish_date`=?, `summary`=?, `content_body`=?, `exam_relevance`=?, `source_name`=?, `image_url`=?, `tags`=?, `read_time_minutes`=? WHERE `title`=?");
            $u->execute([$art['category'], $art['publish_date'], $art['summary'], $art['content_body'], $art['exam_relevance'], $art['source_name'], $art['image_url'], $art['tags'], $art['read_time_minutes'], $art['title']]);
            echo "Updated article: {$art['title']}\n";
        } else {
            // Insert
            $ins = $db->prepare("INSERT INTO `current_affairs` (`title`, `category`, `publish_date`, `summary`, `content_body`, `exam_relevance`, `source_name`, `image_url`, `tags`, `read_time_minutes`, `is_published`) VALUES (?,?,?,?,?,?,?,?,?,?,1)");
            $ins->execute([$art['title'], $art['category'], $art['publish_date'], $art['summary'], $art['content_body'], $art['exam_relevance'], $art['source_name'], $art['image_url'], $art['tags'], $art['read_time_minutes']]);
            echo "Inserted article: {$art['title']}\n";
        }
    }

    echo "=== Migration v3 Completed Successfully! ===\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
