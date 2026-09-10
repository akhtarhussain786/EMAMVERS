-- ============================================================================
-- EXAMVERSE migration v8 — department question banks + per-attempt papers
--
-- Two changes:
--   1. A question can belong to one or more exam "department" banks, while
--      still being tagged by subject/topic. This is what lets one Quant
--      question serve SSC and Banking at once instead of being duplicated.
--   2. Each attempt stores the exact questions drawn for it, so every student
--      gets a different randomised paper that can still be resumed and
--      reviewed afterwards.
-- ============================================================================

-- 1. Department bank membership (many-to-many: a question serves N exams).
CREATE TABLE IF NOT EXISTS `question_exams` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `question_id` INT NOT NULL,
    `exam_id` INT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `question_exam_unique` (`question_id`, `exam_id`),
    KEY `idx_qe_exam` (`exam_id`),
    FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. The paper actually served to one attempt.
--    option_order stores the shuffled A/B/C/D sequence so a resumed test shows
--    options in the same positions the candidate first saw.
CREATE TABLE IF NOT EXISTS `attempt_questions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `attempt_id` INT NOT NULL,
    `question_id` INT NOT NULL,
    `question_order` INT NOT NULL,
    `section_id` INT NULL,
    `positive_marks` DECIMAL(5,2) NOT NULL DEFAULT 2.00,
    `negative_marks` DECIMAL(5,2) NOT NULL DEFAULT 0.50,
    `option_order` VARCHAR(32) NULL,
    UNIQUE KEY `attempt_question_unique` (`attempt_id`, `question_id`),
    KEY `idx_aq_attempt_order` (`attempt_id`, `question_order`),
    KEY `idx_aq_question` (`question_id`),
    FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Duplicate detection.
--    content_hash  = normalised exact text  -> catches literal repeats
--    structure_hash= same, with numbers masked -> catches reworded clones,
--    while deliberately still allowing numeric variants of a Quant question
--    (same structure + DIFFERENT numbers is a new question, not a duplicate).
ALTER TABLE `questions`
    ADD COLUMN `content_hash` CHAR(64) NULL AFTER `rejection_reason`;

ALTER TABLE `questions`
    ADD COLUMN `structure_hash` CHAR(64) NULL AFTER `content_hash`;

ALTER TABLE `questions`
    ADD INDEX `idx_questions_content_hash` (`content_hash`);

ALTER TABLE `questions`
    ADD INDEX `idx_questions_structure_hash` (`structure_hash`);

-- 4. How a test was assembled, so results can distinguish a randomised paper
--    from a fixed one (a ranked challenge still needs everyone on one paper).
ALTER TABLE `test_attempts`
    ADD COLUMN `assembly_mode` ENUM('fixed','randomised') NOT NULL DEFAULT 'fixed' AFTER `pattern_version`;

-- 5. Blueprint flag: does this test draw fresh questions per attempt?
ALTER TABLE `tests`
    ADD COLUMN `is_randomised` TINYINT(1) NOT NULL DEFAULT 0 AFTER `status`;

-- 6. Draw-selection hot path: find published questions in a bucket fast.
ALTER TABLE `questions`
    ADD INDEX `idx_questions_draw` (`status`, `subject_id`, `difficulty`);

-- 7. Records each AI top-up run so bank growth is auditable.
CREATE TABLE IF NOT EXISTS `question_topup_runs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `exam_id` INT NULL,
    `subject_id` INT NULL,
    `difficulty` ENUM('easy','medium','hard') NULL,
    `requested` INT NOT NULL DEFAULT 0,
    `generated_count` INT NOT NULL DEFAULT 0,  -- not `generated`: reserved word in MySQL 8
    `duplicates_rejected` INT NOT NULL DEFAULT 0,
    `inserted` INT NOT NULL DEFAULT 0,
    `status` ENUM('running','completed','error') NOT NULL DEFAULT 'running',
    `error_message` TEXT NULL,
    `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `finished_at` DATETIME NULL,
    KEY `idx_topup_started` (`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Per-exam bank targets, so each department can size its own pool.
CREATE TABLE IF NOT EXISTS `exam_bank_targets` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `exam_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `target_per_difficulty` INT NOT NULL DEFAULT 150,
    `auto_topup` TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY `exam_subject_target` (`exam_id`, `subject_id`),
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
