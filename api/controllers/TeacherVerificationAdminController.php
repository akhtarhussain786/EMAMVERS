<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

/**
 * Admin Teacher KYC Verification Controller.
 * Handles:
 * - Application listing and filtering
 * - Secure authenticated KYC document streaming
 * - Document-by-document status updates
 * - Request changes, Reject, and Atomic Approval
 */
class TeacherVerificationAdminController {

    private static function requireAdmin() {
        AuthMiddleware::getAuthenticatedUser('admin');
    }

    /**
     * List all teacher applications with filters and pagination.
     */
    public static function listApplications() {
        self::requireAdmin();
        $db = Database::getConnection();

        $status = $_GET['status'] ?? '';
        $search = trim($_GET['search'] ?? '');
        $page   = max(1, intval($_GET['page'] ?? 1));
        $limit  = min(50, max(1, intval($_GET['limit'] ?? 20)));
        $offset = ($page - 1) * $limit;

        $where = ["1=1"];
        $params = [];

        if ($status !== '' && $status !== 'all') {
            $where[] = "ta.status = ?";
            $params[] = $status;
        }

        if ($search !== '') {
            $where[] = "(u.full_name LIKE ? OR u.email LIKE ? OR u.mobile LIKE ? OR ta.application_no LIKE ? OR ta.institution_name LIKE ?)";
            $searchTerm = "%$search%";
            $params = array_merge($params, [$searchTerm, $searchTerm, $searchTerm, $searchTerm, $searchTerm]);
        }

        $whereSql = implode(' AND ', $where);

        $countStmt = $db->prepare("
            SELECT COUNT(*) FROM teacher_applications ta
            LEFT JOIN users u ON ta.user_id = u.id
            WHERE $whereSql
        ");
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $stmt = $db->prepare("
            SELECT ta.*, 
                   COALESCE(u.full_name, 'Teacher Applicant') AS full_name, 
                   COALESCE(u.email, 'N/A') AS email, 
                   COALESCE(u.mobile, 'N/A') AS mobile, 
                   COALESCE(s.name, 'All India') AS state,
                   (SELECT COUNT(*) FROM teacher_documents td WHERE td.application_id = ta.id) AS document_count
            FROM teacher_applications ta
            LEFT JOIN users u ON ta.user_id = u.id
            LEFT JOIN states s ON u.state_id = s.id
            WHERE $whereSql
            ORDER BY COALESCE(ta.submitted_at, ta.created_at) DESC, ta.id DESC
            LIMIT $limit OFFSET $offset
        ");
        $stmt->execute($params);
        $applications = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($applications as &$app) {
            $app['subject_ids'] = $app['subject_ids'] ? json_decode($app['subject_ids'], true) : [];
            $app['exam_ids'] = $app['exam_ids'] ? json_decode($app['exam_ids'], true) : [];
        }
        unset($app);

        Response::json([
            'applications' => $applications,
            'pagination'   => [
                'total'        => $total,
                'page'         => $page,
                'limit'        => $limit,
                'total_pages'  => ceil($total / $limit)
            ]
        ], 'Teacher applications loaded');
    }

    /**
     * Get single application details with full document list and user history.
     */
    public static function getApplicationDetail($appId) {
        self::requireAdmin();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT ta.*, u.full_name, u.email, u.mobile, COALESCE(s.name, 'All India') AS state, u.created_at AS user_joined_at
            FROM teacher_applications ta
            JOIN users u ON ta.user_id = u.id
            LEFT JOIN states s ON u.state_id = s.id
            WHERE ta.id = ?
        ");
        $stmt->execute([$appId]);
        $app = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            Response::error('Teacher application not found', 404);
        }

        $app['subject_ids'] = $app['subject_ids'] ? json_decode($app['subject_ids'], true) : [];
        $app['exam_ids'] = $app['exam_ids'] ? json_decode($app['exam_ids'], true) : [];

        // Load document list
        $docStmt = $db->prepare("
            SELECT id, document_type, document_subtype, document_side, original_name,
                   mime_type, file_size, verification_status, reviewer_note, uploaded_at, verified_at
            FROM teacher_documents
            WHERE application_id = ?
            ORDER BY id ASC
        ");
        $docStmt->execute([$appId]);
        $app['documents'] = $docStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json($app, 'Application detail loaded');
    }

    /**
     * Authenticated secure document streaming for KYC files.
     */
    public static function viewDocument($docId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM teacher_documents WHERE id = ?");
        $stmt->execute([$docId]);
        $doc = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$doc) {
            Response::error('Document not found', 404);
        }

        $filePath = __DIR__ . '/../../storage/teacher_docs/' . $doc['storage_key'];
        if (!file_exists($filePath)) {
            Response::error('Document file not found on disk', 404);
        }

        // Audit log document view
        $audit = $db->prepare("
            INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, details)
            VALUES (?, 'VIEW_TEACHER_KYC_DOCUMENT', 'teacher_documents', ?, ?)
        ");
        $audit->execute([$adminId, $docId, json_encode(['doc_type' => $doc['document_type'], 'app_id' => $doc['application_id']])]);

        // Stream file securely with correct MIME headers
        header('Content-Type: ' . $doc['mime_type']);
        header('Content-Length: ' . filesize($filePath));
        header('Content-Disposition: inline; filename="' . addslashes($doc['original_name']) . '"');
        header('Cache-Control: private, max-age=0, must-revalidate');
        header('Pragma: public');
        readfile($filePath);
        exit;
    }

    /**
     * Update verification status of an individual KYC document.
     */
    public static function updateDocumentStatus($docId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $rawStatus = $input['status'] ?? $input['verification_status'] ?? '';
        $status = in_array($rawStatus, ['verified', 'invalid', 'unclear', 'reupload_required'], true)
            ? $rawStatus
            : 'verified';
        $note = trim($input['reviewer_note'] ?? '');

        $stmt = $db->prepare("
            UPDATE teacher_documents
            SET verification_status = ?, reviewer_id = ?, reviewer_note = ?, verified_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$status, $adminId, $note, $docId]);

        Response::json(['document_id' => $docId, 'status' => $status], 'Document status updated');
    }

