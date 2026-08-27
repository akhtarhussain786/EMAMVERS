-- EXAMVERSE Database Migration v5.0 — Map Learning, Friends Discovery, Mistake Notebook

USE `examverse_db`;

-- 1. MAP LEARNING CATEGORIES
CREATE TABLE IF NOT EXISTS `map_categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `slug` VARCHAR(100) NOT NULL UNIQUE,
    `icon` VARCHAR(50) DEFAULT 'place',
    `sort_order` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. MAP LOCATIONS
CREATE TABLE IF NOT EXISTS `map_locations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_id` INT NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `slug` VARCHAR(150) NOT NULL UNIQUE,
    `country` VARCHAR(100) DEFAULT 'India',
    `state` VARCHAR(100) NULL,
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,
    `short_description` TEXT,
    `important_facts` TEXT,
    `exam_relevance` VARCHAR(255),
    `pyq_count` INT DEFAULT 0,
    `image_url` VARCHAR(255) NULL,
    `status` ENUM('active', 'inactive') DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`category_id`) REFERENCES `map_categories`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. MAP LOCATION FACTS
CREATE TABLE IF NOT EXISTS `map_location_facts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `location_id` INT NOT NULL,
    `fact` TEXT NOT NULL,
    `sort_order` INT DEFAULT 0,
    FOREIGN KEY (`location_id`) REFERENCES `map_locations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. MAP QUIZ QUESTIONS
CREATE TABLE IF NOT EXISTS `map_questions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `location_id` INT NOT NULL,
    `question_text` TEXT NOT NULL,
    `option_a` VARCHAR(150) NOT NULL,
    `option_b` VARCHAR(150) NOT NULL,
    `option_c` VARCHAR(150) NOT NULL,
    `option_d` VARCHAR(150) NOT NULL,
    `correct_option` ENUM('A', 'B', 'C', 'D') NOT NULL,
    `explanation` TEXT,
    FOREIGN KEY (`location_id`) REFERENCES `map_locations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. MAP USER PROGRESS
CREATE TABLE IF NOT EXISTS `map_user_progress` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `location_id` INT NOT NULL,
    `is_learned` TINYINT(1) DEFAULT 1,
    `quiz_score` INT DEFAULT 0,
    `last_reviewed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `user_loc_unique` (`user_id`, `location_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`location_id`) REFERENCES `map_locations`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. USER CONTACTS MATCHING (PRIVACY SAFE HASHES)
CREATE TABLE IF NOT EXISTS `user_contacts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `contact_phone_hash` VARCHAR(64) NOT NULL,
    `matched_user_id` INT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`matched_user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. MISTAKE NOTEBOOK
CREATE TABLE IF NOT EXISTS `mistake_notebook` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `question_id` INT NOT NULL,
    `user_answer` VARCHAR(255),
    `correct_answer` VARCHAR(255),
    `mistake_reason` TEXT,
    `is_mastered` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. USER WEAK TOPICS
CREATE TABLE IF NOT EXISTS `user_weak_topics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `topic_id` INT NOT NULL,
    `accuracy` DECIMAL(5, 2) DEFAULT 0.00,
    `attempted_count` INT DEFAULT 0,
    `last_practiced_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `user_topic_unique` (`user_id`, `topic_id`),
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
