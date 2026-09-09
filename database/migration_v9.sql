-- ============================================================================
-- EXAMVERSE migration v9 — PRD v3.0 Content Integrity, KYC & Governance Hardening
--
-- Modules:
--   1. Teacher Application & KYC Document Verification
--   2. Question Revisions, Canonical Clusters & Duplicate Candidates
--   3. Question Dispute Reports & Moderation Queue
--   4. Versioned Test Management & Regrade Jobs
--   5. Referral & Subscription Growth Ledger
-- ============================================================================

-- 1. Teacher KYC Applications
CREATE TABLE IF NOT EXISTS `teacher_applications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `application_no` VARCHAR(64) NOT NULL UNIQUE,
    `user_id` INT NOT NULL,
    `highest_qualification` VARCHAR(100) NOT NULL,
    `degree_name` VARCHAR(150) NOT NULL,
    `specialization` VARCHAR(150) NULL,
    `institution_name` VARCHAR(255) NOT NULL,
    `passing_year` INT NOT NULL,
    `score_value` DECIMAL(5,2) NULL,
    `score_type` ENUM('percentage', 'cgpa', 'grade') NOT NULL DEFAULT 'percentage',
    `experience_years` DECIMAL(4,1) NOT NULL DEFAULT 0.0,
    `current_organization` VARCHAR(255) NULL,
    `preferred_languages` VARCHAR(255) NULL,
    `subject_ids` JSON NULL,
    `exam_ids` JSON NULL,
    `status` ENUM('draft', 'submitted', 'under_review', 'changes_required', 'approved', 'rejected', 'withdrawn', 'suspended') NOT NULL DEFAULT 'draft',
    `assigned_reviewer_id` INT NULL,
    `decision_reason_code` VARCHAR(64) NULL,
    `reviewer_message` TEXT NULL,
    `declaration_accepted` TINYINT(1) NOT NULL DEFAULT 0,
    `declaration_timestamp` DATETIME NULL,
    `submitted_at` DATETIME NULL,
    `reviewed_at` DATETIME NULL,
    `approved_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_ta_user` (`user_id`),
    INDEX `idx_ta_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Teacher Verification Documents (Private Storage)
