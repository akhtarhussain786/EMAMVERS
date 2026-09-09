<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

/**
 * Teacher KYC Application Controller.
 * Manages the student self-application lifecycle (PRD §15):
 * Draft -> Document Uploads -> Final Submission -> Review Tracking.
 */
class TeacherApplicationController {

    private static $allowedMimes = [
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp'
    ];
    private static $maxFileSize = 5242880; // 5 MB per file

    /**
     * Get the current user's active/latest teacher application with uploaded documents.
     */
    public static function getApplication() {
        $auth = AuthMiddleware::getAuthenticatedUser();
        $userId = $auth['sub'];
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT * FROM teacher_applications
            WHERE user_id = ?
            ORDER BY id DESC LIMIT 1
        ");
        $stmt->execute([$userId]);
        $app = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            Response::json(null, 'No teacher application found');
            return;
        }

        // Decode JSON arrays if present
        $app['subject_ids'] = $app['subject_ids'] ? json_decode($app['subject_ids'], true) : [];
        $app['exam_ids'] = $app['exam_ids'] ? json_decode($app['exam_ids'], true) : [];

        // Fetch documents
        $docStmt = $db->prepare("
            SELECT id, document_type, document_subtype, document_side, original_name,
                   mime_type, file_size, verification_status, reviewer_note, uploaded_at, verified_at
            FROM teacher_documents
            WHERE application_id = ?
            ORDER BY id ASC
        ");
        $docStmt->execute([$app['id']]);
        $app['documents'] = $docStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json($app, 'Teacher application loaded');
    }

