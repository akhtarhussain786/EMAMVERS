-- Migration v11: Add District to Users and Expand States & Qualifications Taxonomy

-- 1. Add district column to users if not exists
SET @dbname = DATABASE();
SET @tablename = "users";
SET @columnname = "district";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 1",
  "ALTER TABLE users ADD COLUMN district VARCHAR(100) NULL AFTER state_id;"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 2. Seed All Indian States & UTs
INSERT INTO `states` (`id`, `code`, `name`) VALUES
(1, 'DL', 'Delhi NCR'),
(2, 'MH', 'Maharashtra'),
(3, 'UP', 'Uttar Pradesh'),
(4, 'BR', 'Bihar'),
(5, 'RJ', 'Rajasthan'),
(6, 'MP', 'Madhya Pradesh'),
(7, 'WB', 'West Bengal'),
(8, 'TN', 'Tamil Nadu'),
(9, 'KA', 'Karnataka'),
(10, 'GJ', 'Gujarat'),
(11, 'HR', 'Haryana'),
(12, 'PB', 'Punjab'),
(13, 'JH', 'Jharkhand'),
(14, 'CG', 'Chhattisgarh'),
(15, 'OD', 'Odisha'),
(16, 'AS', 'Assam'),
(17, 'TG', 'Telangana'),
(18, 'AP', 'Andhra Pradesh'),
(19, 'KL', 'Kerala'),
(20, 'UK', 'Uttarakhand'),
(21, 'HP', 'Himachal Pradesh'),
(22, 'JK', 'Jammu & Kashmir'),
(23, 'GA', 'Goa'),
(24, 'TR', 'Tripura'),
(25, 'ML', 'Meghalaya'),
(26, 'MN', 'Manipur'),
(27, 'NL', 'Nagaland'),
(28, 'MZ', 'Mizoram'),
(29, 'AR', 'Arunachal Pradesh'),
(30, 'SK', 'Sikkim'),
(31, 'CH', 'Chandigarh'),
(32, 'PY', 'Puducherry'),
(33, 'ALL', 'All India / Other')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `code` = VALUES(`code`);

-- 3. Seed Comprehensive Qualifications
INSERT INTO `qualifications` (`id`, `code`, `name`) VALUES
(1, '10TH', '10th Pass (Matriculation)'),
(2, '12TH', '12th Pass (Intermediate / Senior Secondary)'),
(3, 'DIPLOMA', 'Diploma / Polytechnic'),
(4, 'GRAD', 'Graduation (BA / B.Sc / B.Com / Bachelor Degree)'),
(5, 'ENGG', 'B.Tech / B.E. (Engineering)'),
(6, 'POSTGRAD', 'Post Graduation (MA / M.Sc / M.Com / MCA)'),
(7, 'BED', 'B.Ed / D.El.Ed (Teaching Degree)'),
(8, 'MED', 'MBBS / BDS / Medical'),
(9, 'LAW', 'LLB / Law Graduate'),
(10, 'OTHER', 'Other Qualification')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `code` = VALUES(`code`);
