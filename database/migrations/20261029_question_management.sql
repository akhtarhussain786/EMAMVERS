-- Safe Migration: Question Management System
-- Adds extended statuses, types, scoring, media, review feedback, and creator tracking without data loss.

ALTER TABLE `questions` 
  MODIFY COLUMN `status` ENUM('draft', 'review', 'published', 'rejected', 'changes_requested') DEFAULT 'draft',
  MODIFY COLUMN `question_type` ENUM('MCQ', 'NUMERICAL', 'TRUE_FALSE', 'DESCRIPTIVE') DEFAULT 'MCQ',
  ADD COLUMN IF NOT EXISTS `image_url` VARCHAR(255) NULL AFTER `question_type`,
  ADD COLUMN IF NOT EXISTS `marks` DECIMAL(5,2) DEFAULT 1.00 AFTER `difficulty`,
  ADD COLUMN IF NOT EXISTS `negative_marks` DECIMAL(5,2) DEFAULT 0.00 AFTER `marks`,
  ADD COLUMN IF NOT EXISTS `options_json` LONGTEXT NULL AFTER `negative_marks`,
  ADD COLUMN IF NOT EXISTS `created_by_admin_id` INT NULL AFTER `author_user_id`,
  ADD COLUMN IF NOT EXISTS `admin_comment` TEXT NULL AFTER `rejection_reason`,
  ADD COLUMN IF NOT EXISTS `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`;

