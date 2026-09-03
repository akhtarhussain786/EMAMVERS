<?php
/**
 * Duplicate detection for the question bank.
 *
 * Two fingerprints per question:
 *   contentHash   — normalised text. Catches literal re-insertion.
 *   structureHash — normalised text with every number replaced by a marker.
 *                   Catches reworded clones.
 *
 * A question is only a duplicate when BOTH hashes match. That distinction
 * matters for Quantitative Aptitude: "A finishes in 12 days" and "A finishes in
 * 15 days" share a structure hash but differ in content, and both are wanted.
 */
class QuestionFingerprint {

    /** Lowercases, strips punctuation and collapses whitespace. */
    public static function normalise($text) {
        $t = mb_strtolower(trim((string)$text));
        $t = preg_replace('/[\p{P}\p{S}]+/u', ' ', $t);   // punctuation & symbols
        $t = preg_replace('/\s+/u', ' ', $t);
        return trim($t);
    }

    /** Exact-content fingerprint over the question and its options. */
    public static function contentHash($questionText, array $optionTexts = []) {
        $parts = [self::normalise($questionText)];
        // Options are sorted so a reordered set is still recognised as the same.
        $opts = array_map([self::class, 'normalise'], $optionTexts);
        sort($opts);
        return hash('sha256', implode('|', array_merge($parts, $opts)));
    }

    /** Structural fingerprint: same as above with digits masked. */
    public static function structureHash($questionText, array $optionTexts = []) {
        $mask = function ($s) {
            return preg_replace('/\d+(?:\.\d+)?/', '#', self::normalise($s));
        };
        $parts = [$mask($questionText)];
        $opts = array_map($mask, $optionTexts);
        sort($opts);
        return hash('sha256', implode('|', array_merge($parts, $opts)));
    }

    /**
     * Looks for an existing question with the same content hash.
     * Returns the clashing question id, or null.
     */
    public static function findDuplicate($db, $contentHash, $excludeId = null) {
        $sql = "SELECT id FROM questions WHERE content_hash = ? AND status <> 'rejected'";
        $params = [$contentHash];
        if ($excludeId) { $sql .= " AND id <> ?"; $params[] = $excludeId; }
        $sql .= " LIMIT 1";

        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $id = $stmt->fetchColumn();
        return $id === false ? null : (int)$id;
    }

    /**
     * Counts existing questions sharing a structure hash. Used to stop the AI
     * job flooding the bank with fifty variants of one template.
     */
    public static function countSameStructure($db, $structureHash) {
        $stmt = $db->prepare("SELECT COUNT(*) FROM questions WHERE structure_hash = ? AND status <> 'rejected'");
        $stmt->execute([$structureHash]);
        return (int)$stmt->fetchColumn();
    }

    /** Computes and persists both hashes for a question. */
    public static function store($db, $questionId, $questionText, array $optionTexts) {
        $db->prepare("UPDATE questions SET content_hash = ?, structure_hash = ? WHERE id = ?")
           ->execute([
               self::contentHash($questionText, $optionTexts),
               self::structureHash($questionText, $optionTexts),
               $questionId,
           ]);
    }
}
