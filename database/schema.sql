-- EXAMVERSE MySQL Database Schema (SRD v2.0 Baseline)
CREATE DATABASE IF NOT EXISTS `examverse_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `examverse_db`;

-- 1. IDENTITY & ONBOARDING
CREATE TABLE IF NOT EXISTS `states` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(10) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `qualifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `full_name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `mobile` VARCHAR(20) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `state_id` INT NULL,
    `qualification_id` INT NULL,
    `is_verified` TINYINT(1) DEFAULT 0,
    `status` ENUM('active', 'suspended', 'pending') DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`state_id`) REFERENCES `states`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`qualification_id`) REFERENCES `qualifications`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `user_otps` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `mobile_or_email` VARCHAR(150) NOT NULL,
    `otp_code` VARCHAR(10) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `is_used` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. EXAM TAXONOMY
CREATE TABLE IF NOT EXISTS `exam_categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `slug` VARCHAR(100) NOT NULL UNIQUE,
    `type` ENUM('government', 'entrance', 'private_job', 'upskilling', 'qualification') DEFAULT 'government',
    `description` TEXT,
    `icon_url` VARCHAR(255),
    `status` ENUM('active', 'inactive') DEFAULT 'active',
    `sort_order` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `organizations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL,
    `short_name` VARCHAR(50) NOT NULL,
    `logo_url` VARCHAR(255),
    `website` VARCHAR(255),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `exams` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_id` INT NOT NULL,
    `organization_id` INT NULL,
    `title` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(150) NOT NULL UNIQUE,
    `short_description` TEXT,
    `overview_text` LONGTEXT,
    `syllabus_text` LONGTEXT,
    `eligibility_info` TEXT,
    `banner_url` VARCHAR(255),
    `status` ENUM('active', 'draft', 'archived') DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`category_id`) REFERENCES `exam_categories`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`organization_id`) REFERENCES `organizations`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `subjects` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `code` VARCHAR(50) UNIQUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `chapters` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `subject_id` INT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `topics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `chapter_id` INT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    FOREIGN KEY (`chapter_id`) REFERENCES `chapters`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. TEST PATTERNS (Universal Test Engine Rules)
CREATE TABLE IF NOT EXISTS `exam_patterns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `exam_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `pattern_version` INT DEFAULT 1,
    `timer_mode` ENUM('TOTAL', 'SECTIONAL') DEFAULT 'TOTAL',
    `total_duration_seconds` INT NOT NULL,
    `total_questions` INT NOT NULL,
    `total_marks` DECIMAL(8,2) NOT NULL,
    `default_positive_marks` DECIMAL(5,2) DEFAULT 2.00,
    `default_negative_marks` DECIMAL(5,2) DEFAULT 0.50,
    `navigation_policy` ENUM('FREE', 'SECTION_LOCKED') DEFAULT 'FREE',
    `languages` VARCHAR(255) DEFAULT 'en,hi',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `pattern_sections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `pattern_id` INT NOT NULL,
    `subject_id` INT NOT NULL,
    `section_name` VARCHAR(100) NOT NULL,
    `question_count` INT NOT NULL,
    `positive_marks` DECIMAL(5,2) NOT NULL,
    `negative_marks` DECIMAL(5,2) NOT NULL,
    `duration_seconds` INT DEFAULT 0,
    `sort_order` INT DEFAULT 1,
    FOREIGN KEY (`pattern_id`) REFERENCES `exam_patterns`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. QUESTION BANK