    /**
     * Request changes from applicant for specific documents/fields.
     */
    public static function requestChanges($appId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $reasonCode = trim($input['reason_code'] ?? 'DOCUMENTS_REQUIRED');
        $message    = trim($input['message'] ?? 'Please provide clearer or updated documents.');
        $docIds     = isset($input['document_ids']) && is_array($input['document_ids']) ? $input['document_ids'] : [];

        $appStmt = $db->prepare("SELECT * FROM teacher_applications WHERE id = ?");
        $appStmt->execute([$appId]);
        $app = $appStmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            Response::error('Application not found', 404);
        }

        // Asking for changes only makes sense while a decision is still open.
        // On a settled application it would leave the candidate's privileges
        // and their application state disagreeing.
        if (in_array($app['status'], ['approved', 'rejected', 'withdrawn'], true)) {
            Response::error(
                "This application is already {$app['status']}. Reopen it before requesting changes.",
                409
            );
        }

        $db->beginTransaction();
        try {
            // Update application status
            $upApp = $db->prepare("
                UPDATE teacher_applications
                SET status = 'changes_required',
                    assigned_reviewer_id = ?,
                    decision_reason_code = ?,
                    reviewer_message = ?,
                    reviewed_at = NOW()
                WHERE id = ?
            ");
            $upApp->execute([$adminId, $reasonCode, $message, $appId]);

            // Mark specified documents as reupload_required
            if (!empty($docIds)) {
                $inQuery = implode(',', array_fill(0, count($docIds), '?'));
                $upDoc = $db->prepare("
                    UPDATE teacher_documents
                    SET verification_status = 'reupload_required', reviewer_id = ?, reviewer_note = ?
                    WHERE id IN ($inQuery) AND application_id = ?
                ");
                $params = array_merge([$adminId, $message], $docIds, [$appId]);
                $upDoc->execute($params);
            }

            // Notification
            $notif = $db->prepare("
                INSERT INTO user_notifications (user_id, title, message, type)
                VALUES (?, 'Teacher Application: Action Required', ?, 'teacher_application')
            ");
            $notif->execute([$app['user_id'], "Changes required for your teacher application: $message"]);

            // Audit
            $audit = $db->prepare("
                INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, details)
                VALUES (?, 'TEACHER_APPLICATION_REQUEST_CHANGES', 'teacher_applications', ?, ?)
            ");
            $audit->execute([$adminId, $appId, json_encode(['reason' => $reasonCode, 'message' => $message, 'doc_ids' => $docIds])]);

            $db->commit();
            Response::json(['application_id' => $appId, 'status' => 'changes_required'], 'Changes requested from teacher applicant');
        } catch (Exception $e) {
            $db->rollBack();
            Response::error('Failed to request changes: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Reject teacher application.
     */
    public static function reject($appId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $reasonCode = trim($input['reason_code'] ?? 'INELIGIBLE');
        $message    = trim($input['message'] ?? 'Your teacher application could not be approved.');

        $appStmt = $db->prepare("SELECT * FROM teacher_applications WHERE id = ?");
        $appStmt->execute([$appId]);
        $app = $appStmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            Response::error('Application not found', 404);
        }

        if ($app['status'] === 'rejected') {
            Response::json(['application_id' => $appId, 'status' => 'rejected'], 'Application is already rejected');
            return;
        }

        // Rejecting an application that was previously approved has to take the
        // privilege back with it, otherwise the teacher keeps authoring rights
        // after their verification has been revoked.
        $wasApproved = ($app['status'] === 'approved');

        $db->beginTransaction();
        try {
            $upApp = $db->prepare("
                UPDATE teacher_applications
                SET status = 'rejected',
                    assigned_reviewer_id = ?,
                    decision_reason_code = ?,
                    reviewer_message = ?,
                    reviewed_at = NOW()
                WHERE id = ?
            ");
            $upApp->execute([$adminId, $reasonCode, $message, $appId]);

            if ($wasApproved) {
                $db->prepare("UPDATE users SET user_type = 'student' WHERE id = ? AND user_type = 'teacher'")
                   ->execute([$app['user_id']]);
                $db->prepare("UPDATE teacher_profiles SET status = 'suspended' WHERE user_id = ?")
                   ->execute([$app['user_id']]);
            }

            $notif = $db->prepare("
                INSERT INTO user_notifications (user_id, title, message, type)
                VALUES (?, 'Teacher Application Update', ?, 'teacher_application')
            ");
            $notif->execute([$app['user_id'], "Your teacher application has been rejected. Reason: $message"]);

            $audit = $db->prepare("
                INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, details)
                VALUES (?, 'TEACHER_APPLICATION_REJECT', 'teacher_applications', ?, ?)
            ");
            $audit->execute([$adminId, $appId, json_encode(['reason' => $reasonCode, 'message' => $message])]);

            $db->commit();
            Response::json(['application_id' => $appId, 'status' => 'rejected'], 'Teacher application rejected');
        } catch (Exception $e) {
            $db->rollBack();
            Response::error('Failed to reject application: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Atomically approve teacher application:
     * 1. Check mandatory documents are verified
     * 2. Set application status -> 'approved'
     * 3. Set users.user_type -> 'teacher'
     * 4. Upsert active teacher_profiles
     * 5. Audit log + Notification
     */
    public static function approve($appId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $note = trim($input['review_note'] ?? 'Application and credentials approved.');

        $appStmt = $db->prepare("SELECT * FROM teacher_applications WHERE id = ?");
        $appStmt->execute([$appId]);
        $app = $appStmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            Response::error('Application not found', 404);
        }

        if ($app['status'] === 'approved') {
            Response::json(['application_id' => $appId, 'status' => 'approved'], 'Application is already approved');
            return;
        }

        // An application the candidate never submitted has not passed the
        // declaration step and may still be half-filled, so it is not
        // approvable however it is reached.
        $reviewable = ['submitted', 'under_review', 'changes_required'];
        if (!in_array($app['status'], $reviewable, true)) {
            Response::error(
                "This application is still in '{$app['status']}' state. Only an application the teacher has submitted can be approved.",
                409
            );
        }

        // Mandatory documents must exist. Approving with none on file would
        // hand out teacher privileges with no identity or qualification
        // evidence at all.
        $docStmt = $db->prepare("
            SELECT document_type, verification_status FROM teacher_documents
            WHERE application_id = ?
        ");
        $docStmt->execute([$appId]);
        $docs = $docStmt->fetchAll(PDO::FETCH_ASSOC);

        // verification_status enumerates pending, verified, invalid, unclear and
        // reupload_required: the last three mean the file cannot stand as proof.
        $unusable = ['invalid', 'reupload_required'];
        $present = [];
        foreach ($docs as $d) {
            if (!in_array($d['verification_status'], $unusable, true)) {
                $present[$d['document_type']] = true;
            }
        }

        $missing = [];
        foreach (['identity', 'qualification'] as $required) {
            if (empty($present[$required])) $missing[] = $required;
        }
        if ($missing) {
            Response::error(
                'Cannot approve: the teacher has not uploaded ' . implode(' and ', $missing)
                . ' ' . (count($missing) === 1 ? 'proof' : 'proofs')
                . '. Use "request changes" to ask for the missing document.',
                422
            );
        }

        // Clicking approve on a reviewed application is the act of accepting
        // the documents attached to it, so anything still pending is marked
        // verified against this reviewer.
        $upDocs = $db->prepare("
            UPDATE teacher_documents
            SET verification_status = 'verified', reviewer_id = ?, verified_at = NOW()
            WHERE application_id = ? AND verification_status = 'pending'
        ");
        $upDocs->execute([$adminId, $appId]);

        $userId = $app['user_id'];

        $db->beginTransaction();
        try {
            // 1. Update application status
            $upApp = $db->prepare("
                UPDATE teacher_applications
                SET status = 'approved',
                    assigned_reviewer_id = ?,
                    reviewer_message = ?,
                    approved_at = NOW(),
                    reviewed_at = NOW()
                WHERE id = ?
            ");
            $upApp->execute([$adminId, $note, $appId]);

            // 2. Set user role to teacher
            $upUser = $db->prepare("UPDATE users SET user_type = 'teacher' WHERE id = ?");
            $upUser->execute([$userId]);

            // 3. Upsert teacher profile
            $userStmt = $db->prepare("SELECT full_name FROM users WHERE id = ?");
            $userStmt->execute([$userId]);
            $userName = $userStmt->fetchColumn() ?: 'Faculty Teacher';

            $qualification = trim(($app['highest_qualification'] ?? '') . ' ' . ($app['degree_name'] ?? ''));
            $specialisation = $app['specialization'] ?? '';
            $institution = $app['institution_name'] ?? '';
            $bio = $qualification . ($institution ? " ($institution)" : '');

            $upProf = $db->prepare("
                INSERT INTO teacher_profiles (user_id, display_name, qualification, specialisation, bio, status)
                VALUES (?, ?, ?, ?, ?, 'active')
                ON DUPLICATE KEY UPDATE
                    display_name = VALUES(display_name),
                    qualification = VALUES(qualification),
                    specialisation = VALUES(specialisation),
                    bio = VALUES(bio),
                    status = 'active'
            ");
            $upProf->execute([$userId, $userName, $qualification, $specialisation, $bio]);

            // 4. Send notification
            $notif = $db->prepare("
                INSERT INTO user_notifications (user_id, title, message, type)
                VALUES (?, '🎉 Congratulations! You are now a Verified Teacher', 'Your teacher verification application has been approved. Teacher Mode is now unlocked in your app profile!', 'teacher_approval')
            ");
            $notif->execute([$userId]);

            // 5. Audit log
            $audit = $db->prepare("
                INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, details)
                VALUES (?, 'TEACHER_APPLICATION_APPROVE', 'teacher_applications', ?, ?)
            ");
            $audit->execute([$adminId, $appId, json_encode(['note' => $note, 'user_id' => $userId])]);

            $db->commit();

            Response::json([
                'application_id' => $appId,
                'user_id'        => $userId,
                'status'         => 'approved'
            ], 'Teacher application approved and privileges activated');
        } catch (Exception $e) {
            $db->rollBack();
            Response::error('Failed to approve application: ' . $e->getMessage(), 500);
        }
    }
}
