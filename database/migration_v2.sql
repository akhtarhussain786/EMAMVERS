-- EXAMVERSE Migration v2 — Creator Economy, Marketplace, AI Keys
USE `examverse_db`;

-- 1. Add user_type to users (student or creator)
-- Add user_type, avatar_url, bio to users (safe via individual try)
ALTER TABLE `users` ADD COLUMN `user_type` ENUM('student','creator') NOT NULL DEFAULT 'student' AFTER `status`;
ALTER TABLE `users` ADD COLUMN `avatar_url` VARCHAR(255) NULL AFTER `user_type`;
ALTER TABLE `users` ADD COLUMN `bio` TEXT NULL AFTER `avatar_url`;

-- 2. Creator profiles
CREATE TABLE IF NOT EXISTS `creators` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL UNIQUE,
    `display_name` VARCHAR(150) NOT NULL,
    `about` TEXT,
    `upi_id` VARCHAR(100),
    `bank_account_number` VARCHAR(50),
    `bank_ifsc` VARCHAR(20),
    `bank_account_name` VARCHAR(150),
    `total_earnings` DECIMAL(12,2) DEFAULT 0.00,
    `pending_payout` DECIMAL(12,2) DEFAULT 0.00,
    `paid_out` DECIMAL(12,2) DEFAULT 0.00,
    `platform_commission_pct` DECIMAL(5,2) DEFAULT 20.00,
    `verification_status` ENUM('pending','approved','rejected','suspended') DEFAULT 'pending',
    `verified_at` DATETIME NULL,
    `total_materials` INT DEFAULT 0,
    `total_sales` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Study Materials (uploaded by creators)
CREATE TABLE IF NOT EXISTS `study_materials` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `creator_id` INT NOT NULL,
    `exam_id` INT NULL,
    `subject_id` INT NULL,
    `title` VARCHAR(200) NOT NULL,
    `slug` VARCHAR(200) NOT NULL UNIQUE,
    `description` TEXT,
    `tags` VARCHAR(500),
    `file_path` VARCHAR(500) NOT NULL,
    `cover_image_url` VARCHAR(500),
    `file_size_kb` INT DEFAULT 0,
    `total_pages` INT DEFAULT 0,
    `preview_pages` INT DEFAULT 5,
    `language` VARCHAR(20) DEFAULT 'en',
    `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `is_free` TINYINT(1) DEFAULT 0,
    `status` ENUM('draft','pending_review','approved','rejected','archived') DEFAULT 'pending_review',
    `rejection_reason` TEXT NULL,
    `total_downloads` INT DEFAULT 0,
    `total_revenue` DECIMAL(12,2) DEFAULT 0.00,
    `rating_avg` DECIMAL(3,2) DEFAULT 0.00,
    `rating_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`creator_id`) REFERENCES `creators`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Material Purchases
CREATE TABLE IF NOT EXISTS `material_purchases` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `material_id` INT NOT NULL,
    `amount_paid` DECIMAL(10,2) NOT NULL,
    `platform_fee` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `creator_earning` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `payment_status` ENUM('pending','completed','failed','refunded') DEFAULT 'completed',
    `payment_method` VARCHAR(50) DEFAULT 'mock',
    `transaction_id` VARCHAR(200) NULL,
    `purchased_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`material_id`) REFERENCES `study_materials`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `user_material` (`user_id`, `material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Material Ratings & Reviews
CREATE TABLE IF NOT EXISTS `material_reviews` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `material_id` INT NOT NULL,
    `user_id` INT NOT NULL,
    `rating` TINYINT NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
    `review_text` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`material_id`) REFERENCES `study_materials`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `material_user_review` (`material_id`, `user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. AI API Keys (stored securely per admin)
CREATE TABLE IF NOT EXISTS `ai_api_keys` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `label` VARCHAR(100) NOT NULL,
    `provider` ENUM('gemini','openai') NOT NULL DEFAULT 'gemini',
    `api_key_encrypted` TEXT NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `usage_count` INT DEFAULT 0,
    `last_used_at` DATETIME NULL,
    `created_by` VARCHAR(100) DEFAULT 'admin',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. AI Generated Question Batches (for review before publishing)
CREATE TABLE IF NOT EXISTS `ai_question_batches` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `ai_key_id` INT NULL,
    `exam_id` INT NULL,
    `subject_id` INT NULL,
    `section_name` VARCHAR(100),
    `difficulty` ENUM('easy','medium','hard') DEFAULT 'medium',
    `language` VARCHAR(10) DEFAULT 'en',
    `count_requested` INT DEFAULT 5,
    `count_generated` INT DEFAULT 0,
    `count_approved` INT DEFAULT 0,
    `status` ENUM('pending','completed','error','partial') DEFAULT 'pending',
    `prompt_text` TEXT,
    `raw_response` LONGTEXT,
    `error_message` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`ai_key_id`) REFERENCES `ai_api_keys`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. AI Generated Questions (staging — before approval into main questions table)
CREATE TABLE IF NOT EXISTS `ai_generated_questions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `batch_id` INT NOT NULL,
    `question_text` LONGTEXT NOT NULL,
    `option_a` TEXT NOT NULL,
    `option_b` TEXT NOT NULL,
    `option_c` TEXT NOT NULL,
    `option_d` TEXT NOT NULL,
    `correct_option` ENUM('A','B','C','D') NOT NULL,
    `explanation` LONGTEXT,
    `difficulty` ENUM('easy','medium','hard') DEFAULT 'medium',
    `review_status` ENUM('pending','approved','rejected','edited') DEFAULT 'pending',
    `approved_question_id` INT NULL,
    `admin_notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`batch_id`) REFERENCES `ai_question_batches`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`approved_question_id`) REFERENCES `questions`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Payout Requests from Creators
CREATE TABLE IF NOT EXISTS `creator_payouts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `creator_id` INT NOT NULL,
    `amount_requested` DECIMAL(12,2) NOT NULL,
    `amount_paid` DECIMAL(12,2) DEFAULT 0.00,
    `status` ENUM('requested','processing','completed','rejected') DEFAULT 'requested',
    `payout_method` VARCHAR(50) DEFAULT 'upi',
    `transaction_reference` VARCHAR(200) NULL,
    `admin_notes` TEXT NULL,
    `requested_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `processed_at` DATETIME NULL,
    FOREIGN KEY (`creator_id`) REFERENCES `creators`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Exam sub-exam parent-child relationship (for mega taxonomy)
ALTER TABLE `exams` ADD COLUMN `parent_exam_id` INT NULL AFTER `id`;
ALTER TABLE `exams` ADD COLUMN `exam_level` ENUM('main','sub','stage') DEFAULT 'main' AFTER `parent_exam_id`;
ALTER TABLE `exams` ADD CONSTRAINT `fk_exam_parent` FOREIGN KEY (`parent_exam_id`) REFERENCES `exams`(`id`) ON DELETE SET NULL;

-- 11. Add search index on exam_categories
ALTER TABLE `exam_categories` ADD COLUMN `parent_category_id` INT NULL AFTER `id`;
ALTER TABLE `exam_categories` ADD COLUMN `keywords` TEXT NULL AFTER `description`;

SELECT 'Migration v2 completed successfully!' AS result;