CREATE TABLE IF NOT EXISTS `questions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `subject_id` INT NOT NULL,
    `chapter_id` INT NULL,
    `topic_id` INT NULL,
    `question_type` ENUM('MCQ', 'NUMERICAL') DEFAULT 'MCQ',
    `difficulty` ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
    `pyq_year` INT NULL,
    `pyq_shift` VARCHAR(50) NULL,
    `status` ENUM('draft', 'review', 'published') DEFAULT 'published',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`chapter_id`) REFERENCES `chapters`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`topic_id`) REFERENCES `topics`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `question_translations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `question_id` INT NOT NULL,
    `language` VARCHAR(10) NOT NULL DEFAULT 'en',
    `question_text` LONGTEXT NOT NULL,
    `solution_text` LONGTEXT,
    `shortcut_text` LONGTEXT,
    FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `q_lang` (`question_id`, `language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `question_options` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `question_id` INT NOT NULL,
    `option_key` VARCHAR(10) NOT NULL, -- A, B, C, D
    `language` VARCHAR(10) NOT NULL DEFAULT 'en',
    `option_text` TEXT NOT NULL,
    `is_correct` TINYINT(1) DEFAULT 0,
    FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. TESTS & TEST SERIES
CREATE TABLE IF NOT EXISTS `tests` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `exam_id` INT NOT NULL,
    `pattern_id` INT NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(150) NOT NULL UNIQUE,
    `test_type` ENUM('full_mock', 'sectional', 'topic', 'pyq', 'live', 'monthly_challenge') DEFAULT 'full_mock',
    `is_paid` TINYINT(1) DEFAULT 0,
    `price` DECIMAL(10,2) DEFAULT 0.00,
    `instructions` LONGTEXT,
    `status` ENUM('draft', 'scheduled', 'published', 'closed') DEFAULT 'published',
    `start_time` DATETIME NULL,
    `end_time` DATETIME NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`pattern_id`) REFERENCES `exam_patterns`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `test_questions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `test_id` INT NOT NULL,
    `question_id` INT NOT NULL,
    `section_id` INT NULL,
    `question_order` INT NOT NULL,
    `positive_marks` DECIMAL(5,2) DEFAULT 2.00,
    `negative_marks` DECIMAL(5,2) DEFAULT 0.50,
    FOREIGN KEY (`test_id`) REFERENCES `tests`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. ATTEMPTS & TEST ENGINE LOGIC
CREATE TABLE IF NOT EXISTS `test_attempts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `test_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `pattern_version` INT DEFAULT 1,
    `status` ENUM('in_progress', 'submitted', 'evaluated') DEFAULT 'in_progress',
    `score` DECIMAL(8,2) DEFAULT 0.00,
    `accuracy_percentage` DECIMAL(5,2) DEFAULT 0.00,
    `total_time_spent_seconds` INT DEFAULT 0,
    `correct_count` INT DEFAULT 0,
    `wrong_count` INT DEFAULT 0,
    `unattempted_count` INT DEFAULT 0,
    `central_rank` INT NULL,
    `state_rank` INT NULL,
    `percentile` DECIMAL(6,2) DEFAULT 0.00,
    `started_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `submitted_at` DATETIME NULL,
    FOREIGN KEY (`test_id`) REFERENCES `tests`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `attempt_answers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `attempt_id` INT NOT NULL,
    `question_id` INT NOT NULL,
    `selected_option_key` VARCHAR(10) NULL,
    `numerical_answer` VARCHAR(100) NULL,
    `is_marked_for_review` TINYINT(1) DEFAULT 0,
    `is_answered` TINYINT(1) DEFAULT 0,
    `is_correct` TINYINT(1) NULL,
    `marks_awarded` DECIMAL(5,2) DEFAULT 0.00,
    `time_spent_seconds` INT DEFAULT 0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `attempt_q` (`attempt_id`, `question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. MONTHLY NATIONAL CHALLENGES & LEADERBOARDS
CREATE TABLE IF NOT EXISTS `monthly_challenges` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `exam_id` INT NOT NULL,
    `test_id` INT NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `month_year` VARCHAR(20) NOT NULL,
    `start_window` DATETIME NOT NULL,
    `end_window` DATETIME NOT NULL,
    `status` ENUM('upcoming', 'live', 'evaluating', 'completed') DEFAULT 'upcoming',
    `tie_break_rule` VARCHAR(255) DEFAULT '1. Score DESC, 2. Accuracy DESC, 3. Negative Marks ASC, 4. Time Spent ASC',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`test_id`) REFERENCES `tests`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `challenge_registrations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `challenge_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`challenge_id`) REFERENCES `monthly_challenges`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `user_challenge` (`challenge_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `integrity_flags` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `attempt_id` INT NOT NULL,
    `flag_type` VARCHAR(50) NOT NULL,
    `reason` TEXT NOT NULL,
    `status` ENUM('pending', 'reviewed_valid', 'disqualified') DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. AI CAPABILITIES
CREATE TABLE IF NOT EXISTS `exam_twin_snapshots` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `exam_id` INT NOT NULL,
    `knowledge_score` DECIMAL(5,2) DEFAULT 0.00,
    `accuracy_score` DECIMAL(5,2) DEFAULT 0.00,
    `speed_score` DECIMAL(5,2) DEFAULT 0.00,
    `consistency_score` DECIMAL(5,2) DEFAULT 0.00,
    `overall_readiness` DECIMAL(5,2) DEFAULT 0.00,
    `estimated_score_min` INT DEFAULT 0,
    `estimated_score_max` INT DEFAULT 0,
    `target_benchmark` INT DEFAULT 160,
    `diagnosis_summary` TEXT,
    `recommended_route` TEXT,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `daily_missions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `mission_date` DATE NOT NULL,
    `total_planned_minutes` INT DEFAULT 45,
    `items_json` LONGTEXT NOT NULL,
    `status` ENUM('pending', 'completed') DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `user_date` (`user_id`, `mission_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lost_marks_analyses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `attempt_id` INT NOT NULL,
    `concept_gap_marks` DECIMAL(5,2) DEFAULT 0.00,
    `silly_mistake_marks` DECIMAL(5,2) DEFAULT 0.00,
    `time_pressure_marks` DECIMAL(5,2) DEFAULT 0.00,
    `question_selection_marks` DECIMAL(5,2) DEFAULT 0.00,
    `recoverable_marks_estimate` DECIMAL(5,2) DEFAULT 0.00,
    `actionable_advice` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. CONTENT HUBS
CREATE TABLE IF NOT EXISTS `current_affairs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) NOT NULL,
    `category` VARCHAR(100) DEFAULT 'General',
    `publish_date` DATE NOT NULL,
    `content_body` LONGTEXT NOT NULL,
    `pdf_url` VARCHAR(255) NULL,
    `is_published` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `jobs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `organization_name` VARCHAR(150) NOT NULL,
    `job_type` ENUM('government', 'private') DEFAULT 'government',
    `total_vacancies` INT DEFAULT 0,
    `eligibility_criteria` TEXT,
    `last_date_to_apply` DATE NULL,
    `apply_link` VARCHAR(255),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `topper_stories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `student_name` VARCHAR(150) NOT NULL,
    `photo_url` VARCHAR(255),
    `exam_name` VARCHAR(150) NOT NULL,
    `year` INT NOT NULL,
    `verified_rank` INT NOT NULL,
    `best_mock_rank` INT NOT NULL,
    `story_text` TEXT NOT NULL,
    `is_verified` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. COMMERCE & ENTITLEMENTS
CREATE TABLE IF NOT EXISTS `orders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `order_code` VARCHAR(50) NOT NULL UNIQUE,
    `user_id` INT NOT NULL,
    `amount` DECIMAL(10,2) NOT NULL,
    `currency` VARCHAR(10) DEFAULT 'INR',
    `payment_status` ENUM('created', 'paid', 'failed', 'refunded') DEFAULT 'created',
    `gateway_transaction_id` VARCHAR(100) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `entitlements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `item_type` ENUM('test', 'test_series', 'book') NOT NULL,
    `item_id` INT NOT NULL,
    `order_id` INT NULL,
    `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. ADMIN RBAC & AUDIT LOGS
CREATE TABLE IF NOT EXISTS `admins` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `email` VARCHAR(150) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `full_name` VARCHAR(100) NOT NULL,
    `role` ENUM('super_admin', 'content_operator', 'reviewer', 'finance_operator') DEFAULT 'content_operator',
    `status` ENUM('active', 'inactive') DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `admin_audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_id` INT NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `entity_type` VARCHAR(50) NOT NULL,
    `entity_id` INT NULL,
    `details` TEXT NULL,
    `ip_address` VARCHAR(50) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`admin_id`) REFERENCES `admins`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
