<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../utils/auth_token.php';

class CreatorController {

    // ─── BECOME A CREATOR ─────────────────────────────────────────────

    public static function register() {
        $user = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $user['sub'] ?? ($user['id'] ?? null);
        $body = json_decode(file_get_contents('php://input'), true);

        $displayName = trim($body['display_name'] ?? '');
        $about       = trim($body['about'] ?? '');
        $upiId       = trim($body['upi_id'] ?? '');
        $bankAccount = trim($body['bank_account_number'] ?? '');
        $bankIfsc    = trim($body['bank_ifsc'] ?? '');
        $bankName    = trim($body['bank_account_name'] ?? '');

        if (empty($displayName)) {
            Response::json(null, 'display_name is required', 'error', 422);
            return;
        }

        $db = Database::getConnection();

        // Check if already a creator
        $existing = $db->prepare("SELECT id FROM creators WHERE user_id=?");
        $existing->execute([$userId]);
        if ($existing->fetch()) {
            Response::json(null, 'Already registered as creator', 'error', 409);
            return;
        }

        $stmt = $db->prepare("INSERT INTO creators (user_id, display_name, about, upi_id, bank_account_number, bank_ifsc, bank_account_name, verification_status) VALUES (?,?,?,?,?,?,?,'pending')");
        $stmt->execute([$userId, $displayName, $about, $upiId, $bankAccount, $bankIfsc, $bankName]);

        // Update user_type
        $db->prepare("UPDATE users SET user_type='creator' WHERE id=?")->execute([$userId]);

        Response::json(['creator_id' => $db->lastInsertId()], 'Creator registration submitted! Pending admin review.', 'success', 201);
    }

    // ─── CREATOR DASHBOARD ────────────────────────────────────────────