CREATE TABLE IF NOT EXISTS `teacher_documents` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `application_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `document_type` ENUM('identity', 'qualification', 'experience', 'resume', 'certification') NOT NULL,
    `document_subtype` VARCHAR(64) NULL,
    `document_side` ENUM('front', 'back', 'single') NOT NULL DEFAULT 'single',
    `storage_key` VARCHAR(255) NOT NULL,
    `original_name` VARCHAR(255) NOT NULL,
    `mime_type` VARCHAR(64) NOT NULL,
    `file_size` INT NOT NULL,
    `checksum` CHAR(64) NULL,
    `verification_status` ENUM('pending', 'verified', 'invalid', 'unclear', 'reupload_required') NOT NULL DEFAULT 'pending',
    `reviewer_id` INT NULL,
    `reviewer_note` TEXT NULL,
    `replaced_document_id` INT NULL,
    `uploaded_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `verified_at` DATETIME NULL,
    INDEX `idx_td_app` (`application_id`),
    INDEX `idx_td_user` (`user_id`),
    INDEX `idx_td_status` (`verification_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Immutable Question Revisions
CREATE TABLE IF NOT EXISTS `question_revisions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `question_id` INT NOT NULL,
    `revision_no` INT NOT NULL DEFAULT 1,
    `question_text` TEXT NOT NULL,
    `option_a` TEXT NOT NULL,
    `option_b` TEXT NOT NULL,
    `option_c` TEXT NOT NULL,
    `option_d` TEXT NOT NULL,
    `correct_option` VARCHAR(8) NOT NULL,
    `explanation` TEXT NULL,
    `shortcut_trick` TEXT NULL,
    `subject_id` INT NULL,
    `topic_id` INT NULL,
    `difficulty` ENUM('easy','medium','hard') NOT NULL DEFAULT 'medium',
    `language` VARCHAR(16) NOT NULL DEFAULT 'en',
    `change_reason` VARCHAR(255) NULL,
    `created_by` INT NULL,
    `moderation_status` ENUM('draft','submitted','under_review','approved','published','rejected','unpublished') NOT NULL DEFAULT 'submitted',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_qr_question` (`question_id`),
    INDEX `idx_qr_rev` (`question_id`, `revision_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Question Duplicate Clusters
CREATE TABLE IF NOT EXISTS `question_duplicate_clusters` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `canonical_question_id` INT NOT NULL,
    `cluster_name` VARCHAR(128) NULL,
    `relation_policy` VARCHAR(64) NOT NULL DEFAULT 'cluster_default',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_qdc_canonical` (`canonical_question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Question Duplicate Detection & Candidates
CREATE TABLE IF NOT EXISTS `question_duplicate_candidates` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `question_a_id` INT NOT NULL,
    `question_b_id` INT NOT NULL,
    `match_method` VARCHAR(64) NOT NULL DEFAULT 'exact_hash',
    `similarity_score` DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    `status` ENUM('pending','reviewed','resolved') NOT NULL DEFAULT 'pending',
    `decision` ENUM('not_duplicate','exact_duplicate','near_duplicate','translation_pair','intentional_variant','replace_canonical','merge_cluster','conflict_escalate') NULL,
    `decision_reason` TEXT NULL,
    `decided_by` INT NULL,
    `decided_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_dup_pair` (`question_a_id`, `question_b_id`),
    INDEX `idx_qdc_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Question Reports & Quality Disputes
CREATE TABLE IF NOT EXISTS `question_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `question_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `report_reason` ENUM('wrong_answer','multiple_correct','no_correct_option','explanation_conflict','typo','duplicate','outdated','wrong_taxonomy','broken_image','other') NOT NULL,
    `report_notes` TEXT NULL,
    `status` ENUM('pending','under_review','resolved','dismissed') NOT NULL DEFAULT 'pending',
    `resolution_action` VARCHAR(64) NULL,
    `resolution_note` TEXT NULL,
    `resolved_by` INT NULL,
    `resolved_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_qr_q_status` (`question_id`, `status`),
    INDEX `idx_qr_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Versioned Test Management
CREATE TABLE IF NOT EXISTS `test_versions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `test_id` INT NOT NULL,
    `version_no` INT NOT NULL DEFAULT 1,
    `title` VARCHAR(255) NOT NULL,
    `instructions` TEXT NULL,
    `duration_minutes` INT NOT NULL DEFAULT 60,
    `total_marks` DECIMAL(6,2) NOT NULL DEFAULT 100.00,
    `pass_percentage` DECIMAL(5,2) NOT NULL DEFAULT 40.00,
    `negative_marking` DECIMAL(4,2) NOT NULL DEFAULT 0.50,
    `validation_status` ENUM('draft','valid','invalid','blocked') NOT NULL DEFAULT 'draft',
    `validation_summary` JSON NULL,
    `is_locked` TINYINT(1) NOT NULL DEFAULT 0,
    `locked_at` DATETIME NULL,
    `created_by` INT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_tv_test` (`test_id`),
    INDEX `idx_tv_version` (`test_id`, `version_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Post-Exam Answer Key Regrade Jobs
CREATE TABLE IF NOT EXISTS `regrade_jobs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `test_id` INT NOT NULL,
    `test_version_id` INT NULL,
    `question_id` INT NOT NULL,
    `old_answer` VARCHAR(16) NOT NULL,
    `new_answer` VARCHAR(16) NOT NULL,
    `scoring_action` ENUM('change_key','give_bonus','exclude_question') NOT NULL DEFAULT 'change_key',
    `affected_attempts_count` INT NOT NULL DEFAULT 0,
    `processed_attempts_count` INT NOT NULL DEFAULT 0,
    `status` ENUM('queued','running','completed','failed') NOT NULL DEFAULT 'queued',
    `reason` TEXT NOT NULL,
    `created_by` INT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `completed_at` DATETIME NULL,
    INDEX `idx_rj_test` (`test_id`),
    INDEX `idx_rj_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Referral Codes
CREATE TABLE IF NOT EXISTS `referral_codes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL UNIQUE,
    `code` VARCHAR(32) NOT NULL UNIQUE,
    `status` ENUM('active','suspended') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_ref_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Referrals Attribution
CREATE TABLE IF NOT EXISTS `referrals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `referrer_user_id` INT NOT NULL,
    `referred_user_id` INT NOT NULL UNIQUE,
    `referral_code` VARCHAR(32) NOT NULL,
    `status` ENUM('attributed','pending_qualification','qualified','rewarded','fraud_flagged') NOT NULL DEFAULT 'attributed',
    `rejection_reason` VARCHAR(255) NULL,
    `qualified_at` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_ref_referrer` (`referrer_user_id`),
    INDEX `idx_ref_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. Immutable Referral Reward Ledger
CREATE TABLE IF NOT EXISTS `referral_rewards` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `referral_id` INT NOT NULL,
    `beneficiary_user_id` INT NOT NULL,
    `reward_type` ENUM('premium_days','bonus_coins','voucher') NOT NULL DEFAULT 'premium_days',
    `reward_days` INT NOT NULL DEFAULT 7,
    `idempotency_key` VARCHAR(64) NOT NULL UNIQUE,
    `status` ENUM('issued','reversed') NOT NULL DEFAULT 'issued',
    `issued_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_rr_ben` (`beneficiary_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. Subscription Plans & User Entitlements (PRD §18)
CREATE TABLE IF NOT EXISTS `subscription_plans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `duration_days` INT NOT NULL DEFAULT 30,
    `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `description` TEXT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. User Active Subscriptions & Entitlements
CREATE TABLE IF NOT EXISTS `user_subscriptions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `plan_id` INT NOT NULL DEFAULT 1,
    `status` ENUM('trial','active','expiring','expired','cancelled','suspended') NOT NULL DEFAULT 'active',
    `expiry_date` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_us_user` (`user_id`),
    INDEX `idx_us_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 14. User Transactional Notifications (PRD §19)
CREATE TABLE IF NOT EXISTS `user_notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `type` VARCHAR(50) DEFAULT 'general',
    `is_read` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_un_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
