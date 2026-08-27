-- EXAMVERSE Migration v4 — Bookmarks, Wrong Questions, Notifications, Target Exams
USE `examverse_db`;

-- 1. Bookmarks
CREATE TABLE IF NOT EXISTS `user_bookmarks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `item_type` ENUM('question', 'article', 'material', 'test') NOT NULL DEFAULT 'question',
    `item_id` INT NOT NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `user_item_bookmark` (`user_id`, `item_type`, `item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Wrong Questions Notebook (Mistake Bank)
CREATE TABLE IF NOT EXISTS `user_wrong_questions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `question_id` INT NOT NULL,
    `attempt_id` INT NOT NULL,
    `user_selected_key` VARCHAR(10) NULL,
    `correct_key` VARCHAR(10) NOT NULL,
    `review_status` ENUM('unreviewed', 'mastered', 'needs_practice') DEFAULT 'unreviewed',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `user_attempt_q` (`user_id`, `attempt_id`, `question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Notifications System
CREATE TABLE IF NOT EXISTS `user_notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `type` ENUM('system', 'challenge', 'marketplace', 'ai_coaching', 'job_alert') DEFAULT 'system',
    `action_url` VARCHAR(255) NULL,
    `is_read` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. User Target Exams
CREATE TABLE IF NOT EXISTS `user_target_exams` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `exam_id` INT NOT NULL,
    `target_year` INT DEFAULT 2026,
    `is_primary` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `user_exam_target` (`user_id`, `exam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT 'Migration v4 completed successfully!' AS result;