    public static function dashboard() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);
        $db = Database::getConnection();

        $cStmt = $db->prepare("SELECT c.*, u.full_name, u.email FROM creators c JOIN users u ON c.user_id=u.id WHERE c.user_id=?");
        $cStmt->execute([$userId]);
        $creator = $cStmt->fetch(PDO::FETCH_ASSOC);
        if (!$creator) { Response::json(null,'Creator profile not found','error',404); return; }

        // Stats
        $statsStmt = $db->prepare("
            SELECT
                COUNT(DISTINCT sm.id) as total_materials,
                COUNT(mp.id) as total_sales,
                COALESCE(SUM(mp.creator_earning),0) as total_earned,
                COALESCE(SUM(CASE WHEN mp.payment_status='completed' THEN mp.creator_earning ELSE 0 END),0) as confirmed_earnings
            FROM study_materials sm
            LEFT JOIN material_purchases mp ON sm.id=mp.material_id AND mp.payment_status='completed'
            WHERE sm.creator_id=?
        ");
        $statsStmt->execute([$creator['id']]);
        $stats = $statsStmt->fetch(PDO::FETCH_ASSOC);

        // Recent materials
        $matStmt = $db->prepare("SELECT sm.*, e.title as exam_title, s.name as subject_name,
                                  (SELECT COUNT(*) FROM material_purchases WHERE material_id=sm.id AND payment_status='completed') as sales_count
                                  FROM study_materials sm
                                  LEFT JOIN exams e ON sm.exam_id=e.id
                                  LEFT JOIN subjects s ON sm.subject_id=s.id
                                  WHERE sm.creator_id=? ORDER BY sm.created_at DESC LIMIT 10");
        $matStmt->execute([$creator['id']]);
        $materials = $matStmt->fetchAll(PDO::FETCH_ASSOC);

        // Recent sales
        $salesStmt = $db->prepare("SELECT mp.*, sm.title as material_title, u.full_name as buyer_name
                                    FROM material_purchases mp
                                    JOIN study_materials sm ON mp.material_id=sm.id
                                    JOIN users u ON mp.user_id=u.id
                                    WHERE sm.creator_id=? ORDER BY mp.purchased_at DESC LIMIT 10");
        $salesStmt->execute([$creator['id']]);
        $sales = $salesStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json([
            'creator'   => $creator,
            'stats'     => $stats,
            'materials' => $materials,
            'recent_sales' => $sales,
        ], 'Creator dashboard fetched');
    }

    // ─── UPLOAD STUDY MATERIAL ────────────────────────────────────────

    public static function uploadMaterial() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);
        $db = Database::getConnection();

        $cStmt = $db->prepare("SELECT id, verification_status FROM creators WHERE user_id=?");
        $cStmt->execute([$userId]);
        $creator = $cStmt->fetch(PDO::FETCH_ASSOC);
        if (!$creator) { Response::json(null,'Creator profile not found. Register as creator first.','error',403); return; }
        if ($creator['verification_status'] !== 'approved') {
            Response::json(null,'Your creator account is pending admin approval.','error',403); return;
        }

        // Handle file upload
        if (empty($_FILES['file'])) {
            Response::json(null,'File is required','error',422); return;
        }

        $file     = $_FILES['file'];
        $title    = trim($_POST['title'] ?? '');
        $examId   = intval($_POST['exam_id'] ?? 0) ?: null;
        $subjectId = intval($_POST['subject_id'] ?? 0) ?: null;
        $description = trim($_POST['description'] ?? '');
        $price    = floatval($_POST['price'] ?? 0);
        $previewPages = intval($_POST['preview_pages'] ?? 5);
        $language = $_POST['language'] ?? 'en';
        $tags     = trim($_POST['tags'] ?? '');

        if (empty($title)) { Response::json(null,'title is required','error',422); return; }
        if ($price < 0)    { Response::json(null,'price cannot be negative','error',422); return; }

        // Save file
        $uploadDir = __DIR__ . '/../../uploads/materials/';
        if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);

        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, ['pdf', 'pptx', 'docx', 'zip'])) {
            Response::json(null,'Only PDF, PPTX, DOCX, ZIP files allowed','error',422); return;
        }

        $fileName = uniqid('mat_', true) . '.' . $ext;
        $filePath = $uploadDir . $fileName;
        if (!move_uploaded_file($file['tmp_name'], $filePath)) {
            Response::json(null,'File upload failed','error',500); return;
        }

        $fileSizeKb = round($file['size'] / 1024);
        $slug = preg_replace('/[^a-z0-9]+/', '-', strtolower($title)) . '-' . uniqid();
        $isFree = ($price == 0) ? 1 : 0;

        $stmt = $db->prepare("INSERT INTO study_materials (creator_id, exam_id, subject_id, title, slug, description, tags, file_path, file_size_kb, preview_pages, language, price, is_free, status)
                              VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,'pending_review')");
        $stmt->execute([$creator['id'], $examId, $subjectId, $title, $slug, $description, $tags, 'uploads/materials/'.$fileName, $fileSizeKb, $previewPages, $language, $price, $isFree]);

        Response::json(['material_id' => $db->lastInsertId()], 'Material submitted for review!', 'success', 201);
    }

    // ─── LIST OWN MATERIALS ───────────────────────────────────────────

    public static function myMaterials() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);
        $db = Database::getConnection();

        $cStmt = $db->prepare("SELECT id FROM creators WHERE user_id=?");
        $cStmt->execute([$userId]);
        $creator = $cStmt->fetch(PDO::FETCH_ASSOC);
        if (!$creator) { Response::json([],'No creator profile'); return; }

        $stmt = $db->prepare("SELECT sm.*, e.title as exam_title, s.name as subject_name,
                               (SELECT COUNT(*) FROM material_purchases WHERE material_id=sm.id AND payment_status='completed') as sales_count,
                               (SELECT COALESCE(SUM(creator_earning),0) FROM material_purchases WHERE material_id=sm.id AND payment_status='completed') as revenue
                               FROM study_materials sm
                               LEFT JOIN exams e ON sm.exam_id=e.id
                               LEFT JOIN subjects s ON sm.subject_id=s.id
                               WHERE sm.creator_id=? ORDER BY sm.created_at DESC");
        $stmt->execute([$creator['id']]);
        Response::json($stmt->fetchAll(PDO::FETCH_ASSOC), 'Materials fetched');
    }

    // ─── REQUEST PAYOUT ───────────────────────────────────────────────

    public static function requestPayout() {
        $user = AuthMiddleware::getAuthenticatedUser();
        $userId = $user['sub'] ?? ($user['id'] ?? null);
        $db = Database::getConnection();

        $cStmt = $db->prepare("SELECT * FROM creators WHERE user_id=?");
        $cStmt->execute([$userId]);
        $creator = $cStmt->fetch(PDO::FETCH_ASSOC);
        if (!$creator) { Response::json(null,'Creator not found','error',404); return; }

        $body = json_decode(file_get_contents('php://input'), true);
        $amount = floatval($body['amount'] ?? 0);

        if ($amount < 100) { Response::json(null,'Minimum payout is ₹100','error',422); return; }
        if ($amount > $creator['pending_payout']) { Response::json(null,'Insufficient pending balance','error',422); return; }

        $stmt = $db->prepare("INSERT INTO creator_payouts (creator_id, amount_requested, status, payout_method) VALUES (?,?,'requested','upi')");
        $stmt->execute([$creator['id'], $amount]);
        Response::json(['payout_id' => $db->lastInsertId()], 'Payout request submitted!', 'success', 201);
    }

    // ─── ADMIN: LIST ALL CREATORS ─────────────────────────────────────

    public static function adminList() {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $stmt = $db->query("SELECT c.*, u.full_name, u.email, u.mobile, u.status as user_status
                            FROM creators c JOIN users u ON c.user_id=u.id
                            ORDER BY c.created_at DESC");
        Response::json($stmt->fetchAll(PDO::FETCH_ASSOC), 'Creators fetched');
    }

    public static function adminApprove($id) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $db->prepare("UPDATE creators SET verification_status='approved', verified_at=NOW() WHERE id=?")->execute([$id]);
        Response::json(null, 'Creator approved');
    }

    public static function adminSuspend($id) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $db = Database::getConnection();
        $db->prepare("UPDATE creators SET verification_status='suspended' WHERE id=?")->execute([$id]);
        Response::json(null, 'Creator suspended');
    }

    public static function adminProcessPayout($payoutId) {
        AuthMiddleware::getAuthenticatedUser('admin');
        $body = json_decode(file_get_contents('php://input'), true);
        $txnRef = trim($body['transaction_reference'] ?? '');
        $db = Database::getConnection();

        $pStmt = $db->prepare("SELECT * FROM creator_payouts WHERE id=?");
        $pStmt->execute([$payoutId]);
        $payout = $pStmt->fetch(PDO::FETCH_ASSOC);
        if (!$payout) { Response::json(null,'Payout not found','error',404); return; }

        $db->prepare("UPDATE creator_payouts SET status='completed', amount_paid=amount_requested, transaction_reference=?, processed_at=NOW() WHERE id=?")->execute([$txnRef, $payoutId]);
        $db->prepare("UPDATE creators SET pending_payout=pending_payout-?, paid_out=paid_out+? WHERE id=?")->execute([$payout['amount_requested'], $payout['amount_requested'], $payout['creator_id']]);

        Response::json(null,'Payout processed');
    }
}