    /**
     * Create or update draft teacher application.
     */
    public static function saveDraft() {
        $auth = AuthMiddleware::getAuthenticatedUser();
        $userId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $highestQualification = trim($input['highest_qualification'] ?? '');
        $degreeName          = trim($input['degree_name'] ?? '');
        $specialization      = trim($input['specialization'] ?? '');
        $institutionName     = trim($input['institution_name'] ?? '');
        $passingYear         = intval($input['passing_year'] ?? 0);
        $scoreValue          = isset($input['score_value']) ? floatval($input['score_value']) : null;
        $scoreType           = in_array($input['score_type'] ?? '', ['percentage', 'cgpa', 'grade'], true) ? $input['score_type'] : 'percentage';
        $experienceYears     = floatval($input['experience_years'] ?? 0.0);
        $currentOrganization = trim($input['current_organization'] ?? '');
        $preferredLanguages  = trim($input['preferred_languages'] ?? '');
        $subjectIds          = isset($input['subject_ids']) && is_array($input['subject_ids']) ? json_encode(array_values(array_map('intval', $input['subject_ids']))) : null;
        $examIds             = isset($input['exam_ids']) && is_array($input['exam_ids']) ? json_encode(array_values(array_map('intval', $input['exam_ids']))) : null;

        // Check for existing application
        $checkStmt = $db->prepare("SELECT * FROM teacher_applications WHERE user_id = ? ORDER BY id DESC LIMIT 1");
        $checkStmt->execute([$userId]);
        $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

        if ($existing && !in_array($existing['status'], ['draft', 'changes_required'], true)) {
            Response::error('Cannot modify application while it is ' . $existing['status'], 400);
        }

        if ($existing) {
            $updateStmt = $db->prepare("
                UPDATE teacher_applications
                SET highest_qualification = ?, degree_name = ?, specialization = ?,
                    institution_name = ?, passing_year = ?, score_value = ?, score_type = ?,
                    experience_years = ?, current_organization = ?, preferred_languages = ?,
                    subject_ids = ?, exam_ids = ?
                WHERE id = ?
            ");
            $updateStmt->execute([
                $highestQualification ?: $existing['highest_qualification'],
                $degreeName ?: $existing['degree_name'],
                $specialization,
                $institutionName ?: $existing['institution_name'],
                $passingYear > 0 ? $passingYear : $existing['passing_year'],
                $scoreValue !== null ? $scoreValue : $existing['score_value'],
                $scoreType,
                $experienceYears,
                $currentOrganization,
                $preferredLanguages,
                $subjectIds,
                $examIds,
                $existing['id']
            ]);

            Response::json([
                'application_id' => $existing['id'],
                'application_no' => $existing['application_no'],
                'status'         => $existing['status']
            ], 'Draft updated successfully');
        } else {
            $appNo = 'TCH-' . date('Y') . '-' . strtoupper(bin2hex(random_bytes(3)));
            $insertStmt = $db->prepare("
                INSERT INTO teacher_applications (
                    application_no, user_id, highest_qualification, degree_name,
                    specialization, institution_name, passing_year, score_value,
                    score_type, experience_years, current_organization, preferred_languages,
                    subject_ids, exam_ids, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'draft')
            ");
            $insertStmt->execute([
                $appNo,
                $userId,
                $highestQualification ?: 'Bachelor Degree',
                $degreeName ?: 'General',
                $specialization,
                $institutionName ?: 'University',
                $passingYear > 0 ? $passingYear : date('Y'),
                $scoreValue,
                $scoreType,
                $experienceYears,
                $currentOrganization,
                $preferredLanguages,
                $subjectIds,
                $examIds
            ]);

            $newId = (int)$db->lastInsertId();
            Response::json([
                'application_id' => $newId,
                'application_no' => $appNo,
                'status'         => 'draft'
            ], 'Draft created successfully', 201);
        }
    }

    /**
     * Upload a KYC verification document.
     */
    public static function uploadDocument() {
        $auth = AuthMiddleware::getAuthenticatedUser();
        $userId = $auth['sub'];
        $db = Database::getConnection();

        if (empty($_FILES['document']) || $_FILES['document']['error'] !== UPLOAD_ERR_OK) {
            Response::error('No valid file uploaded or upload error occurred', 400);
        }

        $file = $_FILES['document'];
        $docType = in_array($_POST['document_type'] ?? '', ['identity', 'qualification', 'experience', 'resume', 'certification'], true)
            ? $_POST['document_type']
            : 'qualification';
        $docSubtype = trim($_POST['document_subtype'] ?? '');
        $docSide = in_array($_POST['document_side'] ?? '', ['front', 'back', 'single'], true) ? $_POST['document_side'] : 'single';

        if ($file['size'] > self::$maxFileSize) {
            Response::error('File size exceeds 5MB limit', 400);
        }

        // Validate real MIME type using finfo
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file['tmp_name']);
        if (!in_array($mime, self::$allowedMimes, true)) {
            Response::error('Invalid file type. Only PDF, JPG, PNG, and WEBP files are allowed.', 400);
        }

        // Fetch or create draft application
        $appStmt = $db->prepare("SELECT * FROM teacher_applications WHERE user_id = ? ORDER BY id DESC LIMIT 1");
        $appStmt->execute([$userId]);
        $app = $appStmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            // Auto-create draft application shell
            $appNo = 'TCH-' . date('Y') . '-' . strtoupper(bin2hex(random_bytes(3)));
            $insApp = $db->prepare("
                INSERT INTO teacher_applications (application_no, user_id, highest_qualification, degree_name, institution_name, passing_year, status)
                VALUES (?, ?, 'Pending', 'Pending', 'Pending', ?, 'draft')
            ");
            $insApp->execute([$appNo, $userId, date('Y')]);
            $appId = (int)$db->lastInsertId();
        } else {
            $appId = (int)$app['id'];
            if (!in_array($app['status'], ['draft', 'changes_required'], true)) {
                Response::error('Cannot upload documents for application in status ' . $app['status'], 400);
            }
        }

        // Ensure private storage directory exists
        $storageDir = __DIR__ . '/../../storage/teacher_docs';
        if (!is_dir($storageDir)) {
            mkdir($storageDir, 0755, true);
        }

        $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
        $randomKey = bin2hex(random_bytes(24)) . ($extension ? '.' . strtolower($extension) : '');
        $destination = $storageDir . '/' . $randomKey;

        if (!move_uploaded_file($file['tmp_name'], $destination)) {
            Response::error('Failed to securely store document', 500);
        }

        $checksum = hash_file('sha256', $destination);

        $insDoc = $db->prepare("
            INSERT INTO teacher_documents (
                application_id, user_id, document_type, document_subtype,
                document_side, storage_key, original_name, mime_type,
                file_size, checksum, verification_status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
        ");
        $insDoc->execute([
            $appId,
            $userId,
            $docType,
            $docSubtype,
            $docSide,
            $randomKey,
            basename($file['name']),
            $mime,
            $file['size'],
            $checksum
        ]);

        $docId = (int)$db->lastInsertId();

        Response::json([
            'document_id'         => $docId,
            'application_id'      => $appId,
            'document_type'       => $docType,
            'display_name'        => basename($file['name']),
            'file_size'           => $file['size'],
            'verification_status' => 'pending'
        ], 'Document uploaded successfully', 201);
    }

    /**
     * Submit application for administrative verification.
     */
    public static function submitApplication() {
        $auth = AuthMiddleware::getAuthenticatedUser();
        $userId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $declaration = !empty($input['declaration_accepted']);

        if (!$declaration) {
            Response::error('You must accept the truthfulness and copyright declaration to submit your application', 422);
        }

        $appStmt = $db->prepare("SELECT * FROM teacher_applications WHERE user_id = ? ORDER BY id DESC LIMIT 1");
        $appStmt->execute([$userId]);
        $app = $appStmt->fetch(PDO::FETCH_ASSOC);

        if (!$app) {
            Response::error('No application found to submit', 404);
        }

        if (!in_array($app['status'], ['draft', 'changes_required'], true)) {
            Response::error('Application has already been submitted', 400);
        }

        // Validate mandatory documents
        $docStmt = $db->prepare("SELECT document_type FROM teacher_documents WHERE application_id = ?");
        $docStmt->execute([$app['id']]);
        $docs = $docStmt->fetchAll(PDO::FETCH_COLUMN);

        $hasIdentity = in_array('identity', $docs, true);
        $hasQualification = in_array('qualification', $docs, true);

        if (!$hasIdentity || !$hasQualification) {
            Response::error('Mandatory documents missing: Both Government Identity Proof and Qualification Proof are required before submitting.', 422);
        }

        $update = $db->prepare("
            UPDATE teacher_applications
            SET status = 'submitted',
                declaration_accepted = 1,
                declaration_timestamp = NOW(),
                submitted_at = NOW(),
                reviewer_message = NULL
            WHERE id = ?
        ");
        $update->execute([$app['id']]);

        // Send in-app notification
        $notif = $db->prepare("
            INSERT INTO user_notifications (user_id, title, message, type)
            VALUES (?, 'Teacher Application Submitted', 'Your teacher verification application has been submitted for review. You will be notified once reviewed.', 'teacher_application')
        ");
        $notif->execute([$userId]);

        Response::json([
            'application_no' => $app['application_no'],
            'status'         => 'submitted',
            'submitted_at'   => date('c')
        ], 'Teacher application submitted for verification');
    }
}
