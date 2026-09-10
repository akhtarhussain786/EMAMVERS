-- Migration v10: System Settings Table for dynamic SMS Gateway, Payment Gateway, and App Configurations
CREATE TABLE IF NOT EXISTS `system_settings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) NOT NULL UNIQUE,
    `setting_value` LONGTEXT NULL,
    `is_encrypted` TINYINT(1) DEFAULT 0,
    `category` ENUM('sms', 'payment', 'general', 'ai') DEFAULT 'general',
    `description` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed default initial configurations
INSERT INTO `system_settings` (`setting_key`, `setting_value`, `is_encrypted`, `category`, `description`) VALUES
('sms_enabled', '0', 0, 'sms', 'Enable or disable live SMS gateway'),
('sms_provider', 'fast2sms', 0, 'sms', 'Active SMS provider: fast2sms, msg91, twilio, dev_mock'),
('sms_api_key', '', 1, 'sms', 'SMS Gateway API Key / Auth Token'),
('sms_sender_id', 'EXAMVR', 0, 'sms', 'SMS Sender ID / Header'),
('sms_template_id', '', 0, 'sms', 'DLT Template ID (Fast2SMS/MSG91)'),
('sms_entity_id', '', 0, 'sms', 'DLT Principal Entity ID'),
('sms_route', 'otp', 0, 'sms', 'Fast2SMS route: otp or dlt'),

('payment_enabled', '0', 0, 'payment', 'Enable live payment gateway'),
('payment_mode', 'mock', 0, 'payment', 'Payment mode: mock, test, live'),
('razorpay_key_id', '', 0, 'payment', 'Razorpay Key ID (rzp_test_... or rzp_live_...)'),
('razorpay_key_secret', '', 1, 'payment', 'Razorpay Key Secret'),
('razorpay_webhook_secret', '', 1, 'payment', 'Razorpay Webhook Secret'),
('payment_currency', 'INR', 0, 'payment', 'Default payment currency'),

('app_name', 'EXAMVERSE', 0, 'general', 'Application Display Name'),
('support_email', 'support@examverse.com', 0, 'general', 'Official Support Email'),
('support_phone', '+91 9876543210', 0, 'general', 'Official Support Phone')
ON DUPLICATE KEY UPDATE `description` = VALUES(`description`);

-- Ensure user_notifications table type column accommodates referral and audit types
ALTER TABLE `user_notifications` MODIFY COLUMN `type` VARCHAR(64) DEFAULT 'general';

