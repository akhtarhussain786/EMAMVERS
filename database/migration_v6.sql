-- ============================================================================
-- EXAMVERSE migration v6 — integrity + security fixes
--
-- Adds the UNIQUE constraints that existing ON DUPLICATE KEY / INSERT IGNORE
-- statements silently depended on, widens columns that now hold hashes, and
-- adds the map-progress counters and contact-matching hash.
--
-- Safe to re-run: run_migration_v6.php skips objects that already exist.
-- ============================================================================

-- 1. exam_twin_snapshots: the readiness upsert keys on (user_id, exam_id).
--    Without this, every submission inserted a new snapshot row.
ALTER TABLE `exam_twin_snapshots`
    ADD UNIQUE KEY `user_exam_snapshot` (`user_id`, `exam_id`);

-- 2. user_contacts: INSERT IGNORE / ON DUPLICATE KEY needs a real constraint,
--    otherwise repeated contact syncs duplicate every friend.
ALTER TABLE `user_contacts`
    ADD UNIQUE KEY `user_contact_hash` (`user_id`, `contact_phone_hash`);

-- 3. mistake_notebook: one row per (user, question) so re-adding updates.
ALTER TABLE `mistake_notebook`
    ADD UNIQUE KEY `user_question_mistake` (`user_id`, `question_id`);

-- 4. OTPs are now stored as a 64-char HMAC, not a 6-char plaintext code.
ALTER TABLE `user_otps`
    MODIFY COLUMN `otp_code` VARCHAR(64) NOT NULL;

ALTER TABLE `user_otps`
    ADD INDEX `idx_otp_lookup` (`mobile_or_email`, `is_used`, `expires_at`);

-- 5. Privacy-preserving contact matching: SHA-256 of the last 10 digits.
ALTER TABLE `users`
    ADD COLUMN `mobile_hash` CHAR(64) NULL AFTER `mobile`;

ALTER TABLE `users`
    ADD INDEX `idx_users_mobile_hash` (`mobile_hash`);

-- Backfill for existing rows. Placeholder numbers (fewer than 10 digits, or the
-- reserved 'NA-' prefix) are deliberately left NULL so they never match.
UPDATE `users`
SET `mobile_hash` = SHA2(RIGHT(REGEXP_REPLACE(`mobile`, '[^0-9]', ''), 10), 256)
WHERE `mobile` NOT LIKE 'NA-%'
  AND CHAR_LENGTH(REGEXP_REPLACE(`mobile`, '[^0-9]', '')) >= 10;

-- 6. Map quiz progress counters used by MapController::recordProgress.
ALTER TABLE `map_user_progress`
    ADD COLUMN `correct_attempts` INT NOT NULL DEFAULT 0 AFTER `quiz_score`;

ALTER TABLE `map_user_progress`
    ADD COLUMN `total_attempts` INT NOT NULL DEFAULT 0 AFTER `correct_attempts`;

-- 7. Indexes for the hot paths: leaderboard/rank scans and answer lookups.
ALTER TABLE `test_attempts`
    ADD INDEX `idx_attempts_ranking` (`test_id`, `status`, `score`);

ALTER TABLE `test_attempts`
    ADD INDEX `idx_attempts_user_status` (`user_id`, `status`);

ALTER TABLE `question_options`
    ADD INDEX `idx_options_question_correct` (`question_id`, `is_correct`);

-- 8. study_materials.file_path now holds a bare filename inside storage/materials,
--    not a web-reachable path. Rewrite any legacy values.
UPDATE `study_materials`
SET `file_path` = SUBSTRING_INDEX(`file_path`, '/', -1)
WHERE `file_path` LIKE 'uploads/%';
