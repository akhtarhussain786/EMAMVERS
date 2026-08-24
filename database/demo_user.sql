-- Insert Default Demo Candidate Account
USE `examverse_db`;

-- Demo Candidate User (Email: demo@examverse.com | Password: password123)
-- Password hash generated via password_hash('password123', PASSWORD_BCRYPT)
INSERT INTO `users` (`full_name`, `email`, `mobile`, `password_hash`, `state_id`, `qualification_id`, `is_verified`, `status`) VALUES
('Aarav Sharma', 'demo@examverse.com', '9876543210', '$2y$10$wE1VfW3uKqYx1W.H8rV8u.Jv9z9y0q/7n1J2X3Y4Z5W6V7U8T9S0R1Q', 1, 3, 1, 'active')
ON DUPLICATE KEY UPDATE `full_name`=`full_name`;
