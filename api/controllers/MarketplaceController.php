<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class MarketplaceController {

    // ─── LIST MATERIALS (PUBLIC with filters) ─────────────────────────

    public static function list() {
        $db = Database::getConnection();

        $page     = max(1, intval($_GET['page'] ?? 1));
        $limit    = min(intval($_GET['limit'] ?? 20), 50);
        $offset   = ($page - 1) * $limit;
        $search   = trim($_GET['q'] ?? '');
        $examId   = intval($_GET['exam_id'] ?? 0);
        $subjectId = intval($_GET['subject_id'] ?? 0);
        $minPrice = floatval($_GET['min_price'] ?? 0);
        $maxPrice = floatval($_GET['max_price'] ?? 9999);
        $sortBy   = in_array($_GET['sort'] ?? '', ['price_asc','price_desc','popular','newest','rating']) ? $_GET['sort'] : 'newest';
        $isFree   = isset($_GET['free']) ? (int)(bool)$_GET['free'] : null;

        $where = ["sm.status='approved'"];
        $params = [];

        if ($search) {
            $where[] = "(sm.title LIKE ? OR sm.description LIKE ? OR sm.tags LIKE ?)";
            $params = array_merge($params, ["%$search%", "%$search%", "%$search%"]);
        }
        if ($examId)    { $where[] = "sm.exam_id=?";    $params[] = $examId; }
        if ($subjectId) { $where[] = "sm.subject_id=?"; $params[] = $subjectId; }
        if ($isFree !== null) { $where[] = "sm.is_free=?"; $params[] = $isFree; }
        $where[] = "sm.price BETWEEN ? AND ?";
        $params[] = $minPrice;
        $params[] = $maxPrice;

        $orderBy = match($sortBy) {
            'price_asc'  => 'sm.price ASC',
            'price_desc' => 'sm.price DESC',
            'popular'    => 'sm.total_downloads DESC',
            'rating'     => 'sm.rating_avg DESC',
            default      => 'sm.created_at DESC'
        };

        $whereStr = implode(' AND ', $where);

        // Count
        $countStmt = $db->prepare("SELECT COUNT(*) FROM study_materials sm WHERE $whereStr");
        $countStmt->execute($params);
        $total = $countStmt->fetchColumn();

        // Fetch
        $stmt = $db->prepare("
            SELECT sm.id, sm.title, sm.description, sm.price, sm.is_free, sm.preview_pages,
                   sm.total_pages, sm.file_size_kb, sm.language, sm.cover_image_url,
                   sm.total_downloads, sm.rating_avg, sm.rating_count, sm.created_at,
                   sm.tags, sm.slug,
                   c.display_name as creator_name, c.id as creator_id,
                   e.title as exam_title, s.name as subject_name
            FROM study_materials sm
            JOIN creators c ON sm.creator_id=c.id
            LEFT JOIN exams e ON sm.exam_id=e.id
            LEFT JOIN subjects s ON sm.subject_id=s.id
            WHERE $whereStr
            ORDER BY $orderBy
            LIMIT $limit OFFSET $offset
        ");
        $stmt->execute($params);
        $materials = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json([
            'materials' => $materials,
            'pagination' => ['page' => $page, 'limit' => $limit, 'total' => $total, 'pages' => ceil($total/$limit)]
        ], 'Marketplace fetched');
    }

    // ─── MATERIAL DETAIL ──────────────────────────────────────────────

    public static function detail($id) {
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT sm.*, c.display_name as creator_name, c.id as creator_id,
                   u.full_name as creator_full_name,
                   e.title as exam_title, s.name as subject_name,
                   (SELECT COUNT(*) FROM material_purchases WHERE material_id=sm.id AND payment_status='completed') as total_buyers
            FROM study_materials sm
            JOIN creators c ON sm.creator_id=c.id
            JOIN users u ON c.user_id=u.id
            LEFT JOIN exams e ON sm.exam_id=e.id
            LEFT JOIN subjects s ON sm.subject_id=s.id
            WHERE sm.id=? AND sm.status='approved'
        ");
        $stmt->execute([$id]);
        $material = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$material) { Response::json(null,'Material not found','error',404); return; }

        // Reviews
        $revStmt = $db->prepare("SELECT mr.rating, mr.review_text, mr.created_at, u.full_name
                                  FROM material_reviews mr JOIN users u ON mr.user_id=u.id
                                  WHERE mr.material_id=? ORDER BY mr.created_at DESC LIMIT 10");
        $revStmt->execute([$id]);
        $material['reviews'] = $revStmt->fetchAll(PDO::FETCH_ASSOC);

        // Remove file_path from public response
        unset($material['file_path']);

        Response::json($material, 'Material detail fetched');
    }

    // ─── PURCHASE (MOCK PAYMENT) ──────────────────────────────────────

    public static function purchase($id) {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM study_materials WHERE id=? AND status='approved'");
        $stmt->execute([$id]);
        $material = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$material) { Response::json(null,'Material not found','error',404); return; }

        // Check already purchased
        $existing = $db->prepare("SELECT id FROM material_purchases WHERE user_id=? AND material_id=?");
        $existing->execute([$user['id'], $id]);
        if ($existing->fetch()) {
            Response::json(null,'Already purchased','error',409); return;
        }

        // Free material — direct access
        if ($material['is_free'] || $material['price'] == 0) {
            $stmt2 = $db->prepare("INSERT INTO material_purchases (user_id, material_id, amount_paid, platform_fee, creator_earning, payment_status, payment_method) VALUES (?,?,0,0,0,'completed','free')");
            $stmt2->execute([$user['id'], $id]);
            $db->prepare("UPDATE study_materials SET total_downloads=total_downloads+1 WHERE id=?")->execute([$id]);
            Response::json(['purchase_id' => $db->lastInsertId(), 'access_granted' => true], 'Free material unlocked!');
            return;
        }

        // Mock payment — in production replace with Razorpay
        $body = json_decode(file_get_contents('php://input'), true);
        $paymentMethod = $body['payment_method'] ?? 'mock_upi';
        $txnId = 'TXN_' . strtoupper(uniqid());

        $price = floatval($material['price']);
        $platformFee = round($price * 0.20, 2);       // 20% platform commission
        $creatorEarning = round($price - $platformFee, 2);

        $purchaseStmt = $db->prepare("INSERT INTO material_purchases (user_id, material_id, amount_paid, platform_fee, creator_earning, payment_status, payment_method, transaction_id) VALUES (?,?,?,?,?,'completed',?,?)");
        $purchaseStmt->execute([$user['id'], $id, $price, $platformFee, $creatorEarning, $paymentMethod, $txnId]);

        // Update creator pending_payout
        $db->prepare("UPDATE creators SET pending_payout=pending_payout+?, total_earnings=total_earnings+?, total_sales=total_sales+1 WHERE id=?")->execute([$creatorEarning, $creatorEarning, $material['creator_id']]);
        $db->prepare("UPDATE study_materials SET total_downloads=total_downloads+1, total_revenue=total_revenue+? WHERE id=?")->execute([$price, $id]);

        Response::json([
            'purchase_id'    => $db->lastInsertId(),
            'transaction_id' => $txnId,
            'amount_paid'    => $price,
            'access_granted' => true,
        ], 'Payment successful! Material unlocked.');
    }

    // ─── DOWNLOAD (after purchase check) ─────────────────────────────

    public static function download($id) {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT sm.*, mp.payment_status
                               FROM study_materials sm
                               LEFT JOIN material_purchases mp ON sm.id=mp.material_id AND mp.user_id=? AND mp.payment_status='completed'
                               WHERE sm.id=? AND sm.status='approved'");
        $stmt->execute([$user['id'], $id]);
        $material = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$material) { Response::json(null,'Material not found','error',404); return; }

        // Check access — either free or purchased
        if (!$material['is_free'] && $material['payment_status'] !== 'completed') {
            Response::json(null,'Purchase required to download','error',403); return;
        }

        $filePath = __DIR__ . '/../../' . $material['file_path'];
        if (!file_exists($filePath)) {
            Response::json(null,'File not found on server','error',404); return;
        }

        // Return signed download URL (in prod) — for now return the path info
        Response::json([
            'download_url' => '/EXAMVERSE/' . $material['file_path'],
            'title' => $material['title'],
            'file_size_kb' => $material['file_size_kb'],
        ], 'Download ready');
    }

    // ─── MY PURCHASES ─────────────────────────────────────────────────

    public static function myPurchases() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT mp.*, sm.title, sm.cover_image_url, sm.file_size_kb, sm.language,
                   sm.slug, c.display_name as creator_name,
                   e.title as exam_title
            FROM material_purchases mp
            JOIN study_materials sm ON mp.material_id=sm.id
            JOIN creators c ON sm.creator_id=c.id
            LEFT JOIN exams e ON sm.exam_id=e.id
            WHERE mp.user_id=? AND mp.payment_status='completed'
            ORDER BY mp.purchased_at DESC
        ");
        $stmt->execute([$user['id']]);
        Response::json($stmt->fetchAll(PDO::FETCH_ASSOC), 'Purchases fetched');
    }

    // ─── RATE MATERIAL ────────────────────────────────────────────────

    public static function rate($id) {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $db = Database::getConnection();

        // Must have purchased
        $pStmt = $db->prepare("SELECT id FROM material_purchases WHERE user_id=? AND material_id=? AND payment_status='completed'");
        $pStmt->execute([$user['id'], $id]);
        if (!$pStmt->fetch()) { Response::json(null,'Purchase the material before rating','error',403); return; }

        $body = json_decode(file_get_contents('php://input'), true);
        $rating = intval($body['rating'] ?? 0);
        $review = trim($body['review'] ?? '');

        if ($rating < 1 || $rating > 5) { Response::json(null,'Rating must be 1-5','error',422); return; }

        $stmt = $db->prepare("INSERT INTO material_reviews (material_id, user_id, rating, review_text) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE rating=?, review_text=?");
        $stmt->execute([$id, $user['id'], $rating, $review, $rating, $review]);

        // Recalculate avg
        $avgStmt = $db->prepare("SELECT AVG(rating) as avg, COUNT(*) as cnt FROM material_reviews WHERE material_id=?");
        $avgStmt->execute([$id]);
        $avg = $avgStmt->fetch(PDO::FETCH_ASSOC);
        $db->prepare("UPDATE study_materials SET rating_avg=?, rating_count=? WHERE id=?")->execute([round($avg['avg'],2), $avg['cnt'], $id]);

        Response::json(null,'Rating submitted!');
    }

    // ─── ADMIN: LIST ALL MATERIALS ────────────────────────────────────

    public static function adminList() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();

        $status = $_GET['status'] ?? 'pending_review';
        $stmt = $db->prepare("SELECT sm.*, c.display_name as creator_name, u.email as creator_email,
                               e.title as exam_title, s.name as subject_name
                               FROM study_materials sm
                               JOIN creators c ON sm.creator_id=c.id
                               JOIN users u ON c.user_id=u.id
                               LEFT JOIN exams e ON sm.exam_id=e.id
                               LEFT JOIN subjects s ON sm.subject_id=s.id
                               WHERE sm.status=? ORDER BY sm.created_at DESC");
        $stmt->execute([$status]);
        Response::json($stmt->fetchAll(PDO::FETCH_ASSOC), 'Admin materials fetched');
    }

    public static function adminApprove($id) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $db->prepare("UPDATE study_materials SET status='approved' WHERE id=?")->execute([$id]);
        Response::json(null,'Material approved');
    }

    public static function adminReject($id) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $body = json_decode(file_get_contents('php://input'), true);
        $reason = trim($body['reason'] ?? 'Does not meet quality standards');
        $db = Database::getConnection();
        $db->prepare("UPDATE study_materials SET status='rejected', rejection_reason=? WHERE id=?")->execute([$reason, $id]);
        Response::json(null,'Material rejected');
    }

    // ─── ADMIN REVENUE STATS ──────────────────────────────────────────

    public static function adminStats() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();

        $stats = $db->query("SELECT
            COUNT(DISTINCT mp.id) as total_sales,
            COALESCE(SUM(mp.amount_paid),0) as total_revenue,
            COALESCE(SUM(mp.platform_fee),0) as platform_earnings,
            COALESCE(SUM(mp.creator_earning),0) as creator_payouts,
            COUNT(DISTINCT mp.user_id) as unique_buyers,
            COUNT(DISTINCT sm.creator_id) as active_creators
        FROM material_purchases mp
        JOIN study_materials sm ON mp.material_id=sm.id
        WHERE mp.payment_status='completed'")->fetch(PDO::FETCH_ASSOC);

        Response::json($stats,'Marketplace stats fetched');
    }
}
