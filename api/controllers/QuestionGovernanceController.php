<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../utils/question_fingerprint.php';

/**
 * Question Bank Governance & Duplicate Prevention Controller.
 * PRD §16: Canonical identity, candidate comparison, conflict resolution,
 * question dispute reports, and immutable revisions.
 */
class QuestionGovernanceController {

    private static function requireAdmin() {
        AuthMiddleware::getAuthenticatedUser('admin');
    }

    /**
     * Fetch duplicate candidates and candidate diffs for a question.
     */
    public static function getDuplicateCandidates($questionId) {
        self::requireAdmin();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT q.*, s.name AS subject_name, t.name AS topic_name
            FROM questions q
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN topics t ON q.topic_id = t.id
            WHERE q.id = ?
        ");
        $stmt->execute([$questionId]);
        $target = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$target) {
            Response::error('Question not found', 404);
        }

        // Fetch question text from translations if not in main row
        $txtStmt = $db->prepare("SELECT question_text FROM question_translations WHERE question_id = ? LIMIT 1");
        $txtStmt->execute([$questionId]);
        $qText = $txtStmt->fetchColumn() ?: ($target['question_text'] ?? 'Sample stem');
        $target['question_text'] = $qText;

        // Compute fingerprint hashes if not already present
        if (empty($target['content_hash']) || empty($target['structure_hash'])) {
            $cHash = QuestionFingerprint::contentHash($qText);
            $sHash = QuestionFingerprint::structureHash($qText);
            $target['content_hash'] = $cHash;
            $target['structure_hash'] = $sHash;

            $upStmt = $db->prepare("UPDATE questions SET content_hash = ?, structure_hash = ? WHERE id = ?");
            $upStmt->execute([$cHash, $sHash, $questionId]);
        }

