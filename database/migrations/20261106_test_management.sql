-- Migration: AI-Powered Online Test Creation & Examination Management System
-- Updates tests table and test_attempts table with full examination suite fields

ALTER TABLE `tests`
  MODIFY COLUMN `status` ENUM('draft', 'ready_to_publish', 'published', 'active', 'completed', 'archived') DEFAULT 'draft',
  MODIFY COLUMN `pattern_id` INT NULL,
  MODIFY COLUMN `exam_id` INT NULL,
  ADD COLUMN IF NOT EXISTS `description` TEXT NULL AFTER `title`,
  ADD COLUMN IF NOT EXISTS `subject_id` INT NULL AFTER `exam_id`,
  ADD COLUMN IF NOT EXISTS `chapter_id` INT NULL AFTER `subject_id`,
  ADD COLUMN IF NOT EXISTS `topic_id` INT NULL AFTER `chapter_id`,
  ADD COLUMN IF NOT EXISTS `course_class` VARCHAR(100) NULL AFTER `topic_id`,
  ADD COLUMN IF NOT EXISTS `test_category` VARCHAR(100) NULL AFTER `course_class`,
  ADD COLUMN IF NOT EXISTS `difficulty` ENUM('easy','medium','hard') DEFAULT 'medium' AFTER `test_category`,
  ADD COLUMN IF NOT EXISTS `total_questions` INT DEFAULT 0 AFTER `difficulty`,
  ADD COLUMN IF NOT EXISTS `total_marks` DECIMAL(8,2) DEFAULT 0.00 AFTER `total_questions`,
  ADD COLUMN IF NOT EXISTS `duration_minutes` INT DEFAULT 60 AFTER `total_marks`,
  ADD COLUMN IF NOT EXISTS `negative_marking` DECIMAL(5,2) DEFAULT 0.00 AFTER `duration_minutes`,
  ADD COLUMN IF NOT EXISTS `passing_marks` DECIMAL(8,2) DEFAULT 0.00 AFTER `negative_marking`,
  ADD COLUMN IF NOT EXISTS `results_published` TINYINT(1) DEFAULT 1 AFTER `passing_marks`,
  ADD COLUMN IF NOT EXISTS `published_at` DATETIME NULL AFTER `end_time`,
  ADD COLUMN IF NOT EXISTS `created_by_admin_id` INT NULL AFTER `published_at`;

ALTER TABLE `test_attempts`
  ADD COLUMN IF NOT EXISTS `is_passed` TINYINT(1) NULL AFTER `percentile`,
  ADD COLUMN IF NOT EXISTS `passing_marks` DECIMAL(8,2) NULL AFTER `is_passed`;