        // Find exact matches and structure/near-duplicate matches
        $dupStmt = $db->prepare("
            SELECT q.*, s.name AS subject_name, t.name AS topic_name,
                   CASE
                       WHEN q.content_hash = ? THEN 'exact_hash'
                       WHEN q.structure_hash = ? THEN 'structure_hash'
                       ELSE 'fuzzy_similarity'
                   END AS match_method,
                   CASE
                       WHEN q.content_hash = ? THEN 100.00
                       WHEN q.structure_hash = ? THEN 85.00
                       ELSE 70.00
                   END AS similarity_score
            FROM questions q
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN topics t ON q.topic_id = t.id
            WHERE q.id != ? AND (q.content_hash = ? OR q.structure_hash = ?)
            ORDER BY similarity_score DESC
            LIMIT 20
        ");
        $dupStmt->execute([
            $target['content_hash'], $target['structure_hash'],
            $target['content_hash'], $target['structure_hash'],
            $questionId,
            $target['content_hash'], $target['structure_hash']
        ]);
        $candidates = $dupStmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch recorded decisions
        $decStmt = $db->prepare("
            SELECT * FROM question_duplicate_candidates
            WHERE question_a_id = ? OR question_b_id = ?
        ");
        $decStmt->execute([$questionId, $questionId]);
        $decisions = $decStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json([
            'target_question' => $target,
            'candidates'      => $candidates,
            'decisions'       => $decisions
        ], 'Duplicate candidates loaded');
    }

    /**
     * Record a human reviewer decision on a duplicate candidate pair.
     */
    public static function recordDuplicateDecision($candidatePairId = null) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $questionA = intval($input['question_a_id'] ?? 0);
        $questionB = intval($input['question_b_id'] ?? 0);
        $decision  = in_array($input['decision'] ?? '', [
            'not_duplicate', 'exact_duplicate', 'near_duplicate',
            'translation_pair', 'intentional_variant', 'replace_canonical',
            'merge_cluster', 'conflict_escalate'
        ], true) ? $input['decision'] : 'not_duplicate';
        $reason = trim($input['decision_reason'] ?? '');

        if (!$questionA || !$questionB) {
            Response::error('question_a_id and question_b_id are required', 400);
        }

        // Normalize order so question_a_id < question_b_id
        if ($questionA > $questionB) {
            $temp = $questionA;
            $questionA = $questionB;
            $questionB = $temp;
        }

        $stmt = $db->prepare("
            INSERT INTO question_duplicate_candidates (
                question_a_id, question_b_id, match_method, similarity_score,
                status, decision, decision_reason, decided_by, decided_at
            ) VALUES (?, ?, 'manual_review', 100.00, 'resolved', ?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE
                decision = VALUES(decision),
                decision_reason = VALUES(decision_reason),
                status = 'resolved',
                decided_by = VALUES(decided_by),
                decided_at = NOW()
        ");
        $stmt->execute([$questionA, $questionB, $decision, $reason, $adminId]);

        // If exact_duplicate or conflict, handle status
        if ($decision === 'exact_duplicate') {
            // Mark question B as duplicate/unpublished
            $up = $db->prepare("UPDATE questions SET status = 'unpublished' WHERE id = ?");
            $up->execute([$questionB]);
        }

        // Audit log
        $audit = $db->prepare("
            INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, details)
            VALUES (?, 'QUESTION_DUPLICATE_DECISION', 'questions', ?, ?)
        ");
        $audit->execute([$adminId, $questionA, json_encode([
            'pair' => [$questionA, $questionB],
            'decision' => $decision,
            'reason' => $reason
        ])]);

        Response::json([
            'question_a_id' => $questionA,
            'question_b_id' => $questionB,
            'decision'      => $decision,
            'status'        => 'resolved'
        ], 'Duplicate decision persisted');
    }

    /**
     * Submit a student question dispute / report.
     */
    public static function submitReport($questionId) {
        $auth = AuthMiddleware::getAuthenticatedUser();
        $userId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $reason = in_array($input['report_reason'] ?? '', [
            'wrong_answer', 'multiple_correct', 'no_correct_option',
            'explanation_conflict', 'typo', 'duplicate', 'outdated',
            'wrong_taxonomy', 'broken_image', 'other'
        ], true) ? $input['report_reason'] : 'wrong_answer';
        $notes = trim($input['report_notes'] ?? '');

        // Check for duplicate recent report from same user
        $chk = $db->prepare("
            SELECT id FROM question_reports
            WHERE question_id = ? AND user_id = ? AND status = 'pending'
        ");
        $chk->execute([$questionId, $userId]);
        if ($chk->fetch()) {
            Response::json(['message' => 'Your report for this question is already under review'], 'Report received');
            return;
        }

        $ins = $db->prepare("
            INSERT INTO question_reports (question_id, user_id, report_reason, report_notes, status)
            VALUES (?, ?, ?, ?, 'pending')
        ");
        $ins->execute([$questionId, $userId, $reason, $notes]);

        Response::json(['report_id' => (int)$db->lastInsertId()], 'Thank you for reporting. Our content team will review this question.', 201);
    }

    /**
     * List student question dispute reports for moderation.
     */
    public static function listReports() {
        self::requireAdmin();
        $db = Database::getConnection();

        $status = $_GET['status'] ?? 'pending';
        $where = "1=1";
        $params = [];
        if ($status !== 'all') {
            $where .= " AND qr.status = ?";
            $params[] = $status;
        }

        $stmt = $db->prepare("
            SELECT qr.*, COALESCE(qt.question_text, 'Question text unavailable') AS question_text,
                   COALESCE(qt.solution_text, '') AS explanation, q.status AS question_status,
                   u.full_name AS reporter_name, u.email AS reporter_email,
                   s.name AS subject_name
            FROM question_reports qr
            JOIN questions q ON qr.question_id = q.id
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            JOIN users u ON qr.user_id = u.id
            LEFT JOIN subjects s ON q.subject_id = s.id
            WHERE $where
            ORDER BY qr.created_at DESC
            LIMIT 50
        ");
        $stmt->execute($params);
        $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json(['reports' => $reports], 'Question reports loaded');
    }

    /**
     * Resolve a question report.
     */
    public static function resolveReport($reportId) {
        $auth = AuthMiddleware::getAuthenticatedUser('admin');
        $adminId = $auth['sub'];
        $db = Database::getConnection();

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $action = trim($input['resolution_action'] ?? 'dismissed');
        $note   = trim($input['resolution_note'] ?? 'Report reviewed by moderator');
        $status = in_array($input['status'] ?? '', ['resolved', 'dismissed'], true) ? $input['status'] : 'resolved';

        $stmt = $db->prepare("
            UPDATE question_reports
            SET status = ?, resolution_action = ?, resolution_note = ?, resolved_by = ?, resolved_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$status, $action, $note, $adminId, $reportId]);

        Response::json(['report_id' => $reportId, 'status' => $status], 'Report resolved');
    }
}
