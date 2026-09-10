-- EXAMVERSE Complete Unified Database Dump
-- Compatible with phpMyAdmin, cPanel, Staging & Production

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone = '+00:00';

-- --------------------------------------------------------
-- Table structure for `admin_audit_logs`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `admin_audit_logs`;
CREATE TABLE `admin_audit_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) NOT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `admin_id` (`admin_id`),
  CONSTRAINT `admin_audit_logs_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `admin_audit_logs`
INSERT INTO `admin_audit_logs` (`id`, `admin_id`, `action`, `entity_type`, `entity_id`, `details`, `ip_address`, `created_at`) VALUES
('1', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-21 15:04:20'),
('2', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-21 15:10:44'),
('3', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-25 14:38:41'),
('4', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged in', NULL, '2026-08-25 18:40:17'),
('5', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged in', NULL, '2026-08-25 18:40:34'),
('6', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged in', NULL, '2026-08-25 18:44:14'),
('7', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-27 11:00:59'),
('8', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-27 11:01:17'),
('9', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-27 13:49:32'),
('10', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-27 23:36:48'),
('11', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-08-31 15:13:46'),
('12', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-09-02 17:17:11'),
('13', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-09-05 10:59:00'),
('14', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-09-08 13:46:32'),
('15', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged in', NULL, '2026-09-08 13:49:43'),
('16', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged in', NULL, '2026-09-08 13:51:01'),
('17', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-09-08 14:48:52'),
('18', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged in', NULL, '2026-09-09 10:46:07'),
('19', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-09-09 11:02:07'),
('20', '1', 'LOGIN', 'ADMIN', NULL, 'Admin logged into Admin Control Center', NULL, '2026-09-10 11:52:05'),
('21', '1', 'TEACHER_APPLICATION_APPROVE', 'teacher_applications', '4', '{\"note\":\"Approved credentials & verified KYC documents.\",\"user_id\":8}', NULL, '2026-09-10 11:56:59'),
('22', '1', 'TEACHER_APPLICATION_APPROVE', 'teacher_applications', '5', '{\"note\":\"Application and credentials approved.\",\"user_id\":9}', NULL, '2026-09-10 11:58:16'),
('23', '1', 'TEACHER_APPLICATION_APPROVE', 'teacher_applications', '3', '{\"note\":\"Application and credentials approved.\",\"user_id\":7}', NULL, '2026-09-10 11:59:23');

-- --------------------------------------------------------
-- Table structure for `admins`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `admins`;
CREATE TABLE `admins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `role` enum('super_admin','content_operator','reviewer','finance_operator') DEFAULT 'content_operator',
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `admins`
INSERT INTO `admins` (`id`, `username`, `email`, `password_hash`, `full_name`, `role`, `status`, `created_at`) VALUES
('1', 'admin', 'admin@examverse.com', '$2y$10$EvxQOZeaI8saoR3UQIBTvOoD/oXRMe6QHgEu1PY1yco5xt3eQdc1S', 'Super Administrator', 'super_admin', 'active', '2026-08-21 14:22:31');

-- --------------------------------------------------------
-- Table structure for `ai_api_keys`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `ai_api_keys`;
CREATE TABLE `ai_api_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `label` varchar(100) NOT NULL,
  `provider` enum('gemini','openai') NOT NULL DEFAULT 'gemini',
  `api_key_encrypted` text NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `usage_count` int(11) DEFAULT 0,
  `last_used_at` datetime DEFAULT NULL,
  `created_by` varchar(100) DEFAULT 'admin',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `ai_api_keys`
INSERT INTO `ai_api_keys` (`id`, `label`, `provider`, `api_key_encrypted`, `is_active`, `usage_count`, `last_used_at`, `created_by`, `created_at`) VALUES
('3', 'Gemini API Key', 'gemini', 'QVEuQWI4Uk42TEh1U0FQRGZ3ajBmZFVtSWZsWnBqNHVVSGxyWUdRdXhpaVB1RXVFWE9GM2c=', '1', '4', '2026-09-02 17:21:24', 'admin', '2026-08-21 17:01:32');

-- --------------------------------------------------------
-- Table structure for `ai_generated_questions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `ai_generated_questions`;
CREATE TABLE `ai_generated_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_id` int(11) NOT NULL,
  `question_text` longtext NOT NULL,
  `option_a` text NOT NULL,
  `option_b` text NOT NULL,
  `option_c` text NOT NULL,
  `option_d` text NOT NULL,
  `correct_option` enum('A','B','C','D') NOT NULL,
  `explanation` longtext DEFAULT NULL,
  `difficulty` enum('easy','medium','hard') DEFAULT 'medium',
  `review_status` enum('pending','approved','rejected','edited') DEFAULT 'pending',
  `approved_question_id` int(11) DEFAULT NULL,
  `admin_notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `batch_id` (`batch_id`),
  KEY `approved_question_id` (`approved_question_id`),
  CONSTRAINT `ai_generated_questions_ibfk_1` FOREIGN KEY (`batch_id`) REFERENCES `ai_question_batches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ai_generated_questions_ibfk_2` FOREIGN KEY (`approved_question_id`) REFERENCES `questions` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `ai_generated_questions`
INSERT INTO `ai_generated_questions` (`id`, `batch_id`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `review_status`, `approved_question_id`, `admin_notes`, `created_at`) VALUES
('1', '1', 'Which Constitutional Amendment Act incorporated the Fundamental Duties into the Constitution of India?', '42nd Constitutional Amendment Act, 1976', '44th Constitutional Amendment Act, 1978', '86th Constitutional Amendment Act, 2002', '73rd Constitutional Amendment Act, 1992', 'A', 'The Fundamental Duties were added to Part IV-A of the Indian Constitution by the 42nd Constitutional Amendment Act in 1976, based on the recommendations of the Swaran Singh Committee. Originally containing 10 duties, an 11th duty was later added by the 86th Amendment in 2002.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:04:35'),
('2', '1', 'Who among the following presided over the historic 1929 Lahore Session of the Indian National Congress, where the resolution for \'Poorna Swaraj\' was adopted?', 'Mahatma Gandhi', 'Jawaharlal Nehru', 'Subhash Chandra Bose', 'Sardar Vallabhbhai Patel', 'B', 'Jawaharlal Nehru presided over the Lahore Session of the Indian National Congress in December 1929. In this landmark session, the Congress passed the \'Poorna Swaraj\' (Complete Independence) resolution and decided to celebrate January 26, 1930, as Independence Day.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:04:35'),
('3', '1', 'Which Peninsular river in India is traditionally referred to as \'Dakshin Ganga\' due to its large size and extent?', 'Krishna', 'Kaveri', 'Godavari', 'Mahanadi', 'C', 'The Godavari is the largest river system in Peninsular India and is commonly known as \'Dakshin Ganga\' or \'Vridha Ganga\'. It originates from Trimbakeshwar in Nashik district, Maharashtra, and drains into the Bay of Bengal.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:04:35'),
('4', '1', 'Under the Minimum Reserve System followed by the Reserve Bank of India (RBI) for issuing currency, what is the minimum value required to be kept in gold?', 'Rs 100 crore', 'Rs 115 crore', 'Rs 200 crore', 'Rs 85 crore', 'B', 'The Reserve Bank of India follows the Minimum Reserve System adopted in 1957, requiring it to maintain total assets worth at least Rs 200 crore. Of this reserve, at least Rs 115 crore must be held in gold bullion or coins, while the remaining Rs 85 crore can be in foreign currencies or securities.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:04:35'),
('5', '1', 'Which of the following was the first wetland in India to be designated as a Ramsar site of international importance in 1981, alongside Keoladeo National Park?', 'Wular Lake', 'Chilika Lake', 'Loktak Lake', 'Vembanad Lake', 'B', 'Chilika Lake in Odisha, along with Keoladeo National Park in Rajasthan, was recognized as India\'s first Ramsar site in October 1981. Chilika is Asia\'s largest brackish water lagoon and a vital biodiversity hotspot for migratory birds.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:04:35'),
('6', '2', 'Pipe A can fill a tank in 12 hours, while Pipe B can fill it in 15 hours. If both pipes are opened together, but Pipe A is closed 3 hours before the tank is completely full, what is the total time taken to fill the tank?', '8 hours 20 minutes', '7 hours 30 minutes', '9 hours', '8 hours 45 minutes', 'A', 'Let the total time taken to fill the tank be t hours. Pipe A works for (t - 3) hours and Pipe B works for t hours. The equation is (t - 3)/12 + t/15 = 1, which simplifies to 5(t - 3) + 4t = 60, giving 9t = 75 or t = 25/3 hours = 8 hours 20 minutes.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:06:29'),
('7', '2', 'Select the most appropriate word to fill in the blank: \'The committee members were unable to reach a _________ decision, as several members held radically divergent views on the proposed budget allocation.\'', 'unanimous', 'tentative', 'ambiguous', 'contentious', 'A', 'The word \'unanimous\' means fully in agreement or supported by everyone. Since members had \'radically divergent views\', they could not reach a complete agreement, making \'unanimous\' the logically correct choice.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:06:29'),
('8', '2', 'Two fair six-sided dice are rolled simultaneously. What is the probability that the sum of the numbers appearing on their top faces is a prime number?', '5/12', '7/12', '1/2', '13/36', 'A', 'The possible prime sums are 2, 3, 5, 7, and 11. The number of favorable outcomes for these sums are 1, 2, 4, 6, and 2 respectively, totaling 15 favorable outcomes out of 36 possible outcomes. Thus, the probability is 15/36 = 5/12.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:06:29'),
('9', '2', 'A square sheet of paper with a side length of 12 cm is folded along its diagonal to form a triangle. It is then folded again along the altitude of this triangle to form a smaller triangle. What is the surface area of the final folded triangle in cm²?', '18', '36', '72', '24', 'B', 'The original area of the square is 12 × 12 = 144 cm². Folding it once along the diagonal halves its area to 72 cm², and folding it a second time halves the area again to 36 cm².', 'medium', 'pending', NULL, NULL, '2026-08-21 17:06:29'),
('10', '2', 'A train traveling at a uniform speed of 72 km/h crosses a 200-meter-long platform in 22 seconds. How long will it take for the same train to cross a person standing still on the platform?', '10 seconds', '12 seconds', '14 seconds', '15 seconds', 'B', 'Converting speed to m/s: 72 × (5/18) = 20 m/s. The total distance covered crossing the platform is (Length of train + 200) = Speed × Time = 20 × 22 = 440 m, so the train length is 240 m. To cross a standing person, the time taken is Distance/Speed = 240 / 20 = 12 seconds.', 'medium', 'pending', NULL, NULL, '2026-08-21 17:06:29'),
('11', '3', 'A 55-year-old male with long-standing rheumatoid arthritis undergoes a renal biopsy due to progressive proteinuria. Microscopic examination demonstrates extracellular amorphous eosinophilic deposits in the glomeruli. Which of the following special stains will display apple-green birefringence under polarized light for this biopsy sample?', 'Congo Red', 'Masson Trichrome', 'Periodic acid–Schiff (PAS)', 'Oil Red O', 'A', 'Congo red stain is specific for amyloid deposits, which appear pink-red under light microscopy. Under polarized light, Congo red-stained amyloid exhibits pathognomonic apple-green birefringence due to its beta-pleated sheet conformation. This is a classic finding in secondary (AA) amyloidosis associated with chronic inflammatory conditions.', 'medium', 'approved', '24', NULL, '2026-09-02 17:21:24'),
('12', '3', 'Which of the following G-protein subunits is correctly paired with its downstream second messenger mechanism?', 'Gs – Inhibition of adenylyl cyclase, decreasing cAMP', 'Gi – Stimulation of adenylyl cyclase, increasing cAMP', 'Gq – Activation of phospholipase C, increasing IP3 and DAG', 'G12/13 – Direct activation of guanylyl cyclase, increasing cGMP', 'C', 'Gq proteins activate phospholipase C (PLC), which cleaves membrane phosphatidylinositol 4,5-bisphosphate (PIP2) into inositol trisphosphate (IP3) and diacylglycerol (DAG). IP3 increases intracellular calcium release, while DAG activates protein kinase C. Conversely, Gs stimulates adenylyl cyclase while Gi inhibits it.', 'medium', 'approved', '25', NULL, '2026-09-02 17:21:24'),
('13', '3', 'A newly developed diagnostic test for Malaria is evaluated on 1,000 individuals. It correctly identifies 180 out of 200 diseased individuals as positive, and 720 out of 800 non-diseased individuals as negative. What is the sensitivity of this diagnostic test?', '90%', '80%', '72%', '85%', 'A', 'Sensitivity is defined as the proportion of diseased individuals who test positive [True Positives / (True Positives + False Negatives)]. In this case, 180 diseased individuals tested positive out of 200 total diseased individuals, giving a sensitivity of 180/200 = 0.90 or 90%.', 'medium', 'approved', '26', NULL, '2026-09-02 17:21:24'),
('14', '3', 'During the absolute refractory period of a neuronal action potential, a second action potential cannot be elicited regardless of stimulus intensity. Which mechanism primarily accounts for this phenomenon?', 'Persistent open state of voltage-gated potassium channels', 'Inactivated state of voltage-gated sodium channels', 'Complete closure of ligand-gated chloride channels', 'Maximal stimulation of the Na+/K+ ATPase pump', 'B', 'The absolute refractory period is caused by the inactivation gate of voltage-gated sodium channels remaining closed following rapid depolarization. Until the membrane repolarizes sufficiently to allow these channels to transition back to their closed-rested state, no new action potential can be triggered.', 'medium', 'approved', '27', NULL, '2026-09-02 17:21:24'),
('15', '3', 'A 6-year-old child presents with severe photosensitivity, freckling, and early onset of skin neoplasms on sun-exposed areas. A diagnosis of Xeroderma Pigmentosum is established. Which of the following DNA repair mechanisms is defective in this patient?', 'Base Excision Repair', 'Mismatch Repair', 'Nucleotide Excision Repair', 'Non-Homologous End Joining', 'C', 'Xeroderma Pigmentosum is an autosomal recessive genetic disorder caused by mutations in genes responsible for Nucleotide Excision Repair (NER). NER is critical for recognizing and removing bulky DNA lesions, such as pyrimidine dimers caused by ultraviolet (UV) radiation exposure.', 'medium', 'approved', '28', NULL, '2026-09-02 17:21:24');

-- --------------------------------------------------------
-- Table structure for `ai_question_batches`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `ai_question_batches`;
CREATE TABLE `ai_question_batches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ai_key_id` int(11) DEFAULT NULL,
  `exam_id` int(11) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `section_name` varchar(100) DEFAULT NULL,
  `difficulty` enum('easy','medium','hard') DEFAULT 'medium',
  `language` varchar(10) DEFAULT 'en',
  `count_requested` int(11) DEFAULT 5,
  `count_generated` int(11) DEFAULT 0,
  `count_approved` int(11) DEFAULT 0,
  `status` enum('pending','completed','error','partial') DEFAULT 'pending',
  `prompt_text` text DEFAULT NULL,
  `raw_response` longtext DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `ai_key_id` (`ai_key_id`),
  KEY `exam_id` (`exam_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `ai_question_batches_ibfk_1` FOREIGN KEY (`ai_key_id`) REFERENCES `ai_api_keys` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ai_question_batches_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ai_question_batches_ibfk_3` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `ai_question_batches`
INSERT INTO `ai_question_batches` (`id`, `ai_key_id`, `exam_id`, `subject_id`, `section_name`, `difficulty`, `language`, `count_requested`, `count_generated`, `count_approved`, `status`, `prompt_text`, `raw_response`, `error_message`, `created_at`) VALUES
('1', '3', NULL, NULL, 'General', 'medium', 'en', '5', '5', '0', 'completed', 'You are an expert MCQ question setter for Indian competitive exams. Generate exactly 5 multiple choice questions for:\n- Exam: Indian Competitive Exam\n- Subject/Section: General\n- Difficulty: medium\n- Language: English\n\nRULES:\n1. Questions must be relevant, accurate, and exam-appropriate\n2. Each question must have exactly 4 options (A, B, C, D)\n3. Only one correct answer per question\n4. Include a clear 2-3 sentence explanation\n\nRespond with ONLY a valid JSON array (no markdown, no text outside the array):\n[\n  {\n    \"question_text\": \"Question here?\",\n    \"option_a\": \"First option\",\n    \"option_b\": \"Second option\",\n    \"option_c\": \"Third option\",\n    \"option_d\": \"Fourth option\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"Explanation here.\",\n    \"difficulty\": \"medium\"\n  }\n]\n\nGenerate 5 questions now:', '[\n  {\n    \"question_text\": \"Which Constitutional Amendment Act incorporated the Fundamental Duties into the Constitution of India?\",\n    \"option_a\": \"42nd Constitutional Amendment Act, 1976\",\n    \"option_b\": \"44th Constitutional Amendment Act, 1978\",\n    \"option_c\": \"86th Constitutional Amendment Act, 2002\",\n    \"option_d\": \"73rd Constitutional Amendment Act, 1992\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"The Fundamental Duties were added to Part IV-A of the Indian Constitution by the 42nd Constitutional Amendment Act in 1976, based on the recommendations of the Swaran Singh Committee. Originally containing 10 duties, an 11th duty was later added by the 86th Amendment in 2002.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"Who among the following presided over the historic 1929 Lahore Session of the Indian National Congress, where the resolution for \'Poorna Swaraj\' was adopted?\",\n    \"option_a\": \"Mahatma Gandhi\",\n    \"option_b\": \"Jawaharlal Nehru\",\n    \"option_c\": \"Subhash Chandra Bose\",\n    \"option_d\": \"Sardar Vallabhbhai Patel\",\n    \"correct_option\": \"B\",\n    \"explanation\": \"Jawaharlal Nehru presided over the Lahore Session of the Indian National Congress in December 1929. In this landmark session, the Congress passed the \'Poorna Swaraj\' (Complete Independence) resolution and decided to celebrate January 26, 1930, as Independence Day.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"Which Peninsular river in India is traditionally referred to as \'Dakshin Ganga\' due to its large size and extent?\",\n    \"option_a\": \"Krishna\",\n    \"option_b\": \"Kaveri\",\n    \"option_c\": \"Godavari\",\n    \"option_d\": \"Mahanadi\",\n    \"correct_option\": \"C\",\n    \"explanation\": \"The Godavari is the largest river system in Peninsular India and is commonly known as \'Dakshin Ganga\' or \'Vridha Ganga\'. It originates from Trimbakeshwar in Nashik district, Maharashtra, and drains into the Bay of Bengal.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"Under the Minimum Reserve System followed by the Reserve Bank of India (RBI) for issuing currency, what is the minimum value required to be kept in gold?\",\n    \"option_a\": \"Rs 100 crore\",\n    \"option_b\": \"Rs 115 crore\",\n    \"option_c\": \"Rs 200 crore\",\n    \"option_d\": \"Rs 85 crore\",\n    \"correct_option\": \"B\",\n    \"explanation\": \"The Reserve Bank of India follows the Minimum Reserve System adopted in 1957, requiring it to maintain total assets worth at least Rs 200 crore. Of this reserve, at least Rs 115 crore must be held in gold bullion or coins, while the remaining Rs 85 crore can be in foreign currencies or securities.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"Which of the following was the first wetland in India to be designated as a Ramsar site of international importance in 1981, alongside Keoladeo National Park?\",\n    \"option_a\": \"Wular Lake\",\n    \"option_b\": \"Chilika Lake\",\n    \"option_c\": \"Loktak Lake\",\n    \"option_d\": \"Vembanad Lake\",\n    \"correct_option\": \"B\",\n    \"explanation\": \"Chilika Lake in Odisha, along with Keoladeo National Park in Rajasthan, was recognized as India\'s first Ramsar site in October 1981. Chilika is Asia\'s largest brackish water lagoon and a vital biodiversity hotspot for migratory birds.\",\n    \"difficulty\": \"medium\"\n  }\n]', NULL, '2026-08-21 17:04:24'),
('2', '3', '127', NULL, 'General', 'medium', 'en', '5', '5', '0', 'completed', 'You are an expert MCQ question setter for Indian competitive exams. Generate exactly 5 multiple choice questions for:\n- Exam: GATE CSE\n- Subject/Section: General\n- Difficulty: medium\n- Language: English\n\nRULES:\n1. Questions must be relevant, accurate, and exam-appropriate\n2. Each question must have exactly 4 options (A, B, C, D)\n3. Only one correct answer per question\n4. Include a clear 2-3 sentence explanation\n\nRespond with ONLY a valid JSON array (no markdown, no text outside the array):\n[\n  {\n    \"question_text\": \"Question here?\",\n    \"option_a\": \"First option\",\n    \"option_b\": \"Second option\",\n    \"option_c\": \"Third option\",\n    \"option_d\": \"Fourth option\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"Explanation here.\",\n    \"difficulty\": \"medium\"\n  }\n]\n\nGenerate 5 questions now:', '[\n  {\n    \"question_text\": \"Pipe A can fill a tank in 12 hours, while Pipe B can fill it in 15 hours. If both pipes are opened together, but Pipe A is closed 3 hours before the tank is completely full, what is the total time taken to fill the tank?\",\n    \"option_a\": \"8 hours 20 minutes\",\n    \"option_b\": \"7 hours 30 minutes\",\n    \"option_c\": \"9 hours\",\n    \"option_d\": \"8 hours 45 minutes\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"Let the total time taken to fill the tank be t hours. Pipe A works for (t - 3) hours and Pipe B works for t hours. The equation is (t - 3)/12 + t/15 = 1, which simplifies to 5(t - 3) + 4t = 60, giving 9t = 75 or t = 25/3 hours = 8 hours 20 minutes.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"Select the most appropriate word to fill in the blank: \'The committee members were unable to reach a _________ decision, as several members held radically divergent views on the proposed budget allocation.\'\",\n    \"option_a\": \"unanimous\",\n    \"option_b\": \"tentative\",\n    \"option_c\": \"ambiguous\",\n    \"option_d\": \"contentious\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"The word \'unanimous\' means fully in agreement or supported by everyone. Since members had \'radically divergent views\', they could not reach a complete agreement, making \'unanimous\' the logically correct choice.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"Two fair six-sided dice are rolled simultaneously. What is the probability that the sum of the numbers appearing on their top faces is a prime number?\",\n    \"option_a\": \"5/12\",\n    \"option_b\": \"7/12\",\n    \"option_c\": \"1/2\",\n    \"option_d\": \"13/36\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"The possible prime sums are 2, 3, 5, 7, and 11. The number of favorable outcomes for these sums are 1, 2, 4, 6, and 2 respectively, totaling 15 favorable outcomes out of 36 possible outcomes. Thus, the probability is 15/36 = 5/12.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"A square sheet of paper with a side length of 12 cm is folded along its diagonal to form a triangle. It is then folded again along the altitude of this triangle to form a smaller triangle. What is the surface area of the final folded triangle in cm²?\",\n    \"option_a\": \"18\",\n    \"option_b\": \"36\",\n    \"option_c\": \"72\",\n    \"option_d\": \"24\",\n    \"correct_option\": \"B\",\n    \"explanation\": \"The original area of the square is 12 × 12 = 144 cm². Folding it once along the diagonal halves its area to 72 cm², and folding it a second time halves the area again to 36 cm².\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"A train traveling at a uniform speed of 72 km/h crosses a 200-meter-long platform in 22 seconds. How long will it take for the same train to cross a person standing still on the platform?\",\n    \"option_a\": \"10 seconds\",\n    \"option_b\": \"12 seconds\",\n    \"option_c\": \"14 seconds\",\n    \"option_d\": \"15 seconds\",\n    \"correct_option\": \"B\",\n    \"explanation\": \"Converting speed to m/s: 72 × (5/18) = 20 m/s. The total distance covered crossing the platform is (Length of train + 200) = Speed × Time = 20 × 22 = 440 m, so the train length is 240 m. To cross a standing person, the time taken is Distance/Speed = 240 / 20 = 12 seconds.\",\n    \"difficulty\": \"medium\"\n  }\n]', NULL, '2026-08-21 17:06:15'),
('3', '3', '114', NULL, 'General', 'medium', 'en', '5', '5', '5', 'completed', 'You are an expert MCQ question setter for Indian competitive exams. Generate exactly 5 multiple choice questions for:\r\n- Exam: AIIMS PG Entrance\r\n- Subject/Section: General\r\n- Difficulty: medium\r\n- Language: English\r\n\r\nRULES:\r\n1. Questions must be relevant, accurate, and exam-appropriate\r\n2. Each question must have exactly 4 options (A, B, C, D)\r\n3. Only one correct answer per question\r\n4. Include a clear 2-3 sentence explanation\r\n\r\nRespond with ONLY a valid JSON array (no markdown, no text outside the array):\r\n[\r\n  {\r\n    \"question_text\": \"Question here?\",\r\n    \"option_a\": \"First option\",\r\n    \"option_b\": \"Second option\",\r\n    \"option_c\": \"Third option\",\r\n    \"option_d\": \"Fourth option\",\r\n    \"correct_option\": \"A\",\r\n    \"explanation\": \"Explanation here.\",\r\n    \"difficulty\": \"medium\"\r\n  }\r\n]\r\n\r\nGenerate 5 questions now:', '[\n  {\n    \"question_text\": \"A 55-year-old male with long-standing rheumatoid arthritis undergoes a renal biopsy due to progressive proteinuria. Microscopic examination demonstrates extracellular amorphous eosinophilic deposits in the glomeruli. Which of the following special stains will display apple-green birefringence under polarized light for this biopsy sample?\",\n    \"option_a\": \"Congo Red\",\n    \"option_b\": \"Masson Trichrome\",\n    \"option_c\": \"Periodic acid–Schiff (PAS)\",\n    \"option_d\": \"Oil Red O\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"Congo red stain is specific for amyloid deposits, which appear pink-red under light microscopy. Under polarized light, Congo red-stained amyloid exhibits pathognomonic apple-green birefringence due to its beta-pleated sheet conformation. This is a classic finding in secondary (AA) amyloidosis associated with chronic inflammatory conditions.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"Which of the following G-protein subunits is correctly paired with its downstream second messenger mechanism?\",\n    \"option_a\": \"Gs – Inhibition of adenylyl cyclase, decreasing cAMP\",\n    \"option_b\": \"Gi – Stimulation of adenylyl cyclase, increasing cAMP\",\n    \"option_c\": \"Gq – Activation of phospholipase C, increasing IP3 and DAG\",\n    \"option_d\": \"G12/13 – Direct activation of guanylyl cyclase, increasing cGMP\",\n    \"correct_option\": \"C\",\n    \"explanation\": \"Gq proteins activate phospholipase C (PLC), which cleaves membrane phosphatidylinositol 4,5-bisphosphate (PIP2) into inositol trisphosphate (IP3) and diacylglycerol (DAG). IP3 increases intracellular calcium release, while DAG activates protein kinase C. Conversely, Gs stimulates adenylyl cyclase while Gi inhibits it.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"A newly developed diagnostic test for Malaria is evaluated on 1,000 individuals. It correctly identifies 180 out of 200 diseased individuals as positive, and 720 out of 800 non-diseased individuals as negative. What is the sensitivity of this diagnostic test?\",\n    \"option_a\": \"90%\",\n    \"option_b\": \"80%\",\n    \"option_c\": \"72%\",\n    \"option_d\": \"85%\",\n    \"correct_option\": \"A\",\n    \"explanation\": \"Sensitivity is defined as the proportion of diseased individuals who test positive [True Positives / (True Positives + False Negatives)]. In this case, 180 diseased individuals tested positive out of 200 total diseased individuals, giving a sensitivity of 180/200 = 0.90 or 90%.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"During the absolute refractory period of a neuronal action potential, a second action potential cannot be elicited regardless of stimulus intensity. Which mechanism primarily accounts for this phenomenon?\",\n    \"option_a\": \"Persistent open state of voltage-gated potassium channels\",\n    \"option_b\": \"Inactivated state of voltage-gated sodium channels\",\n    \"option_c\": \"Complete closure of ligand-gated chloride channels\",\n    \"option_d\": \"Maximal stimulation of the Na+/K+ ATPase pump\",\n    \"correct_option\": \"B\",\n    \"explanation\": \"The absolute refractory period is caused by the inactivation gate of voltage-gated sodium channels remaining closed following rapid depolarization. Until the membrane repolarizes sufficiently to allow these channels to transition back to their closed-rested state, no new action potential can be triggered.\",\n    \"difficulty\": \"medium\"\n  },\n  {\n    \"question_text\": \"A 6-year-old child presents with severe photosensitivity, freckling, and early onset of skin neoplasms on sun-exposed areas. A diagnosis of Xeroderma Pigmentosum is established. Which of the following DNA repair mechanisms is defective in this patient?\",\n    \"option_a\": \"Base Excision Repair\",\n    \"option_b\": \"Mismatch Repair\",\n    \"option_c\": \"Nucleotide Excision Repair\",\n    \"option_d\": \"Non-Homologous End Joining\",\n    \"correct_option\": \"C\",\n    \"explanation\": \"Xeroderma Pigmentosum is an autosomal recessive genetic disorder caused by mutations in genes responsible for Nucleotide Excision Repair (NER). NER is critical for recognizing and removing bulky DNA lesions, such as pyrimidine dimers caused by ultraviolet (UV) radiation exposure.\",\n    \"difficulty\": \"medium\"\n  }\n]', NULL, '2026-09-02 17:21:05');

-- --------------------------------------------------------
-- Table structure for `attempt_answers`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `attempt_answers`;
CREATE TABLE `attempt_answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attempt_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `selected_option_key` varchar(10) DEFAULT NULL,
  `numerical_answer` varchar(100) DEFAULT NULL,
  `is_marked_for_review` tinyint(1) DEFAULT 0,
  `is_answered` tinyint(1) DEFAULT 0,
  `is_correct` tinyint(1) DEFAULT NULL,
  `marks_awarded` decimal(5,2) DEFAULT 0.00,
  `time_spent_seconds` int(11) DEFAULT 0,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `attempt_q` (`attempt_id`,`question_id`),
  KEY `question_id` (`question_id`),
  CONSTRAINT `attempt_answers_ibfk_1` FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attempt_answers_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=143 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `attempt_answers`
INSERT INTO `attempt_answers` (`id`, `attempt_id`, `question_id`, `selected_option_key`, `numerical_answer`, `is_marked_for_review`, `is_answered`, `is_correct`, `marks_awarded`, `time_spent_seconds`, `updated_at`) VALUES
('92', '5', '1', NULL, NULL, '0', '0', NULL, '0.00', '45', '2026-09-05 12:27:07'),
('95', '7', '1', 'A', NULL, '0', '1', '0', '-0.50', '45', '2026-09-09 12:10:04'),
('96', '8', '1', 'A', NULL, '0', '1', '0', '-0.50', '45', '2026-09-09 12:10:24'),
('97', '9', '1', 'A', NULL, '0', '1', '0', '-0.50', '45', '2026-09-09 12:11:22'),
('98', '10', '1', 'B', NULL, '0', '1', '1', '2.00', '0', '2026-09-09 12:40:05'),
('99', '10', '6', 'B', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('100', '10', '2', 'C', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('101', '10', '7', 'D', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('102', '10', '3', 'C', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('103', '10', '8', 'B', NULL, '0', '1', '1', '2.00', '0', '2026-09-09 12:40:05'),
('104', '10', '4', 'B', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('105', '10', '9', 'D', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('106', '10', '5', 'C', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('107', '10', '10', 'B', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('108', '10', '11', 'A', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('109', '10', '12', 'C', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('110', '10', '13', 'B', NULL, '0', '1', '1', '2.00', '0', '2026-09-09 12:40:05'),
('111', '10', '14', 'C', NULL, '0', '1', '1', '2.00', '0', '2026-09-09 12:40:05'),
('112', '10', '15', 'B', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('113', '10', '16', 'C', NULL, '0', '1', '1', '2.00', '0', '2026-09-09 12:40:05'),
('114', '10', '17', 'B', NULL, '0', '1', '1', '2.00', '1', '2026-09-09 12:40:05'),
('115', '10', '18', 'B', NULL, '0', '1', '0', '-0.50', '1', '2026-09-09 12:40:05'),
('116', '10', '19', 'C', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('117', '10', '20', 'D', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('118', '10', '21', 'B', NULL, '0', '1', '0', '-0.50', '0', '2026-09-09 12:40:05'),
('119', '10', '22', 'B', NULL, '0', '1', '1', '2.00', '1', '2026-09-09 12:40:05'),
('142', '11', '1', 'A', NULL, '0', '1', '0', '-0.50', '45', '2026-09-09 12:57:05');

-- --------------------------------------------------------
-- Table structure for `attempt_questions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `attempt_questions`;
CREATE TABLE `attempt_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attempt_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `question_order` int(11) NOT NULL,
  `section_id` int(11) DEFAULT NULL,
  `positive_marks` decimal(5,2) NOT NULL DEFAULT 2.00,
  `negative_marks` decimal(5,2) NOT NULL DEFAULT 0.50,
  `option_order` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `attempt_question_unique` (`attempt_id`,`question_id`),
  KEY `idx_aq_attempt_order` (`attempt_id`,`question_order`),
  KEY `idx_aq_question` (`question_id`),
  CONSTRAINT `attempt_questions_ibfk_1` FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `attempt_questions_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `career_pathways`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `career_pathways`;
CREATE TABLE `career_pathways` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` enum('after_10th','after_12th','after_graduation','private_jobs','upskilling') NOT NULL,
  `title` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `short_description` text NOT NULL,
  `full_roadmap` longtext NOT NULL,
  `recommended_courses` text DEFAULT NULL,
  `top_careers` text DEFAULT NULL,
  `scholarships_info` text DEFAULT NULL,
  `icon_name` varchar(50) DEFAULT 'work',
  `status` enum('active','draft') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `career_pathways`
INSERT INTO `career_pathways` (`id`, `category`, `title`, `slug`, `short_description`, `full_roadmap`, `recommended_courses`, `top_careers`, `scholarships_info`, `icon_name`, `status`, `created_at`) VALUES
('1', 'after_10th', 'Diploma in Engineering (Polytechnic)', 'diploma-engineering-polytechnic', 'Direct practical pathway into technical roles (JE) in SSC, Railways, and PSUs after 10th.', 'Step 1: Appear for State Polytechnic Entrance Exam (JEECUP, Bihar DCECE, etc.).\nStep 2: Complete 3-Year Diploma in Civil/Mechanical/Electrical Engineering.\nStep 3: Eligible for Railway Junior Engineer (RRB JE), SSC JE, and State Electricity Boards.', 'Diploma in Civil, Mechanical, Electrical, Computer Science', 'RRB Junior Engineer, SSC JE, Technician in BHEL/NTPC', 'AICTE Pragati Scholarship for Girls, State Post-Matric Scholarships', 'engineering', 'active', '2026-08-31 14:37:37'),
('2', 'after_12th', 'NDA & Armed Forces Officer Entry', 'nda-armed-forces-entry', 'Prestigious career leading directly to Commissioned Officer rank in Army, Navy & Air Force.', 'Step 1: Clear NDA written exam conducted twice a year by UPSC.\nStep 2: 5-Day SSB Interview & Medical Examination.\nStep 3: 3 Years training at NDA Khadakwasla + 1 Year at IMA/INA/AFA.', 'Physics, Chemistry & Math in 12th; SSB Interview Preparation', 'Lieutenant in Indian Army, Flying Officer in IAF, Sub Lieutenant in Navy', 'Armed Forces Personnel Welfare Fund Subsidies', 'military_tech', 'active', '2026-08-31 14:37:37'),
('3', 'after_12th', 'SSC CHSL & Railway NTPC (Undergraduate)', 'ssc-chsl-railway-undergraduate', 'Fastest clerical and assistant entry in Central Government departments straight after 12th.', 'Step 1: Target SSC CHSL (LDC, DEO, JSA) & RRB NTPC (Undergraduate posts).\nStep 2: Prepare Quantitative Aptitude, Reasoning, English, and General Awareness.\nStep 3: Clear Tier 1 Computer Based Test & Tier 2 Skill/Typing Test.', 'Speed Math, General Studies Capsule, English Error Spotting', 'Lower Division Clerk (LDC), Data Entry Operator (DEO), Commercial Cum Ticket Clerk', 'Central Sector Scheme of Scholarships for College & University Students', 'account_balance', 'active', '2026-08-31 14:37:37'),
('4', 'after_graduation', 'Civil Services (UPSC CSE & State PSCs)', 'civil-services-upsc-state-psc', 'Top administrative leadership roles shaping public policy, district administration, and governance.', 'Step 1: Preliminary Exam (GS Paper 1 + CSAT).\nStep 2: Main Examination (9 Descriptive Papers) + Optional Subject.\nStep 3: Personality Test (Interview) by UPSC Board.', 'NCERT Foundation, Indian Polity (Laxmikanth), Daily Current Affairs & Editorial Analysis', 'IAS (District Magistrate), IPS (Superintendent of Police), IFS, IRS', 'State Government Incentive Schemes for UPSC Prelims Qualified Candidates (e.g., Mukhyamantri Abhyudaya)', 'gavel', 'active', '2026-08-31 14:37:37'),
('5', 'private_jobs', 'Full Stack & Software Engineering Assessments', 'full-stack-software-engineering', 'High-growth tech careers in top MNCs & startups with aptitude and coding evaluation.', 'Step 1: Master Data Structures, Algorithms (LeetCode/Hackerrank medium standard).\nStep 2: Build 2-3 Production Projects (React/Node/Python/Java).\nStep 3: Crack Company Technical Screening & System Design Interviews.', 'Data Structures in Java/C++, Modern Web Development, System Design Basics', 'Software Development Engineer (SDE-1), Frontend Engineer, Backend Developer', 'Bootcamp Income Share Agreements (ISAs) & Merit Sponsorships', 'code', 'active', '2026-08-31 14:37:37'),
('6', 'upskilling', 'Practical Data Analytics & Advanced Excel/MIS', 'data-analytics-excel-mis', 'Essential business analytical skills high in demand across government PSUs, banks, and corporates.', 'Step 1: Learn Advanced Excel (VLOOKUP, INDEX/MATCH, Pivot Tables, Power Query).\nStep 2: SQL Data Querying & Data Visualization (Power BI / Tableau).\nStep 3: Complete Real-World Sales & Financial Dashboard Projects.', 'Excel to Power BI Masterclass, SQL for Data Analysis, MIS Reporting', 'Data Analyst, MIS Executive, Operations Analyst, Business Intelligence Specialist', 'Free Digital India Skilling Certificates (NPTEL / Swayam)', 'bar_chart', 'active', '2026-08-31 14:37:37');

-- --------------------------------------------------------
-- Table structure for `challenge_registrations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `challenge_registrations`;
CREATE TABLE `challenge_registrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `challenge_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `registered_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_challenge` (`challenge_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `challenge_registrations_ibfk_1` FOREIGN KEY (`challenge_id`) REFERENCES `monthly_challenges` (`id`) ON DELETE CASCADE,
  CONSTRAINT `challenge_registrations_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `chapters`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `chapters`;
CREATE TABLE `chapters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `chapters_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `chapters`
INSERT INTO `chapters` (`id`, `subject_id`, `name`) VALUES
('1', '1', 'Percentage & Ratio'),
('2', '1', 'Profit & Loss'),
('3', '2', 'Coding-Decoding'),
('4', '2', 'Syllogism'),
('5', '3', 'Grammar & Error Spotting'),
('6', '4', 'Indian Polity & Constitution');

-- --------------------------------------------------------
-- Table structure for `creator_payouts`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `creator_payouts`;
CREATE TABLE `creator_payouts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `creator_id` int(11) NOT NULL,
  `amount_requested` decimal(12,2) NOT NULL,
  `amount_paid` decimal(12,2) DEFAULT 0.00,
  `status` enum('requested','processing','completed','rejected') DEFAULT 'requested',
  `payout_method` varchar(50) DEFAULT 'upi',
  `transaction_reference` varchar(200) DEFAULT NULL,
  `admin_notes` text DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `processed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `creator_id` (`creator_id`),
  CONSTRAINT `creator_payouts_ibfk_1` FOREIGN KEY (`creator_id`) REFERENCES `creators` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `creators`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `creators`;
CREATE TABLE `creators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `display_name` varchar(150) NOT NULL,
  `about` text DEFAULT NULL,
  `upi_id` varchar(100) DEFAULT NULL,
  `bank_account_number` varchar(50) DEFAULT NULL,
  `bank_ifsc` varchar(20) DEFAULT NULL,
  `bank_account_name` varchar(150) DEFAULT NULL,
  `total_earnings` decimal(12,2) DEFAULT 0.00,
  `pending_payout` decimal(12,2) DEFAULT 0.00,
  `paid_out` decimal(12,2) DEFAULT 0.00,
  `platform_commission_pct` decimal(5,2) DEFAULT 20.00,
  `verification_status` enum('pending','approved','rejected','suspended') DEFAULT 'pending',
  `verified_at` datetime DEFAULT NULL,
  `total_materials` int(11) DEFAULT 0,
  `total_sales` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `creators_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `current_affairs`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `current_affairs`;
CREATE TABLE `current_affairs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `category` varchar(100) DEFAULT 'General',
  `publish_date` date NOT NULL,
  `content_body` longtext NOT NULL,
  `pdf_url` varchar(255) DEFAULT NULL,
  `is_published` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `summary` text DEFAULT NULL,
  `exam_relevance` varchar(255) DEFAULT NULL,
  `source_name` varchar(150) DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL,
  `read_time_minutes` int(11) DEFAULT 3,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `current_affairs`
INSERT INTO `current_affairs` (`id`, `title`, `category`, `publish_date`, `content_body`, `pdf_url`, `is_published`, `created_at`, `summary`, `exam_relevance`, `source_name`, `image_url`, `tags`, `read_time_minutes`) VALUES
('1', 'Reserve Bank of India Keeps Repo Rate Unchanged at 6.5%', 'Banking & Economy', '2026-08-20', 'The Monetary Policy Committee (MPC) of the Reserve Bank of India has decided to maintain the repo rate at 6.50% to maintain inflation target alignment.', NULL, '1', '2026-08-21 14:22:31', NULL, NULL, NULL, NULL, NULL, '3'),
('2', 'National Space Day Celebrations Highlight Gaganyaan Progress', 'Science & Tech', '2026-08-21', 'ISRO announces successful test fire of human-rated Vikas engine for upcoming Gaganyaan crewed spaceflight program.', NULL, '1', '2026-08-21 14:22:31', NULL, NULL, NULL, NULL, NULL, '3'),
('3', 'Reserve Bank of India Keeps Repo Rate Unchanged at 6.5% for Ninth Consecutive Time', 'Banking & Economy', '2026-08-21', 'The Reserve Bank of India\'s (RBI) Monetary Policy Committee (MPC) announced its bi-monthly monetary policy decision, keeping the policy repo rate unchanged at 6.50% for the ninth consecutive meeting.\n\nKey Highlights of the Policy:\n1. Repo Rate & Stance: Repo rate stays at 6.50%. The standing deposit facility (SDF) rate remains at 6.25%, and the marginal standing facility (MSF) rate and Bank Rate at 6.75%. The committee decided to remain focused on the \'Withdrawal of Accommodation\' to ensure that inflation aligns with the target while supporting growth.\n\n2. Inflation & GDP Forecast: Real GDP growth for FY25 is projected at 7.2%, with Q1 at 7.1%, Q2 at 7.2%, Q3 at 7.3%, and Q4 at 7.2%. CPI inflation for FY25 is projected at 4.5%.\n\n3. Regulatory Announcements: The RBI announced an increase in the limit for tax payments through UPI from ₹1 lakh to ₹5 lakh per transaction to enhance digital adoption.\n\n4. Global Context: The decision comes amidst persistent food inflation pressures in the domestic market and economic uncertainties across advanced economies.', NULL, '1', '2026-08-21 17:25:57', 'The Monetary Policy Committee (MPC) of the Reserve Bank of India, headed by Governor Shaktikanta Das, decided by a 4:2 majority to keep the benchmark policy repo rate unchanged at 6.50%. The standing deposit facility (SDF) rate remains at 6.25% and marginal standing facility (MSF) at 6.75%. Inflation target remains anchored at 4%.', 'UPSC CSE (GS-3 Economy), RBI Grade B, SBI PO, IBPS PO, SSC CGL', 'RBI Official Press Release / The Hindu', 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800', 'Monetary Policy, Repo Rate, RBI, Inflation, Banking', '3'),
('4', 'ISRO Successfully Tests Human-Rated Cryogenic Stage for Gaganyaan Mission', 'Science & Technology', '2026-08-21', 'The Indian Space Research Organisation (ISRO) has accomplished the critical human-rating qualification for the CE20 cryogenic engine, paving the way for the maiden uncrewed and subsequent crewed Gaganyaan missions.\n\nTechnical Overview:\n1. Engine & Testing: The CE20 cryogenic engine was tested at the ISRO Propulsion Complex (IPRC) in Mahendragiri, Tamil Nadu. The engine underwent rigorous vacuum testing, hot tests for extended durations, and simulated flight acceptance tests.\n\n2. Crew Module Readiness: The Gaganyaan project envisages demonstrating human spaceflight capability to Low Earth Orbit (LEO) of 400 km for a 3-day mission with a crew of 3 members, safely returning them to Indian waters.\n\n3. Significance: India aims to become only the fourth nation in the world—after the United States, Russia, and China—to send humans into space independently.', NULL, '1', '2026-08-21 17:25:57', 'The Indian Space Research Organisation (ISRO) has achieved a major milestone by human-rating its CE20 cryogenic engine that powers the cryogenic stage of the human-rated LVM3 launch vehicle for India\'s maiden human spaceflight mission, Gaganyaan.', 'UPSC CSE (GS-3 Space & Tech), SSC CGL Science, State PSCs, NDA/CDS', 'ISRO / Press Information Bureau', 'https://images.unsplash.com/photo-1517976487504-59a1a04d20d6?w=800', 'ISRO, Gaganyaan, Space Technology, Cryogenic Engine, LVM3', '4'),
('5', 'India and European Union Launch 8th Round of Free Trade Agreement (FTA) Negotiations in Brussels', 'International Relations', '2026-08-20', 'Negotiators from India and the European Union held the eighth round of talks for the proposed India-EU Free Trade Agreement (FTA) in Brussels, focusing on goods, services, rules of origin, and digital trade.\n\nCore Discussion Areas:\n1. Market Access & Tariff Reduction: Discussions covered tariff reductions on key Indian exports, including textiles, leather, marine products, and chemicals, alongside European automobiles, wines, and spirits.\n\n2. Carbon Border Adjustment Mechanism (CBAM): India raised concerns regarding the EU\'s Carbon Border Adjustment Mechanism and its potential impact on Indian steel and aluminum exports.\n\n3. Strategic Partnership: The EU is India\'s second-largest trading partner after the US. Concluding the FTA will significantly boost bilateral trade beyond the current $130+ billion threshold and strengthen supply chain resilience.', NULL, '1', '2026-08-21 17:25:57', 'India and the European Union concluded extensive discussions during the 8th round of negotiations for the comprehensive Free Trade Agreement (FTA), Investment Protection Agreement (IPA), and Geographical Indications (GIs) Agreement in Brussels.', 'UPSC CSE (GS-2 International Relations), SSC CGL, State PSCs', 'Ministry of Commerce & Industry / Reuters', 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=800', 'India-EU, Free Trade Agreement, International Trade, CBAM, Diplomacy', '4'),
('6', 'India Adds 3 New Ramsar Sites, Taking Total Wetland Count to 85', 'Environment & Ecology', '2026-08-19', 'India\'s Ministry of Environment, Forest and Climate Change announced the designation of three additional wetlands under the Ramsar Convention on Wetlands of International Importance.\n\nKey Details of the New Sites:\n1. Nanjarayan Bird Sanctuary: Located in Tirupur district, Tamil Nadu, home to over 130 bird species and a critical stopover on the Central Asian Flyway.\n\n2. Kazhuveli Bird Sanctuary: Located in Villupuram district, Tamil Nadu, recognized as one of the largest brackish water wetlands in South India.\n\n3. Tawa Reservoir: Located in Narmadapuram district, Madhya Pradesh / Karnataka borders, providing critical habitat for vulnerable fish species and migratory waterbirds.\n\nConservation Significance:\nWith 85 Ramsar sites covering over 1.35 million hectares, India continues to lead Asia in wetland conservation efforts, aligning with the Amrit Dharohar initiative launched by the Government of India.', NULL, '1', '2026-08-21 17:25:57', 'India has expanded its network of protected wetlands under the Ramsar Convention by designating three new wetlands in Tamil Nadu and Karnataka, bringing the total number of Ramsar sites in India to 85, the highest in Asia.', 'UPSC CSE (GS-3 Environment & Biodiversity), State PSCs, SSC CGL', 'Ministry of Environment, Forest and Climate Change', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800', 'Ramsar Sites, Wetlands, Biodiversity, Environment, Amrit Dharohar', '3'),
('7', 'Cabinet Approves Unified Pension Scheme (UPS) for Central Government Employees', 'Governance & Policy', '2026-08-18', 'The Union Cabinet chaired by the Prime Minister approved the landmark Unified Pension Scheme (UPS), which harmonizes features of the Old Pension Scheme (OPS) and the National Pension System (NPS).\n\nPillars of the Unified Pension Scheme:\n1. Assured Pension: 50% of the average basic pay drawn in the last 12 months before superannuation for a minimum qualifying service of 25 years. Proportionate pension for service between 10 and 25 years.\n\n2. Assured Family Pension: 60% of the pension of the employee immediately before their demise.\n\n3. Assured Minimum Pension: ₹10,000 per month on superannuation after a minimum of 10 years of service.\n\n4. Inflation Indexation: Dearness Relief (DR) will be provided on the assured pension, family pension, and minimum pension, indexed to the All India Consumer Price Index for Industrial Workers (AICPI-IW).\n\n5. Lump Sum on Superannuation: In addition to gratuity, a lump sum payment based on 1/10th of monthly emoluments for every completed six months of service.', NULL, '1', '2026-08-21 17:25:57', 'The Union Cabinet has approved the Unified Pension Scheme (UPS) for Central Government employees, guaranteeing 50% of the average basic pay drawn over the last 12 months as pension for those completing a minimum qualifying service of 25 years.', 'UPSC CSE (GS-2 Governance & Welfare), SSC CGL, Banking, State PSCs', 'Cabinet Secretariat / PIB', 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800', 'Unified Pension Scheme, UPS, Governance, NPS, Central Government', '4');

-- --------------------------------------------------------
-- Table structure for `current_affairs_quizzes`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `current_affairs_quizzes`;
CREATE TABLE `current_affairs_quizzes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `article_id` int(11) NOT NULL,
  `question_text` text NOT NULL,
  `option_a` text NOT NULL,
  `option_b` text NOT NULL,
  `option_c` text NOT NULL,
  `option_d` text NOT NULL,
  `correct_option` enum('A','B','C','D') NOT NULL,
  `explanation` text NOT NULL,
  `difficulty` enum('easy','medium','hard') DEFAULT 'medium',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `article_id` (`article_id`),
  CONSTRAINT `current_affairs_quizzes_ibfk_1` FOREIGN KEY (`article_id`) REFERENCES `current_affairs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `current_affairs_quizzes`
INSERT INTO `current_affairs_quizzes` (`id`, `article_id`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `difficulty`, `created_at`) VALUES
('1', '3', 'According to the latest Monetary Policy Committee (MPC) announcement by the Reserve Bank of India, what is the current monetary policy stance?', 'Accommodative', 'Neutral', 'Withdrawal of Accommodation', 'Calibrated Tightening', 'C', 'The Monetary Policy Committee decided to remain focused on the \'Withdrawal of Accommodation\' stance. This decision was made to ensure that inflation progressively aligns with the target while continuing to support economic growth.', 'medium', '2026-08-21 17:27:02'),
('2', '3', 'In the bi-monthly monetary policy decision, what rates were set for the Standing Deposit Facility (SDF) and Marginal Standing Facility (MSF) respectively?', 'SDF: 6.25%, MSF: 6.75%', 'SDF: 6.50%, MSF: 6.75%', 'SDF: 6.00%, MSF: 6.50%', 'SDF: 6.25%, MSF: 6.50%', 'A', 'While keeping the policy repo rate unchanged at 6.50%, the RBI maintained the standing deposit facility (SDF) rate at 6.25%. The marginal standing facility (MSF) rate and the Bank Rate were both maintained at 6.75%.', 'medium', '2026-08-21 17:27:02'),
('3', '3', 'Along with the interest rate decisions, what key regulatory change did the RBI announce regarding tax payments made via UPI?', 'Limit increased from ₹1 lakh to ₹2 lakh per transaction', 'Limit increased from ₹1 lakh to ₹5 lakh per transaction', 'Limit increased from ₹2 lakh to ₹5 lakh per transaction', 'Limit increased from ₹50,000 to ₹1 lakh per transaction', 'B', 'To enhance digital adoption, the RBI announced an increase in the limit for tax payments through UPI. The per-transaction limit was raised from ₹1 lakh to ₹5 lakh.', 'easy', '2026-08-21 17:27:02'),
('4', '3', 'What are the Reserve Bank of India\'s projections for Real GDP growth and CPI inflation for FY25 as announced in the policy update?', 'Real GDP growth: 7.0%, CPI Inflation: 4.0%', 'Real GDP growth: 7.5%, CPI Inflation: 4.5%', 'Real GDP growth: 7.2%, CPI Inflation: 4.5%', 'Real GDP growth: 7.2%, CPI Inflation: 4.0%', 'C', 'The RBI projected real GDP growth for FY25 at 7.2% across the quarters. Meanwhile, CPI inflation for FY25 is projected at 4.5%, with the long-term target remaining anchored at 4%.', 'hard', '2026-08-21 17:27:02');

-- --------------------------------------------------------
-- Table structure for `daily_missions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `daily_missions`;
CREATE TABLE `daily_missions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `mission_date` date NOT NULL,
  `total_planned_minutes` int(11) DEFAULT 45,
  `items_json` longtext NOT NULL,
  `status` enum('pending','completed') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_date` (`user_id`,`mission_date`),
  CONSTRAINT `daily_missions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `daily_missions`
INSERT INTO `daily_missions` (`id`, `user_id`, `mission_date`, `total_planned_minutes`, `items_json`, `status`, `created_at`) VALUES
('6', '11', '2026-09-05', '45', '[{\"id\":1,\"title\":\"Speed Math Warmup\",\"category\":\"Quantitative Aptitude\",\"estimated_minutes\":10,\"question_count\":10,\"is_completed\":false,\"action_type\":\"practice\"},{\"id\":2,\"title\":\"High-Yield Current Affairs Flashcards\",\"category\":\"General Awareness\",\"estimated_minutes\":15,\"question_count\":15,\"is_completed\":false,\"action_type\":\"read\"},{\"id\":3,\"title\":\"Weak Spot Booster: Syllogism & Logic\",\"category\":\"Reasoning Ability\",\"estimated_minutes\":20,\"question_count\":10,\"is_completed\":false,\"action_type\":\"quiz\"}]', 'pending', '2026-09-05 12:12:45'),
('7', '1', '2026-09-09', '45', '[{\"id\":1,\"title\":\"Speed Math Warmup\",\"category\":\"Quantitative Aptitude\",\"estimated_minutes\":10,\"question_count\":10,\"is_completed\":false,\"action_type\":\"practice\"},{\"id\":2,\"title\":\"High-Yield Current Affairs Flashcards\",\"category\":\"General Awareness\",\"estimated_minutes\":15,\"question_count\":15,\"is_completed\":false,\"action_type\":\"read\"},{\"id\":3,\"title\":\"Weak Spot Booster: Syllogism & Logic\",\"category\":\"Reasoning Ability\",\"estimated_minutes\":20,\"question_count\":10,\"is_completed\":false,\"action_type\":\"quiz\"}]', 'pending', '2026-09-09 11:22:33');

-- --------------------------------------------------------
-- Table structure for `entitlements`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `entitlements`;
CREATE TABLE `entitlements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `item_type` enum('test','test_series','book') NOT NULL,
  `item_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `granted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `entitlements_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `exam_bank_targets`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `exam_bank_targets`;
CREATE TABLE `exam_bank_targets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `exam_id` int(11) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `target_per_difficulty` int(11) NOT NULL DEFAULT 150,
  `auto_topup` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `exam_subject_target` (`exam_id`,`subject_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `exam_bank_targets_ibfk_1` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `exam_bank_targets_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `exam_categories`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `exam_categories`;
CREATE TABLE `exam_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_category_id` int(11) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `type` enum('government','entrance','private_job','upskilling','qualification') DEFAULT 'government',
  `description` text DEFAULT NULL,
  `keywords` text DEFAULT NULL,
  `icon_url` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `sort_order` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `exam_categories`
INSERT INTO `exam_categories` (`id`, `parent_category_id`, `name`, `slug`, `type`, `description`, `keywords`, `icon_url`, `status`, `sort_order`) VALUES
('1', NULL, 'Government Exams', 'govt-exams', 'government', 'SSC, UPSC, Banking, Railways, Defence, State Exams', NULL, NULL, 'active', '1'),
('2', NULL, 'Entrance Examinations', 'entrance-exams', 'entrance', 'JEE Main/Advanced, NEET UG, CUET, GATE, CAT, CLAT', NULL, NULL, 'active', '2'),
('3', NULL, 'Private Jobs & Placement', 'private-jobs', 'private_job', 'IT Hiring, Aptitude, Coding Tests, Corporate Roles', NULL, NULL, 'active', '3'),
('4', NULL, 'Upskilling & Certifications', 'upskilling', 'upskilling', 'AI Tools, Data Analytics, Full Stack, Digital Marketing', NULL, NULL, 'active', '4'),
('5', NULL, '10th/12th/Graduation Paths', 'career-paths', 'qualification', 'Qualification-based career pathways and higher studies', NULL, NULL, 'active', '5'),
('6', NULL, 'UPSC Civil Services', 'upsc', 'government', 'Union Public Service Commission — India\'s premier civil service exam', 'upsc,ias,ips,ifs,civil services,collector,dm,sdo', NULL, 'active', '1'),
('7', NULL, 'SSC Exams', 'ssc', 'government', 'Staff Selection Commission — Central Govt recruitment exams', 'ssc,cgl,chsl,mts,constable,stenographer,staff selection', NULL, 'active', '2'),
('8', NULL, 'Banking & Finance', 'banking', 'government', 'IBPS, SBI, RBI, NABARD and all banking sector exams', 'ibps,sbi,rbi,bank po,bank clerk,banking,finance', NULL, 'active', '3'),
('9', NULL, 'Railways', 'railways', 'government', 'RRB — Railway Recruitment Board exams', 'rrb,ntpc,group d,alp,loco pilot,railway,railways,je,sse', NULL, 'active', '4'),
('10', NULL, 'State Public Service Commission', 'state-psc', 'government', 'All 28 State PSC exams across India', 'psc,state psc,bpsc,uppsc,mpsc,mppsc,rpsc,state civil services', NULL, 'active', '5'),
('11', NULL, 'Defence & Paramilitary', 'defence', 'government', 'Army, Navy, Air Force, NDA, CDS and paramilitary exams', 'nda,cds,afcat,army,navy,air force,bsf,crpf,cisf,defence', NULL, 'active', '6'),
('12', NULL, 'Teaching & Education', 'teaching', 'government', 'CTET, TET, UGC NET, NVS, KVS and all teaching exams', 'ctet,tet,ugc net,nvs,kvs,teaching,teacher,dsssb,csir net', NULL, 'active', '7'),
('13', NULL, 'Insurance Sector', 'insurance', 'government', 'LIC, NIACL, NICL, UIICL and all insurance sector exams', 'lic,niacl,nicl,insurance,aao,ado,assistant', NULL, 'active', '8'),
('14', NULL, 'Engineering Entrance', 'engineering-entrance', 'entrance', 'JEE Main, Advanced, BITSAT, VITEEE and state CETs', 'jee,jee main,jee advanced,bitsat,engineering entrance,iit,nit', NULL, 'active', '9'),
('15', NULL, 'Medical Entrance', 'medical-entrance', 'entrance', 'NEET UG/PG, AIIMS, JIPMER and state medical exams', 'neet,neet pg,aiims,medical entrance,mbbs,bds,doctor', NULL, 'active', '10'),
('16', NULL, 'Management Entrance', 'management-entrance', 'entrance', 'CAT, MAT, XAT, SNAP, IIFT, CMAT and MBA entrance exams', 'cat,mat,xat,snap,gmat,mba,management,iim', NULL, 'active', '11'),
('17', NULL, 'Law Entrance', 'law-entrance', 'entrance', 'CLAT, AILET, LSAT India and state law entrance exams', 'clat,ailet,law,nlsiu,nlu,legal studies', NULL, 'active', '12'),
('18', NULL, 'GATE & PSU', 'gate-psu', 'entrance', 'GATE — Graduate Aptitude Test in Engineering and PSU recruitment', 'gate,psu,isro,barc,bel,iocl,ongc,drdo,engineering psu', NULL, 'active', '13'),
('19', NULL, 'CUET', 'cuet', 'entrance', 'Common University Entrance Test UG/PG for central universities', 'cuet,central university,du,jnu,bhu,undergraduate,postgraduate', NULL, 'active', '14'),
('20', NULL, 'Constable & Police', 'police-constable', 'government', 'State Police Constable, Sub-Inspector and Head Constable exams', 'police,constable,sub inspector,si,asi,head constable,upp,rajasthan police', NULL, 'active', '15'),
('21', NULL, 'Judiciary & Law', 'judiciary', 'government', 'District Court, High Court and Civil Judge exams', 'judiciary,civil judge,district court,high court,judicial services', NULL, 'active', '16'),
('22', NULL, 'Skill & Computer', 'skill-computer', 'upskilling', 'NIELIT CCC, O Level, A Level, Typing Tests, DCA, BCA', 'nielit,ccc,o level,a level,typing,computer,dca,bca,skill', NULL, 'active', '17'),
('23', NULL, 'State Govt & Misc', 'state-misc', 'government', 'State-specific patwari, lekhpal, gram sevak, VDO, clerk exams', 'patwari,lekhpal,gram sevak,vdo,clerk,state govt,panchayat', NULL, 'active', '18'),
('24', NULL, 'State PSC Exams', 'state-psc-exams', 'government', 'State Public Service Commission Examinations', '', '', 'active', '0');

-- --------------------------------------------------------
-- Table structure for `exam_patterns`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `exam_patterns`;
CREATE TABLE `exam_patterns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `exam_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `pattern_version` int(11) DEFAULT 1,
  `timer_mode` enum('TOTAL','SECTIONAL') DEFAULT 'TOTAL',
  `total_duration_seconds` int(11) NOT NULL,
  `total_questions` int(11) NOT NULL,
  `total_marks` decimal(8,2) NOT NULL,
  `default_positive_marks` decimal(5,2) DEFAULT 2.00,
  `default_negative_marks` decimal(5,2) DEFAULT 0.50,
  `navigation_policy` enum('FREE','SECTION_LOCKED') DEFAULT 'FREE',
  `languages` varchar(255) DEFAULT 'en,hi',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `exam_id` (`exam_id`),
  CONSTRAINT `exam_patterns_ibfk_1` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `exam_patterns`
INSERT INTO `exam_patterns` (`id`, `exam_id`, `name`, `pattern_version`, `timer_mode`, `total_duration_seconds`, `total_questions`, `total_marks`, `default_positive_marks`, `default_negative_marks`, `navigation_policy`, `languages`, `is_active`, `created_at`) VALUES
('1', '1', 'SSC CGL Tier-1 Pattern (60 Mins)', '1', 'TOTAL', '3600', '100', '200.00', '2.00', '0.50', 'FREE', 'en,hi', '1', '2026-08-21 14:22:31'),
('2', '2', 'IBPS PO Prelims Pattern (60 Mins Sectional)', '1', 'SECTIONAL', '3600', '100', '100.00', '1.00', '0.25', 'SECTION_LOCKED', 'en,hi', '1', '2026-08-21 14:22:31'),
('3', '3', 'JEE Main NTA Pattern (180 Mins)', '1', 'TOTAL', '10800', '90', '300.00', '4.00', '1.00', 'FREE', 'en,hi', '1', '2026-08-21 14:22:31');

-- --------------------------------------------------------
-- Table structure for `exam_twin_snapshots`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `exam_twin_snapshots`;
CREATE TABLE `exam_twin_snapshots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `knowledge_score` decimal(5,2) DEFAULT 0.00,
  `accuracy_score` decimal(5,2) DEFAULT 0.00,
  `speed_score` decimal(5,2) DEFAULT 0.00,
  `consistency_score` decimal(5,2) DEFAULT 0.00,
  `overall_readiness` decimal(5,2) DEFAULT 0.00,
  `estimated_score_min` int(11) DEFAULT 0,
  `estimated_score_max` int(11) DEFAULT 0,
  `target_benchmark` int(11) DEFAULT 160,
  `diagnosis_summary` text DEFAULT NULL,
  `recommended_route` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_exam_snapshot` (`user_id`,`exam_id`),
  KEY `exam_id` (`exam_id`),
  CONSTRAINT `exam_twin_snapshots_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `exam_twin_snapshots_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `exam_twin_snapshots`
INSERT INTO `exam_twin_snapshots` (`id`, `user_id`, `exam_id`, `knowledge_score`, `accuracy_score`, `speed_score`, `consistency_score`, `overall_readiness`, `estimated_score_min`, `estimated_score_max`, `target_benchmark`, `diagnosis_summary`, `recommended_route`, `updated_at`) VALUES
('3', '7', '1', '0.00', '0.00', '100.00', '20.00', '0.00', '0', '10', '35', 'Accuracy 0.00% across 22 questions, 0 correct.', '1. Clear the Mistake Notebook -> 2. Re-attempt weak sections -> 3. Complete the Daily Mission', '2026-09-08 13:57:36'),
('4', '1', '1', '0.00', '0.00', '100.00', '20.00', '0.00', '0', '10', '35', 'Accuracy 0.00% across 22 questions, 0 correct.', '1. Clear the Mistake Notebook -> 2. Re-attempt weak sections -> 3. Complete the Daily Mission', '2026-09-09 12:57:05');

-- --------------------------------------------------------
-- Table structure for `exams`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `exams`;
CREATE TABLE `exams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_exam_id` int(11) DEFAULT NULL,
  `exam_level` enum('main','sub','stage') DEFAULT 'main',
  `category_id` int(11) NOT NULL,
  `organization_id` int(11) DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `slug` varchar(150) NOT NULL,
  `short_description` text DEFAULT NULL,
  `overview_text` longtext DEFAULT NULL,
  `syllabus_text` longtext DEFAULT NULL,
  `eligibility_info` text DEFAULT NULL,
  `banner_url` varchar(255) DEFAULT NULL,
  `status` enum('active','draft','archived') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `category_id` (`category_id`),
  KEY `organization_id` (`organization_id`),
  KEY `fk_exam_parent` (`parent_exam_id`),
  CONSTRAINT `exams_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `exam_categories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `exams_ibfk_2` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_exam_parent` FOREIGN KEY (`parent_exam_id`) REFERENCES `exams` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=157 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `exams`
INSERT INTO `exams` (`id`, `parent_exam_id`, `exam_level`, `category_id`, `organization_id`, `title`, `slug`, `short_description`, `overview_text`, `syllabus_text`, `eligibility_info`, `banner_url`, `status`, `created_at`) VALUES
('1', NULL, 'main', '1', '1', 'SSC CGL (Combined Graduate Level)', 'ssc-cgl', 'Premier exam for Group B & C posts in Ministries and Departments of Govt of India.', 'SSC CGL comprises Tier 1 (Qualifying) and Tier 2 examination testing Quantitative Aptitude, English, Reasoning, and General Awareness.', 'Maths (Arithmetic + Advanced), English Language & Comprehension, Reasoning & Intelligence, General Knowledge & Current Affairs.', NULL, NULL, 'active', '2026-08-21 14:22:31'),
('2', NULL, 'main', '1', '3', 'IBPS PO (Probationary Officer)', 'ibps-po', 'National competitive exam for Officer cadre roles in Indian Public Sector Banks.', 'IBPS PO tests Prelims and Mains followed by Interview. Focuses on Data Interpretation, Reasoning, Banking Awareness and English.', 'Reasoning Ability, Quantitative Aptitude, English Language, General/Economy/Banking Awareness.', NULL, NULL, 'active', '2026-08-21 14:22:31'),
('3', NULL, 'main', '2', '4', 'JEE Main', 'jee-main', 'National level engineering entrance test for admission to NITs, IIITs and CFTIs.', 'JEE Main consists of Physics, Chemistry and Mathematics testing conceptual speed, accuracy and analytical problem solving.', 'Physics (Mechanics, Electrodynamics, Modern Physics), Chemistry (Organic, Inorganic, Physical), Mathematics (Algebra, Calculus, Coordinate Geometry).', NULL, NULL, 'active', '2026-08-21 14:22:31'),
('4', NULL, 'main', '6', '1', 'UPSC Civil Services (IAS/IPS/IFS)', 'upsc-cse', 'India\'s most prestigious exam for IAS, IPS, IRS, IFS officers', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('5', NULL, 'sub', '6', '1', 'UPSC CSE Prelims', 'upsc-cse-prelims', 'Preliminary stage of UPSC Civil Services — GS Paper I & CSAT', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('6', NULL, 'sub', '6', '1', 'UPSC CSE Mains', 'upsc-cse-mains', 'Mains stage — 9 papers including Essay, GS I-IV, Optional', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('7', NULL, 'main', '6', '1', 'UPSC CDS', 'upsc-cds', 'Combined Defence Services — Army, Navy, Air Force officer entry', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('8', NULL, 'main', '6', '1', 'UPSC NDA', 'upsc-nda', 'National Defence Academy — entry for 10+2 students to armed forces', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('9', NULL, 'main', '6', '1', 'UPSC CAPF', 'upsc-capf', 'Central Armed Police Forces — BSF/CRPF/CISF/ITBP/SSB AC posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('10', NULL, 'main', '6', '1', 'UPSC IFS (Indian Forest Service)', 'upsc-ifs', 'Indian Forest Service recruitment via UPSC', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('11', NULL, 'main', '6', '1', 'UPSC SCRA', 'upsc-scra', 'Special Class Railway Apprentices recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('12', NULL, 'main', '6', '1', 'UPSC CISF AC (EXE) LDCE', 'upsc-cisf-ac', 'CISF Assistant Commandant Limited Departmental Competitive Exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('13', NULL, 'sub', '7', '2', 'SSC CGL Tier 1', 'ssc-cgl-tier1', 'SSC CGL Tier 1 — Computer Based Exam (CBE)', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('14', NULL, 'sub', '7', '2', 'SSC CGL Tier 2', 'ssc-cgl-tier2', 'SSC CGL Tier 2 — Advanced CBE for shortlisted candidates', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('15', NULL, 'main', '7', '2', 'SSC CHSL (Combined Higher Secondary Level)', 'ssc-chsl', 'Recruitment for LDC, JSA, PA, SA, DEO posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('16', NULL, 'main', '7', '2', 'SSC MTS (Multi Tasking Staff)', 'ssc-mts', 'Multi Tasking Staff recruitment for Non-Technical Group C posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('17', NULL, 'main', '7', '2', 'SSC CPO (Central Police Organisation)', 'ssc-cpo', 'SI in Delhi Police, CAPFs and ASI in CISF', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('18', NULL, 'main', '7', '2', 'SSC JE (Junior Engineer)', 'ssc-je', 'Junior Engineer Civil/Electrical/Mechanical for CPWD, MES, BRO', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('19', NULL, 'main', '7', '2', 'SSC GD Constable', 'ssc-gd', 'General Duty Constable in BSF, CRPF, CISF, ITBP, SSB, NIA', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('20', NULL, 'main', '7', '2', 'SSC Stenographer (Grade C & D)', 'ssc-steno', 'Stenographer Grade C and D posts in Central Govt', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('21', NULL, 'main', '7', '2', 'SSC Phase VII (Selection Post)', 'ssc-phase7', 'Various selection posts across departments via SSC', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('23', NULL, 'sub', '8', '3', 'IBPS PO Prelims', 'ibps-po-prelims', 'IBPS PO Preliminary Exam — Reasoning, Quant, English', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('24', NULL, 'sub', '8', '3', 'IBPS PO Mains', 'ibps-po-mains', 'IBPS PO Main Exam — Reasoning, Quant, English, GK, Computer', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('25', NULL, 'main', '8', '3', 'IBPS Clerk', 'ibps-clerk', 'IBPS Clerk — Office Assistant posts in public sector banks', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('26', NULL, 'main', '8', '3', 'IBPS SO (Specialist Officer)', 'ibps-so', 'Specialist Officer: IT, HR, Marketing, Agriculture, Law', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('27', NULL, 'main', '8', '3', 'IBPS RRB PO', 'ibps-rrb-po', 'Regional Rural Banks — Officer Scale I/II/III', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('28', NULL, 'main', '8', '3', 'IBPS RRB Clerk', 'ibps-rrb-clerk', 'Regional Rural Banks — Office Assistant (Multipurpose)', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('29', NULL, 'main', '8', '4', 'SBI PO (Probationary Officer)', 'sbi-po', 'State Bank of India Probationary Officer recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('30', NULL, 'main', '8', '4', 'SBI Clerk (Junior Associate)', 'sbi-clerk', 'SBI Junior Associate — Customer Support & Sales', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('31', NULL, 'main', '8', '4', 'SBI SO (Specialist Cadre Officer)', 'sbi-so', 'SBI Specialist Cadre — IT, CA, Law, Marketing, HR', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('32', NULL, 'main', '8', '5', 'RBI Grade B Officer', 'rbi-grade-b', 'Reserve Bank of India Grade B — General/DEPR/DSIM', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('33', NULL, 'main', '8', '5', 'RBI Assistant', 'rbi-assistant', 'Reserve Bank of India Assistant posts in regional offices', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('34', NULL, 'main', '8', '5', 'RBI Office Attendant', 'rbi-office-attendant', 'RBI Office Attendant recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('35', NULL, 'main', '8', NULL, 'NABARD Grade A/B', 'nabard-grade-ab', 'National Bank for Agriculture and Rural Development recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('36', NULL, 'main', '8', NULL, 'SIDBI Grade A', 'sidbi-grade-a', 'Small Industries Development Bank of India Officer recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('37', NULL, 'main', '8', NULL, 'IRDAI Assistant Manager', 'irdai-am', 'Insurance Regulatory Development Authority of India', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('39', NULL, 'main', '9', '6', 'RRB NTPC (Non-Technical Popular Categories)', 'rrb-ntpc', 'Station Master, Goods Guard, Junior Clerk, ASM and 35+ posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('40', NULL, 'sub', '9', '6', 'RRB NTPC CBT 1', 'rrb-ntpc-cbt1', 'RRB NTPC Stage 1 — Preliminary Computer Based Test', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('41', NULL, 'sub', '9', '6', 'RRB NTPC CBT 2', 'rrb-ntpc-cbt2', 'RRB NTPC Stage 2 — Mains Computer Based Test', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('42', NULL, 'main', '9', '6', 'RRB Group D', 'rrb-group-d', 'Track Maintainer, Helper, Porter and various Group D posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('43', NULL, 'main', '9', '6', 'RRB ALP (Assistant Loco Pilot)', 'rrb-alp', 'Assistant Loco Pilot and Technician posts in Indian Railways', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('44', NULL, 'main', '9', '6', 'RRB JE (Junior Engineer)', 'rrb-je', 'Junior Engineer Civil/Electrical/IT/Mechanical/Signal posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('45', NULL, 'main', '9', '6', 'RRB SSE (Senior Section Engineer)', 'rrb-sse', 'Senior Section Engineer across various departments', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('46', NULL, 'main', '9', '6', 'RPF Constable & SI', 'rpf', 'Railway Protection Force Constable and Sub-Inspector', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('47', NULL, 'main', '9', '6', 'RRC Group C (Ministerial & Isolated)', 'rrc-group-c', 'Railway Recruitment Cell — Ministerial and Isolated posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('48', NULL, 'main', '10', '8', 'BPSC (Bihar Civil Services)', 'bpsc', 'Bihar Public Service Commission — BAS, BPS and related services', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('49', NULL, 'sub', '10', '8', 'BPSC 70th Combined Exam', 'bpsc-70', 'BPSC 70th Integrated Combined Competitive Exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('50', NULL, 'main', '10', '9', 'UPPSC PCS (UP Civil Services)', 'uppsc-pcs', 'UP Provincial Civil Services — SDM, DSP and Group A/B posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('51', NULL, 'main', '10', '9', 'UPPSC RO/ARO', 'uppsc-ro-aro', 'UP Review Officer / Assistant Review Officer exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('52', NULL, 'main', '10', '9', 'UPPSC Lekhpal', 'uppsc-lekhpal', 'UP Chakbandi Lekhpal recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('53', NULL, 'main', '10', '10', 'MPSC (Maharashtra Civil Services)', 'mpsc', 'Maharashtra Public Service Commission — State Services', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('54', NULL, 'main', '10', '11', 'RPSC (Rajasthan Civil Services)', 'rpsc-ras', 'Rajasthan Administrative Service — RAS/RTS recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('55', NULL, 'main', '10', '11', 'RPSC 1st Grade Teacher', 'rpsc-1st-grade', 'Rajasthan 1st Grade School Lecturer recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('56', NULL, 'main', '10', '11', 'RPSC 2nd Grade Teacher', 'rpsc-2nd-grade', 'Rajasthan 2nd Grade Senior Teacher recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('57', NULL, 'main', '10', '12', 'MPPSC (MP Civil Services)', 'mppsc', 'MP State Services Exam — Dy Collector, DSP, Tehsildar', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('58', NULL, 'main', '10', '20', 'APPSC Group 1', 'appsc-group1', 'AP Group 1 Services — Deputy Collector, DSP, Joint Director', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('59', NULL, 'main', '10', '20', 'APPSC Group 2', 'appsc-group2', 'AP Group 2 Services — Junior Lecturer, MRO, Sub-Registrar', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('60', NULL, 'main', '10', '21', 'TSPSC Group 1', 'tspsc-group1', 'Telangana Group 1 — Dy Collector, DSP, DFO posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('61', NULL, 'main', '10', '22', 'TNPSC Group 1', 'tnpsc-group1', 'Tamil Nadu Group 1 — IAS equivalent state services', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('62', NULL, 'main', '10', '22', 'TNPSC Group 2', 'tnpsc-group2', 'Tamil Nadu Group 2 — Deputy Tahsildar, VAO, BDO posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('63', NULL, 'main', '10', '22', 'TNPSC Group 4', 'tnpsc-group4', 'Tamil Nadu Village Administrative Officer exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('64', NULL, 'main', '10', '23', 'KPSC (Karnataka Civil Services)', 'kpsc', 'Karnataka Administrative Services — Group A & B', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('65', NULL, 'main', '10', '24', 'Kerala PSC (Various Posts)', 'kerala-psc', 'Kerala Public Service Commission — LDC, Driver, LD Clerk and more', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('66', NULL, 'main', '10', '25', 'PPSC (Punjab Civil Services)', 'ppsc', 'Punjab Civil Services — PCS exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('67', NULL, 'main', '10', '26', 'HPSC (Haryana Civil Services)', 'hpsc-hcs', 'Haryana Civil Services — HCS exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('68', NULL, 'main', '10', '27', 'JPSC (Jharkhand Civil Services)', 'jpsc', 'Jharkhand Administrative Services exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('69', NULL, 'main', '10', '28', 'OPSC (Odisha Civil Services)', 'opsc-oas', 'Odisha Administrative Services — OAS exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('70', NULL, 'main', '10', '29', 'GPSC (Gujarat Civil Services)', 'gpsc', 'Gujarat Administrative Services — Class 1 & 2', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('71', NULL, 'main', '10', NULL, 'UKPSC (Uttarakhand Civil Services)', 'ukpsc', 'Uttarakhand Public Service Commission — PCS exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('72', NULL, 'main', '10', NULL, 'CGPSC (Chhattisgarh Civil Services)', 'cgpsc', 'Chhattisgarh PSC — State Services exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('73', NULL, 'main', '10', NULL, 'WBPSC (West Bengal Civil Services)', 'wbpsc', 'West Bengal Civil Service — WBCS exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('74', NULL, 'main', '10', NULL, 'APSC (Assam Civil Services)', 'apsc', 'Assam Public Service Commission — ACS exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('75', NULL, 'main', '10', NULL, 'Goa PSC', 'goa-psc', 'Goa Public Service Commission — State Services', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('76', NULL, 'main', '10', NULL, 'HP PSC (Himachal Pradesh)', 'hppsc', 'Himachal Pradesh PSC — State Services exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('77', NULL, 'main', '11', '1', 'NDA (National Defence Academy)', 'nda', 'Entry to Army/Navy/Air Force wings of NDA for 10+2 students', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('78', NULL, 'main', '11', '1', 'CDS (Combined Defence Services)', 'cds', 'Entry to IMA, INA, AFA, OTA for graduates', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('79', NULL, 'main', '11', NULL, 'AFCAT (Air Force Common Admission Test)', 'afcat', 'Indian Air Force officer entry for Flying and Ground Duty', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('80', NULL, 'main', '11', NULL, 'Indian Army JCO/GD', 'army-soldier-gd', 'Indian Army — Soldier General Duty, Technical, Tradesman', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('81', NULL, 'main', '11', NULL, 'Indian Navy (Sailors & Officers)', 'indian-navy', 'Navy — SSR, MR, AA, INCET and officer entry exams', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('82', NULL, 'main', '11', NULL, 'BSF Head Constable & ASI', 'bsf-hc', 'Border Security Force Head Constable and ASI recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('83', NULL, 'main', '11', NULL, 'CRPF Constable & ASI', 'crpf', 'Central Reserve Police Force recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('84', NULL, 'main', '11', NULL, 'CISF Constable', 'cisf-constable', 'Central Industrial Security Force Constable (Trade) recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('85', NULL, 'main', '11', NULL, 'ITBP Constable & SI', 'itbp', 'Indo-Tibetan Border Police recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('86', NULL, 'main', '11', NULL, 'SSB (Sashastra Seema Bal)', 'ssb-force', 'Sashastra Seema Bal — Constable, Head Constable, Inspector', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('87', NULL, 'main', '11', NULL, 'Assam Rifles', 'assam-rifles', 'Assam Rifles — Rifleman, Havildar and Technical posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('88', NULL, 'main', '12', '15', 'CTET (Central Teacher Eligibility Test)', 'ctet', 'Eligibility test for central govt school teachers Paper I & II', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('89', NULL, 'main', '12', NULL, 'UP TET (Uttar Pradesh TET)', 'up-tet', 'UP Teacher Eligibility Test for primary and upper primary', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('90', NULL, 'main', '12', NULL, 'Bihar TET (BTET)', 'btet', 'Bihar Teacher Eligibility Test', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('91', NULL, 'main', '12', NULL, 'Rajasthan REET', 'reet', 'Rajasthan Eligibility Examination for Teachers', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('92', NULL, 'main', '12', NULL, 'MP TET / MPTET', 'mptet', 'Madhya Pradesh Teacher Eligibility Test Varg 1, 2, 3', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('93', NULL, 'main', '12', '16', 'UGC NET (National Eligibility Test)', 'ugc-net', 'Eligibility for Assistant Professor and JRF in universities', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('94', NULL, 'main', '12', NULL, 'CSIR UGC NET', 'csir-net', 'CSIR NET for JRF in Science subjects', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('95', NULL, 'main', '12', '17', 'KVS TGT/PGT/PRT', 'kvs-teacher', 'Kendriya Vidyalaya Sangathan teacher recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('96', NULL, 'main', '12', '18', 'NVS TGT/PGT/Misc', 'nvs-teacher', 'Navodaya Vidyalaya Samiti teacher and staff recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('97', NULL, 'main', '12', '19', 'DSSSB TGT/PGT/PRT', 'dsssb-teacher', 'DSSSB Delhi — TGT, PGT, PRT, LDC and various posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('98', NULL, 'main', '13', '13', 'LIC AAO (Assistant Administrative Officer)', 'lic-aao', 'LIC — Generalist and Specialist (IT/CA/Actuarial) AAO', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('99', NULL, 'main', '13', '13', 'LIC ADO (Apprentice Development Officer)', 'lic-ado', 'LIC ADO recruitment for marketing and development roles', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('100', NULL, 'main', '13', '13', 'LIC HFL (Housing Finance Ltd)', 'lic-hfl', 'LIC Housing Finance Assistant/Officer posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('101', NULL, 'main', '13', NULL, 'NIACL AO & Assistant', 'niacl', 'New India Assurance Company — AO and Assistant recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('102', NULL, 'main', '13', '14', 'NICL AO & Assistant', 'nicl', 'National Insurance Company — AO Scale I and Assistant', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('103', NULL, 'main', '13', NULL, 'UIICL (United India Insurance)', 'uiicl', 'United India Insurance Company — AO and Assistant posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('104', NULL, 'main', '13', NULL, 'GIC (General Insurance Corporation)', 'gic-scale1', 'GIC Re — Scale 1 Officer (Generalist and Specialist)', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('105', NULL, 'main', '13', NULL, 'OICL (Oriental Insurance)', 'oicl', 'Oriental Insurance Company — AO Class I posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('106', NULL, 'main', '14', '7', 'JEE Advanced', 'jee-advanced', 'IIT admission exam — top 2.5 lakh JEE Main qualifiers', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('107', NULL, 'main', '14', NULL, 'BITSAT', 'bitsat', 'BITS Pilani Admissions — Computer based engineering entrance', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('108', NULL, 'main', '14', NULL, 'VITEEE', 'viteee', 'VIT Engineering Entrance Exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('109', NULL, 'main', '14', NULL, 'MHT-CET Engineering', 'mht-cet-engg', 'Maharashtra Common Entrance Test for Engineering', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('110', NULL, 'main', '14', NULL, 'KEAM (Kerala Engineering)', 'keam', 'Kerala Engineering Architecture Medical entrance', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('112', NULL, 'main', '15', '7', 'NEET UG', 'neet-ug', 'National Eligibility Entrance Test for MBBS/BDS/BAMS/BHMS', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('113', NULL, 'main', '15', '7', 'NEET PG', 'neet-pg', 'NEET Postgraduate for MD/MS/Diploma admissions', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('114', NULL, 'main', '15', NULL, 'AIIMS PG Entrance', 'aiims-pg', 'AIIMS New Delhi Postgraduate entrance exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('115', NULL, 'main', '15', NULL, 'INI CET', 'ini-cet', 'Institute of National Importance — Combined Entrance Test', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('116', NULL, 'main', '16', NULL, 'CAT (Common Admission Test)', 'cat', 'MBA admission to IIMs and 100+ top B-schools', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('117', NULL, 'main', '16', NULL, 'MAT (Management Aptitude Test)', 'mat', 'AIMA MAT for 600+ B-school admissions', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('118', NULL, 'main', '16', NULL, 'XAT (Xavier Aptitude Test)', 'xat', 'XLRI Xavier Aptitude Test for XLRI and 160+ institutes', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('119', NULL, 'main', '16', NULL, 'SNAP (Symbiosis National Aptitude)', 'snap', 'SNAP test for Symbiosis International University programs', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('120', NULL, 'main', '16', NULL, 'IIFT (Indian Institute of Foreign Trade)', 'iift', 'IIFT MBA IB entrance exam', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('121', NULL, 'main', '16', NULL, 'CMAT (Common Management Admission)', 'cmat', 'NTA CMAT for PGDM/MBA admission', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('122', NULL, 'main', '16', NULL, 'GMAT (Graduate Management)', 'gmat', 'Global MBA entrance for international B-schools', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('123', NULL, 'main', '17', NULL, 'CLAT (Common Law Admission Test)', 'clat', 'NLU admission — 22 National Law Universities across India', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('124', NULL, 'main', '17', NULL, 'AILET (NLU Delhi Entrance)', 'ailet', 'National Law University Delhi — independent entrance', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('125', NULL, 'main', '17', NULL, 'LSAT India', 'lsat-india', 'Law School Admission Test — various private law schools', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('126', NULL, 'main', '18', NULL, 'GATE (Graduate Aptitude Test)', 'gate', 'MTech/PhD admission and PSU jobs via GATE score', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('127', NULL, 'sub', '18', NULL, 'GATE CSE', 'gate-cse', 'GATE Computer Science & Information Technology', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('128', NULL, 'sub', '18', NULL, 'GATE ECE', 'gate-ece', 'GATE Electronics & Communication Engineering', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('129', NULL, 'sub', '18', NULL, 'GATE ME', 'gate-me', 'GATE Mechanical Engineering', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('130', NULL, 'sub', '18', NULL, 'GATE CE', 'gate-ce', 'GATE Civil Engineering', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('131', NULL, 'sub', '18', NULL, 'GATE EE', 'gate-ee', 'GATE Electrical Engineering', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('132', NULL, 'main', '18', NULL, 'ISRO Scientist/Engineer', 'isro-sc', 'Indian Space Research Organisation — Scientist/Engineer SC', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('133', NULL, 'main', '18', NULL, 'DRDO CEPTAM', 'drdo-ceptam', 'DRDO — A, B & Technician posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('134', NULL, 'main', '18', NULL, 'BEL Probationary Engineer', 'bel-pe', 'Bharat Electronics Limited — PE and Trainee Engineer', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('135', NULL, 'main', '18', NULL, 'ONGC E1 Engineer', 'ongc-e1', 'Oil & Natural Gas Corporation — AEE/AE recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('136', NULL, 'main', '19', '7', 'CUET UG', 'cuet-ug', 'Common University Entrance Test — Central Universities UG admission', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('137', NULL, 'main', '19', '7', 'CUET PG', 'cuet-pg', 'Common University Entrance Test — PG admissions across India', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('138', NULL, 'main', '22', '30', 'NIELIT CCC (Course on Computer Concepts)', 'nielit-ccc', 'Most popular govt computer course exam in India', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('139', NULL, 'main', '22', '30', 'NIELIT O Level', 'nielit-o-level', 'Foundation level computer science programme by NIELIT', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('140', NULL, 'main', '22', '30', 'NIELIT A Level', 'nielit-a-level', 'Advanced Diploma in IT by NIELIT (equiv to MCA 1st year)', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('141', NULL, 'main', '22', '30', 'NIELIT B Level', 'nielit-b-level', 'NIELIT B Level — MCA level qualification', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('142', NULL, 'main', '22', NULL, 'Typing Test (Hindi/English)', 'typing-test', 'Government typing tests for clerk, steno, LDC posts', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('143', NULL, 'main', '20', NULL, 'UP Police Constable', 'up-police-constable', 'Uttar Pradesh Police Constable Civil Police recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('144', NULL, 'main', '20', NULL, 'UP Police SI', 'up-police-si', 'UP Police Sub-Inspector Civil Police recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('145', NULL, 'main', '20', NULL, 'Rajasthan Police Constable', 'rajasthan-police-constable', 'Rajasthan Police Constable recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('146', NULL, 'main', '20', NULL, 'MP Police Constable', 'mp-police-constable', 'Madhya Pradesh Police Constable recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('147', NULL, 'main', '20', NULL, 'Bihar Police Constable', 'bihar-police-constable', 'Bihar Police Constable recruitment via CSBC', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('148', NULL, 'main', '20', NULL, 'Delhi Police Constable', 'delhi-police-constable', 'Delhi Police Constable (Exe) Male/Female', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('149', NULL, 'main', '20', NULL, 'Haryana Police Constable', 'haryana-police-constable', 'Haryana Police Constable recruitment via HSSC', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('150', NULL, 'main', '23', NULL, 'UP Lekhpal (Rajasva)', 'up-lekhpal', 'Uttar Pradesh Revenue Board Lekhpal recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('151', NULL, 'main', '23', NULL, 'Rajasthan Patwari', 'rajasthan-patwari', 'Rajasthan Revenue Patwari recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('152', NULL, 'main', '23', NULL, 'MP Patwari', 'mp-patwari', 'Madhya Pradesh Patwari recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('153', NULL, 'main', '23', NULL, 'UP Gram Panchayat Adhikari / VDO', 'up-vdo', 'UP Village Development Officer recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('154', NULL, 'main', '23', NULL, 'UP Junior Assistant (Clerk)', 'up-junior-assistant', 'UP Sachivalaya Junior Assistant / LDC recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('155', NULL, 'main', '23', NULL, 'Rajasthan Vanpal/Vanrakshak', 'rajasthan-vanpal', 'Rajasthan Forest Guard and Forest Ranger recruitment', NULL, NULL, NULL, NULL, 'active', '2026-08-21 16:07:17'),
('156', NULL, 'main', '24', NULL, 'CGDFGD', 'FGFDGDF', 'SDFGDFGDFG', NULL, NULL, NULL, NULL, 'active', '2026-09-02 17:23:28');

-- --------------------------------------------------------
-- Table structure for `external_api_cache`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `external_api_cache`;
CREATE TABLE `external_api_cache` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_name` varchar(100) NOT NULL,
  `cache_key` varchar(255) NOT NULL,
  `payload_json` longtext NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `cache_key` (`cache_key`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `external_api_cache`
INSERT INTO `external_api_cache` (`id`, `service_name`, `cache_key`, `payload_json`, `expires_at`, `created_at`) VALUES
('1', 'JobCrawler', 'jobs_list_all', '[{\"id\":2,\"title\":\"IBPS PO XIV Online Application Open\",\"organization_name\":\"Institute of Banking Personnel Selection\",\"job_type\":\"government\",\"total_vacancies\":4455,\"eligibility_criteria\":\"Graduate in any discipline. Age limit 20 to 30 years.\",\"last_date_to_apply\":\"2026-09-05\",\"apply_link\":\"https:\\/\\/ibps.in\",\"created_at\":\"2026-08-21 14:22:31\"},{\"id\":1,\"title\":\"SSC CGL 2026 Notification for 17,727 Vacancies\",\"organization_name\":\"Staff Selection Commission\",\"job_type\":\"government\",\"total_vacancies\":17727,\"eligibility_criteria\":\"Bachelor Degree in any discipline from a recognized University.\",\"last_date_to_apply\":\"2026-09-15\",\"apply_link\":\"https:\\/\\/ssc.gov.in\",\"created_at\":\"2026-08-21 14:22:31\"}]', '2026-08-31 11:58:10', '2026-08-31 14:58:10');

-- --------------------------------------------------------
-- Table structure for `integrity_flags`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `integrity_flags`;
CREATE TABLE `integrity_flags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attempt_id` int(11) NOT NULL,
  `flag_type` varchar(50) NOT NULL,
  `reason` text NOT NULL,
  `status` enum('pending','reviewed_valid','disqualified') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `attempt_id` (`attempt_id`),
  CONSTRAINT `integrity_flags_ibfk_1` FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `job_crawler_logs`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `job_crawler_logs`;
CREATE TABLE `job_crawler_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source_name` varchar(150) NOT NULL,
  `url_scraped` varchar(255) NOT NULL,
  `jobs_found` int(11) DEFAULT 0,
  `status` enum('success','failed') DEFAULT 'success',
  `error_message` text DEFAULT NULL,
  `run_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `job_crawler_logs`
INSERT INTO `job_crawler_logs` (`id`, `source_name`, `url_scraped`, `jobs_found`, `status`, `error_message`, `run_at`) VALUES
('1', 'GovtPortal_Scraper', 'https://ssc.gov.in/notifications', '3', 'success', NULL, '2026-08-31 14:58:10'),
('2', 'GovtPortal_Scraper', 'https://ssc.gov.in/notifications', '0', 'success', NULL, '2026-08-31 15:16:33');

-- --------------------------------------------------------
-- Table structure for `jobs`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `jobs`;
CREATE TABLE `jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `organization_name` varchar(150) NOT NULL,
  `job_type` enum('government','private') DEFAULT 'government',
  `total_vacancies` int(11) DEFAULT 0,
  `eligibility_criteria` text DEFAULT NULL,
  `last_date_to_apply` date DEFAULT NULL,
  `apply_link` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `jobs`
INSERT INTO `jobs` (`id`, `title`, `organization_name`, `job_type`, `total_vacancies`, `eligibility_criteria`, `last_date_to_apply`, `apply_link`, `created_at`) VALUES
('1', 'SSC CGL 2026 Notification for 17,727 Vacancies', 'Staff Selection Commission', 'government', '17727', 'Bachelor Degree in any discipline from a recognized University.', '2026-09-15', 'https://ssc.gov.in', '2026-08-21 14:22:31'),
('2', 'IBPS PO XIV Online Application Open', 'Institute of Banking Personnel Selection', 'government', '4455', 'Graduate in any discipline. Age limit 20 to 30 years.', '2026-09-05', 'https://ibps.in', '2026-08-21 14:22:31'),
('3', 'SSC CGL 2026 Recruitment Notification Out (17,727 Vacancies)', 'Staff Selection Commission (SSC)', 'government', '17727', 'Bachelor\'s Degree in any discipline from a recognized University. Age: 18-30 Years.', '2026-09-09', 'https://ssc.gov.in', '2026-08-31 14:58:10'),
('4', 'UPSC Civil Services Examination (CSE) 2026', 'Union Public Service Commission (UPSC)', 'government', '1056', 'Graduate in any stream. Age: 21-32 Years.', '2026-09-18', 'https://upsc.gov.in', '2026-08-31 14:58:10'),
('5', 'Associate Software Engineer - Campus Hiring 2026', 'Tech Mahindra / Private Tech Client', 'private', '450', 'B.Tech / BE / BCA / MCA (2025/2026 Passout). Aptitude & Coding evaluation.', '2026-09-30', 'https://careers.examverse.ai/jobs/se-2026', '2026-08-31 14:58:10');

-- --------------------------------------------------------
-- Table structure for `lost_marks_analyses`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `lost_marks_analyses`;
CREATE TABLE `lost_marks_analyses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `attempt_id` int(11) NOT NULL,
  `concept_gap_marks` decimal(5,2) DEFAULT 0.00,
  `silly_mistake_marks` decimal(5,2) DEFAULT 0.00,
  `time_pressure_marks` decimal(5,2) DEFAULT 0.00,
  `question_selection_marks` decimal(5,2) DEFAULT 0.00,
  `recoverable_marks_estimate` decimal(5,2) DEFAULT 0.00,
  `actionable_advice` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `attempt_id` (`attempt_id`),
  CONSTRAINT `lost_marks_analyses_ibfk_1` FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `lost_marks_analyses`
INSERT INTO `lost_marks_analyses` (`id`, `attempt_id`, `concept_gap_marks`, `silly_mistake_marks`, `time_pressure_marks`, `question_selection_marks`, `recoverable_marks_estimate`, `actionable_advice`, `created_at`) VALUES
('3', '6', '0.00', '0.00', '0.00', '0.00', '0.00', 'No incorrect answers in this attempt. Focus next on raising attempt volume within the time limit.', '2026-09-08 13:57:36'),
('4', '7', '1.20', '0.50', '0.30', '0.00', '2.00', 'Revisit the concepts behind your incorrect answers first, then re-attempt them from the Mistake Notebook.', '2026-09-09 12:10:04'),
('5', '8', '1.20', '0.50', '0.30', '0.00', '2.00', 'Revisit the concepts behind your incorrect answers first, then re-attempt them from the Mistake Notebook.', '2026-09-09 12:10:24'),
('6', '9', '1.20', '0.50', '0.30', '0.00', '2.00', 'Revisit the concepts behind your incorrect answers first, then re-attempt them from the Mistake Notebook.', '2026-09-09 12:11:22'),
('7', '10', '18.00', '7.50', '4.50', '0.00', '30.00', 'Revisit the concepts behind your incorrect answers first, then re-attempt them from the Mistake Notebook.', '2026-09-09 12:40:05'),
('8', '11', '1.20', '0.50', '0.30', '0.00', '2.00', 'Revisit the concepts behind your incorrect answers first, then re-attempt them from the Mistake Notebook.', '2026-09-09 12:57:05');

-- --------------------------------------------------------
-- Table structure for `map_categories`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `map_categories`;
CREATE TABLE `map_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `icon` varchar(50) DEFAULT 'place',
  `sort_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `map_categories`
INSERT INTO `map_categories` (`id`, `name`, `slug`, `icon`, `sort_order`, `created_at`) VALUES
('1', 'National Parks', 'national-parks', 'park', '1', '2026-08-27 13:30:50'),
('2', 'Rivers & Lakes', 'rivers-lakes', 'water', '2', '2026-08-27 13:30:50'),
('3', 'Dams & Reservoirs', 'dams-reservoirs', 'water_damage', '3', '2026-08-27 13:30:50'),
('4', 'Historical Sites', 'historical-sites', 'account_balance', '4', '2026-08-27 13:30:50'),
('5', 'World Geography', 'world-geography', 'public', '5', '2026-08-27 13:30:50');

-- --------------------------------------------------------
-- Table structure for `map_location_facts`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `map_location_facts`;
CREATE TABLE `map_location_facts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `location_id` int(11) NOT NULL,
  `fact` text NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `map_location_facts_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `map_locations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `map_locations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `map_locations`;
CREATE TABLE `map_locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `slug` varchar(150) NOT NULL,
  `country` varchar(100) DEFAULT 'India',
  `state` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `short_description` text DEFAULT NULL,
  `important_facts` text DEFAULT NULL,
  `exam_relevance` varchar(255) DEFAULT NULL,
  `pyq_count` int(11) DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `map_locations_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `map_categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `map_locations`
INSERT INTO `map_locations` (`id`, `category_id`, `name`, `slug`, `country`, `state`, `latitude`, `longitude`, `short_description`, `important_facts`, `exam_relevance`, `pyq_count`, `image_url`, `status`, `created_at`) VALUES
('1', '1', 'Gir National Park', 'gir-national-park', 'India', 'Gujarat', '21.12430000', '70.82420000', 'Sole natural habitat of Asiatic Lions in Gujarat.', 'Established in 1965. Home to Asiatic lions, leopards, and chinkara. Located in Kathiawar region.', 'High — Asked 14 times in SSC CGL & UPSC CSAT', '14', NULL, 'active', '2026-08-27 13:30:50'),
('2', '1', 'Kaziranga National Park', 'kaziranga-national-park', 'India', 'Assam', '26.57750000', '93.17110000', 'UNESCO World Heritage Site famous for One-horned Rhinoceros.', 'Located on Brahmaputra river plain. Hosts two-thirds of the worlds Great One-Horned Rhinoceroses.', 'Very High — Frequently asked in UPSC & Railway Exams', '22', NULL, 'active', '2026-08-27 13:30:50'),
('3', '2', 'River Narmada', 'river-narmada', 'India', 'Madhya Pradesh', '22.75330000', '81.75820000', 'West-flowing river originating from Amarkantak Plateau.', 'Flows through rift valley between Vindhya and Satpura ranges. Drains into Arabian Sea at Gulf of Khambhat.', 'High — SSC CGL & BPSC favorite rift valley question', '18', NULL, 'active', '2026-08-27 13:30:50'),
('4', '2', 'Chilika Lake', 'chilika-lake', 'India', 'Odisha', '19.68000000', '85.33000000', 'Largest brackish water lagoon in Asia & first Ramsar site of India.', 'Designated first Ramsar wetland in 1981. Famous for Irrawaddy dolphins and winter migratory birds.', 'High — Environment & Ecology PYQ staple', '16', NULL, 'active', '2026-08-27 13:30:50'),
('5', '3', 'Tehri Dam', 'tehri-dam', 'India', 'Uttarakhand', '30.37810000', '78.48030000', 'Tallest dam in India constructed on Bhagirathi River.', 'Height of 260.5 meters. Multipurpose rock and earth-fill embankment dam located in Garhwal region.', 'High — Static GK & Geography core question', '12', NULL, 'active', '2026-08-27 13:30:50'),
('6', '4', 'Nalanda Mahavihara', 'nalanda-mahavihara', 'India', 'Bihar', '25.13570000', '85.44460000', 'Ancient Mahavihara & Buddhist monastery established during Gupta Empire.', 'Founded in 5th century CE under Kumaragupta I. Visited by Hiuen Tsang. UNESCO World Heritage Site.', 'Very High — History PYQ for BPSC & SSC CGL', '25', NULL, 'active', '2026-08-27 13:30:50'),
('7', '5', 'Suez Canal', 'suez-canal', 'Egypt', 'Suez', '30.58520000', '32.26540000', 'Artificial sea-level waterway connecting Mediterranean Sea to Red Sea.', 'Opened in November 1869. Separates African continent from Sinai Peninsula. Shortcut between Europe & Asia.', 'High — World Geography & Trade Routes PYQ', '19', NULL, 'active', '2026-08-27 13:30:50');

-- --------------------------------------------------------
-- Table structure for `map_questions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `map_questions`;
CREATE TABLE `map_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `location_id` int(11) NOT NULL,
  `question_text` text NOT NULL,
  `option_a` varchar(150) NOT NULL,
  `option_b` varchar(150) NOT NULL,
  `option_c` varchar(150) NOT NULL,
  `option_d` varchar(150) NOT NULL,
  `correct_option` enum('A','B','C','D') NOT NULL,
  `explanation` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `map_questions_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `map_locations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `map_user_progress`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `map_user_progress`;
CREATE TABLE `map_user_progress` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `location_id` int(11) NOT NULL,
  `is_learned` tinyint(1) DEFAULT 1,
  `quiz_score` int(11) DEFAULT 0,
  `correct_attempts` int(11) NOT NULL DEFAULT 0,
  `total_attempts` int(11) NOT NULL DEFAULT 0,
  `last_reviewed_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_loc_unique` (`user_id`,`location_id`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `map_user_progress_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `map_user_progress_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `map_locations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `material_purchases`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `material_purchases`;
CREATE TABLE `material_purchases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `material_id` int(11) NOT NULL,
  `amount_paid` decimal(10,2) NOT NULL,
  `platform_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `creator_earning` decimal(10,2) NOT NULL DEFAULT 0.00,
  `payment_status` enum('pending','completed','failed','refunded') DEFAULT 'completed',
  `payment_method` varchar(50) DEFAULT 'mock',
  `transaction_id` varchar(200) DEFAULT NULL,
  `purchased_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_material` (`user_id`,`material_id`),
  KEY `material_id` (`material_id`),
  CONSTRAINT `material_purchases_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `material_purchases_ibfk_2` FOREIGN KEY (`material_id`) REFERENCES `study_materials` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `material_reviews`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `material_reviews`;
CREATE TABLE `material_reviews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `material_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `rating` tinyint(4) NOT NULL CHECK (`rating` between 1 and 5),
  `review_text` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `material_user_review` (`material_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `material_reviews_ibfk_1` FOREIGN KEY (`material_id`) REFERENCES `study_materials` (`id`) ON DELETE CASCADE,
  CONSTRAINT `material_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `mistake_notebook`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `mistake_notebook`;
CREATE TABLE `mistake_notebook` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `user_answer` varchar(255) DEFAULT NULL,
  `correct_answer` varchar(255) DEFAULT NULL,
  `mistake_reason` text DEFAULT NULL,
  `is_mastered` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_question_mistake` (`user_id`,`question_id`),
  CONSTRAINT `mistake_notebook_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `mistake_notebook`
INSERT INTO `mistake_notebook` (`id`, `user_id`, `question_id`, `user_answer`, `correct_answer`, `mistake_reason`, `is_mastered`, `created_at`, `updated_at`) VALUES
('30', '1', '1', 'A', 'B', NULL, '0', '2026-09-09 12:10:04', '2026-09-09 12:10:04'),
('33', '1', '2', 'C', 'B', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('34', '1', '3', 'C', 'A', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('35', '1', '4', 'B', 'C', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('36', '1', '5', 'C', 'A', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('37', '1', '6', 'B', 'D', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('38', '1', '7', 'D', 'B', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('39', '1', '9', 'D', 'B', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('40', '1', '10', 'B', 'C', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('41', '1', '11', 'A', 'B', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('42', '1', '12', 'C', 'A', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('43', '1', '15', 'B', 'D', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('44', '1', '18', 'B', 'C', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('45', '1', '19', 'C', 'B', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('46', '1', '20', 'D', 'B', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05'),
('47', '1', '21', 'B', 'A', NULL, '0', '2026-09-09 12:40:05', '2026-09-09 12:40:05');

-- --------------------------------------------------------
-- Table structure for `monthly_challenges`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `monthly_challenges`;
CREATE TABLE `monthly_challenges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `exam_id` int(11) NOT NULL,
  `test_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `month_year` varchar(20) NOT NULL,
  `start_window` datetime NOT NULL,
  `end_window` datetime NOT NULL,
  `status` enum('upcoming','live','evaluating','completed') DEFAULT 'upcoming',
  `tie_break_rule` varchar(255) DEFAULT '1. Score DESC, 2. Accuracy DESC, 3. Negative Marks ASC, 4. Time Spent ASC',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `exam_id` (`exam_id`),
  KEY `test_id` (`test_id`),
  CONSTRAINT `monthly_challenges_ibfk_1` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `monthly_challenges_ibfk_2` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `monthly_challenges`
INSERT INTO `monthly_challenges` (`id`, `exam_id`, `test_id`, `title`, `month_year`, `start_window`, `end_window`, `status`, `tie_break_rule`, `created_at`) VALUES
('1', '1', '3', 'August 2026 National SSC CGL Rank Challenge', 'August 2026', '2026-08-01 00:00:00', '2026-08-31 23:59:59', 'live', '1. Score DESC, 2. Accuracy DESC, 3. Negative Marks ASC, 4. Time Spent ASC', '2026-08-21 14:22:31');

-- --------------------------------------------------------
-- Table structure for `orders`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_code` varchar(50) NOT NULL,
  `user_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` varchar(10) DEFAULT 'INR',
  `payment_status` enum('created','paid','failed','refunded') DEFAULT 'created',
  `gateway_transaction_id` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_code` (`order_code`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `organizations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `organizations`;
CREATE TABLE `organizations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `short_name` varchar(50) NOT NULL,
  `logo_url` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `organizations`
INSERT INTO `organizations` (`id`, `name`, `short_name`, `logo_url`, `website`, `created_at`) VALUES
('1', 'Staff Selection Commission', 'SSC', NULL, 'https://ssc.gov.in', '2026-08-21 14:22:31'),
('2', 'Union Public Service Commission', 'UPSC', NULL, 'https://upsc.gov.in', '2026-08-21 14:22:31'),
('3', 'Institute of Banking Personnel Selection', 'IBPS', NULL, 'https://ibps.in', '2026-08-21 14:22:31'),
('4', 'National Testing Agency', 'NTA', NULL, 'https://nta.ac.in', '2026-08-21 14:22:31'),
('5', 'Indian Institutes of Technology', 'IIT', NULL, 'https://jeeadv.ac.in', '2026-08-21 14:22:31'),
('6', 'Union Public Service Commission', 'UPSC', NULL, 'https://upsc.gov.in', '2026-08-21 16:07:17'),
('7', 'Staff Selection Commission', 'SSC', NULL, 'https://ssc.nic.in', '2026-08-21 16:07:17'),
('8', 'Institute of Banking Personnel Selection', 'IBPS', NULL, 'https://ibps.in', '2026-08-21 16:07:17'),
('9', 'State Bank of India', 'SBI', NULL, 'https://sbi.co.in', '2026-08-21 16:07:17'),
('10', 'Reserve Bank of India', 'RBI', NULL, 'https://rbi.org.in', '2026-08-21 16:07:17'),
('11', 'Railway Recruitment Board', 'RRB', NULL, 'https://indianrailways.gov.in', '2026-08-21 16:07:17'),
('12', 'National Testing Agency', 'NTA', NULL, 'https://nta.ac.in', '2026-08-21 16:07:17'),
('13', 'Bihar Public Service Commission', 'BPSC', NULL, 'https://bpsc.bih.nic.in', '2026-08-21 16:07:17'),
('14', 'Uttar Pradesh Public Service Commission', 'UPPSC', NULL, 'https://uppsc.up.nic.in', '2026-08-21 16:07:17'),
('15', 'Maharashtra Public Service Commission', 'MPSC', NULL, 'https://mpsc.gov.in', '2026-08-21 16:07:17'),
('16', 'Rajasthan Public Service Commission', 'RPSC', NULL, 'https://rpsc.rajasthan.gov.in', '2026-08-21 16:07:17'),
('17', 'Madhya Pradesh Public Service Commission', 'MPPSC', NULL, 'https://mppsc.mp.gov.in', '2026-08-21 16:07:17'),
('18', 'Life Insurance Corporation of India', 'LIC', NULL, 'https://licindia.in', '2026-08-21 16:07:17'),
('19', 'National Insurance Company', 'NICL', NULL, 'https://nationalinsurance.nic.co.in', '2026-08-21 16:07:17'),
('20', 'Central Board of Secondary Education', 'CBSE', NULL, 'https://cbse.nic.in', '2026-08-21 16:07:17'),
('21', 'University Grants Commission', 'UGC', NULL, 'https://ugc.ac.in', '2026-08-21 16:07:17'),
('22', 'Kendriya Vidyalaya Sangathan', 'KVS', NULL, 'https://kvsangathan.nic.in', '2026-08-21 16:07:17'),
('23', 'Navodaya Vidyalaya Samiti', 'NVS', NULL, 'https://nvshq.org', '2026-08-21 16:07:17'),
('24', 'Delhi Subordinate Services Selection Board', 'DSSSB', NULL, 'https://dsssb.delhi.gov.in', '2026-08-21 16:07:17'),
('25', 'Andhra Pradesh Public Service Commission', 'APPSC', NULL, 'https://psc.ap.gov.in', '2026-08-21 16:07:17'),
('26', 'Telangana State Public Service Commission', 'TSPSC', NULL, 'https://tspsc.gov.in', '2026-08-21 16:07:17'),
('27', 'Tamil Nadu Public Service Commission', 'TNPSC', NULL, 'https://tnpsc.gov.in', '2026-08-21 16:07:17'),
('28', 'Karnataka Public Service Commission', 'KPSC', NULL, 'https://kpsc.kar.nic.in', '2026-08-21 16:07:17'),
('29', 'Kerala Public Service Commission', 'KPSC_KL', NULL, 'https://keralapsc.gov.in', '2026-08-21 16:07:17'),
('30', 'Punjab Public Service Commission', 'PPSC', NULL, 'https://ppsc.gov.in', '2026-08-21 16:07:17'),
('31', 'Haryana Public Service Commission', 'HPSC', NULL, 'https://hpsc.gov.in', '2026-08-21 16:07:17'),
('32', 'Jharkhand Public Service Commission', 'JPSC', NULL, 'https://jpsc.gov.in', '2026-08-21 16:07:17'),
('33', 'Odisha Public Service Commission', 'OPSC', NULL, 'https://opsc.gov.in', '2026-08-21 16:07:17'),
('34', 'Gujarat Public Service Commission', 'GPSC', NULL, 'https://gpsc.gujarat.gov.in', '2026-08-21 16:07:17'),
('35', 'National Informatics Centre Electronics and Information Technology Ltd', 'NIELIT', NULL, 'https://nielit.gov.in', '2026-08-21 16:07:17');

-- --------------------------------------------------------
-- Table structure for `pattern_sections`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `pattern_sections`;
CREATE TABLE `pattern_sections` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pattern_id` int(11) NOT NULL,
  `subject_id` int(11) NOT NULL,
  `section_name` varchar(100) NOT NULL,
  `question_count` int(11) NOT NULL,
  `positive_marks` decimal(5,2) NOT NULL,
  `negative_marks` decimal(5,2) NOT NULL,
  `duration_seconds` int(11) DEFAULT 0,
  `sort_order` int(11) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `pattern_id` (`pattern_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `pattern_sections_ibfk_1` FOREIGN KEY (`pattern_id`) REFERENCES `exam_patterns` (`id`) ON DELETE CASCADE,
  CONSTRAINT `pattern_sections_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `pattern_sections`
INSERT INTO `pattern_sections` (`id`, `pattern_id`, `subject_id`, `section_name`, `question_count`, `positive_marks`, `negative_marks`, `duration_seconds`, `sort_order`) VALUES
('1', '1', '1', 'Quantitative Aptitude', '25', '2.00', '0.50', '0', '1'),
('2', '1', '2', 'General Intelligence & Reasoning', '25', '2.00', '0.50', '0', '2'),
('3', '1', '3', 'English Comprehension', '25', '2.00', '0.50', '0', '3'),
('4', '1', '4', 'General Awareness', '25', '2.00', '0.50', '0', '4');

-- --------------------------------------------------------
-- Table structure for `qualifications`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `qualifications`;
CREATE TABLE `qualifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `qualifications`
INSERT INTO `qualifications` (`id`, `code`, `name`, `created_at`) VALUES
('1', '10TH', '10th Pass (Matriculation)', '2026-08-21 14:22:02'),
('2', '12TH', '12th Pass (Intermediate / Senior Secondary)', '2026-08-21 14:22:02'),
('3', 'GRAD', 'Graduation / Bachelor Degree', '2026-08-21 14:22:02'),
('4', 'POSTGRAD', 'Post Graduation / Master Degree', '2026-08-21 14:22:02'),
('5', 'ENGG', 'B.Tech / B.E. (Engineering)', '2026-08-21 14:22:02'),
('6', 'MED', 'MBBS / Medical', '2026-08-21 14:22:02');

-- --------------------------------------------------------
-- Table structure for `question_duplicate_candidates`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_duplicate_candidates`;
CREATE TABLE `question_duplicate_candidates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question_a_id` int(11) NOT NULL,
  `question_b_id` int(11) NOT NULL,
  `match_method` varchar(64) NOT NULL DEFAULT 'exact_hash',
  `similarity_score` decimal(5,2) NOT NULL DEFAULT 100.00,
  `status` enum('pending','reviewed','resolved') NOT NULL DEFAULT 'pending',
  `decision` enum('not_duplicate','exact_duplicate','near_duplicate','translation_pair','intentional_variant','replace_canonical','merge_cluster','conflict_escalate') DEFAULT NULL,
  `decision_reason` text DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dup_pair` (`question_a_id`,`question_b_id`),
  KEY `idx_qdc_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `question_duplicate_candidates`
INSERT INTO `question_duplicate_candidates` (`id`, `question_a_id`, `question_b_id`, `match_method`, `similarity_score`, `status`, `decision`, `decision_reason`, `decided_by`, `decided_at`, `created_at`) VALUES
('1', '1', '2', 'exact_hash', '100.00', 'resolved', 'not_duplicate', NULL, NULL, NULL, '2026-09-05 10:39:43');

-- --------------------------------------------------------
-- Table structure for `question_duplicate_clusters`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_duplicate_clusters`;
CREATE TABLE `question_duplicate_clusters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `canonical_question_id` int(11) NOT NULL,
  `cluster_name` varchar(128) DEFAULT NULL,
  `relation_policy` varchar(64) NOT NULL DEFAULT 'cluster_default',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_qdc_canonical` (`canonical_question_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `question_exams`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_exams`;
CREATE TABLE `question_exams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `question_exam_unique` (`question_id`,`exam_id`),
  KEY `idx_qe_exam` (`exam_id`),
  CONSTRAINT `question_exams_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `question_exams_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `question_options`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_options`;
CREATE TABLE `question_options` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question_id` int(11) NOT NULL,
  `option_key` varchar(10) NOT NULL,
  `language` varchar(10) NOT NULL DEFAULT 'en',
  `option_text` text NOT NULL,
  `is_correct` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_options_question_correct` (`question_id`,`is_correct`),
  CONSTRAINT `question_options_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=225 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `question_options`
INSERT INTO `question_options` (`id`, `question_id`, `option_key`, `language`, `option_text`, `is_correct`) VALUES
('1', '1', 'A', 'en', '120%', '0'),
('2', '1', 'B', 'en', '150%', '1'),
('3', '1', 'C', 'en', '133.33%', '0'),
('4', '1', 'D', 'en', '166.66%', '0'),
('5', '2', 'A', 'en', '18%', '0'),
('6', '2', 'B', 'en', '19%', '1'),
('7', '2', 'C', 'en', '20%', '0'),
('8', '2', 'D', 'en', '25%', '0'),
('9', '3', 'A', 'en', 'FZQCDM', '1'),
('10', '3', 'B', 'en', 'EYPBDL', '0'),
('11', '3', 'C', 'en', 'FZRCEM', '0'),
('12', '3', 'D', 'en', 'HBSEFO', '0'),
('13', '4', 'A', 'en', 'Neither of the', '0'),
('14', '4', 'B', 'en', 'two candidates', '0'),
('15', '4', 'C', 'en', 'have submitted', '1'),
('16', '4', 'D', 'en', 'their documents', '0'),
('17', '5', 'A', 'en', 'Article 12-13', '1'),
('18', '5', 'B', 'en', 'Article 14-18', '0'),
('19', '5', 'C', 'en', 'Article 19-22', '0'),
('20', '5', 'D', 'en', 'Article 25-28', '0'),
('21', '6', 'A', 'en', '12', '0'),
('22', '6', 'B', 'en', '16', '0'),
('23', '6', 'C', 'en', '24', '0'),
('24', '6', 'D', 'en', '48', '1'),
('25', '7', 'A', 'en', '₹400', '0'),
('26', '7', 'B', 'en', '₹450', '1'),
('27', '7', 'C', 'en', '₹380', '0'),
('28', '7', 'D', 'en', '₹420', '0'),
('29', '8', 'A', 'en', '6 days', '0'),
('30', '8', 'B', 'en', '8 days', '1'),
('31', '8', 'C', 'en', '10 days', '0'),
('32', '8', 'D', 'en', '12 days', '0'),
('33', '9', 'A', 'en', '₹2,000', '0'),
('34', '9', 'B', 'en', '₹2,100', '1'),
('35', '9', 'C', 'en', '₹2,200', '0'),
('36', '9', 'D', 'en', '₹2,050', '0'),
('37', '10', 'A', 'en', '20', '0'),
('38', '10', 'B', 'en', '21', '0'),
('39', '10', 'C', 'en', '22', '1'),
('40', '10', 'D', 'en', '24', '0'),
('41', '11', 'A', 'en', 'Humidity', '0'),
('42', '11', 'B', 'en', 'Pressure', '1'),
('43', '11', 'C', 'en', 'Current', '0'),
('44', '11', 'D', 'en', 'Earthquake', '0'),
('45', '12', 'A', 'en', 'FZQCDM', '1'),
('46', '12', 'B', 'en', 'FZQCEN', '0'),
('47', '12', 'C', 'en', 'EYPBDM', '0'),
('48', '12', 'D', 'en', 'GZQDDM', '0'),
('49', '13', 'A', 'en', 'Brother', '0'),
('50', '13', 'B', 'en', 'Son', '1'),
('51', '13', 'C', 'en', 'Father', '0'),
('52', '13', 'D', 'en', 'Nephew', '0'),
('53', '14', 'A', 'en', '50', '0'),
('54', '14', 'B', 'en', '52', '0'),
('55', '14', 'C', 'en', '54', '1'),
('56', '14', 'D', 'en', '56', '0'),
('57', '15', 'A', 'en', 'Only I follows', '0'),
('58', '15', 'B', 'en', 'Only II follows', '0'),
('59', '15', 'C', 'en', 'Both I and II follow', '0'),
('60', '15', 'D', 'en', 'Neither follows', '1'),
('61', '16', 'A', 'en', 'Flexible', '0'),
('62', '16', 'B', 'en', 'Stubborn', '0'),
('63', '16', 'C', 'en', 'Gentle', '1'),
('64', '16', 'D', 'en', 'Docile', '0'),
('65', '17', 'A', 'en', 'Acommodate', '0'),
('66', '17', 'B', 'en', 'Accomodate', '1'),
('67', '17', 'C', 'en', 'Accommodate', '0'),
('68', '17', 'D', 'en', 'Acomodate', '0'),
('69', '18', 'A', 'en', 'Neither the principal', '0'),
('70', '18', 'B', 'en', 'nor the teachers', '0'),
('71', '18', 'C', 'en', 'was present', '1'),
('72', '18', 'D', 'en', 'at the meeting', '0'),
('73', '19', 'A', 'en', 'To waste food', '0'),
('74', '19', 'B', 'en', 'To reveal a secret', '1'),
('75', '19', 'C', 'en', 'To cook well', '0'),
('76', '19', 'D', 'en', 'To cause delay', '0'),
('77', '20', 'A', 'en', 'Article 14', '0'),
('78', '20', 'B', 'en', 'Article 17', '1'),
('79', '20', 'C', 'en', 'Article 21', '0'),
('80', '20', 'D', 'en', 'Article 23', '0'),
('81', '21', 'A', 'en', 'Lord Mountbatten', '1'),
('82', '21', 'B', 'en', 'C. Rajagopalachari', '0'),
('83', '21', 'C', 'en', 'Dr. Rajendra Prasad', '0'),
('84', '21', 'D', 'en', 'Jawaharlal Nehru', '0'),
('85', '22', 'A', 'en', 'Rajasthan', '0'),
('86', '22', 'B', 'en', 'Chhattisgarh', '1'),
('87', '22', 'C', 'en', 'Odisha', '0'),
('88', '22', 'D', 'en', 'Tripura', '0'),
('89', '23', 'A', 'en', 'Data Business Management System', '1'),
('90', '23', 'B', 'en', 'Database Management System', '0'),
('91', '23', 'C', 'en', 'Digital Basic Multi System', '0'),
('92', '23', 'D', 'en', 'Direct Binary Management Software', '0'),
('93', '24', 'A', 'en', 'Congo Red', '1'),
('94', '24', 'B', 'en', 'Periodic acid-Schiff', '0'),
('95', '24', 'C', 'en', 'Masson trichrome', '0'),
('96', '24', 'D', 'en', 'Oil Red O', '0'),
('97', '25', 'A', 'en', 'Gs - Increases cAMP', '0'),
('98', '25', 'B', 'en', 'Gi - Increases cAMP', '0'),
('99', '25', 'C', 'en', 'Gq - Decreases IP3', '1'),
('100', '25', 'D', 'en', 'Gt - Increases cGMP', '0'),
('101', '26', 'A', 'en', '85%', '1'),
('102', '26', 'B', 'en', '90%', '0'),
('103', '26', 'C', 'en', '92%', '0'),
('104', '26', 'D', 'en', '95%', '0'),
('105', '27', 'A', 'en', 'Inactivation of voltage-gated Na+ channels', '0'),
('106', '27', 'B', 'en', 'Opening of voltage-gated K+ channels', '1'),
('107', '27', 'C', 'en', 'Closure of Cl- channels', '0'),
('108', '27', 'D', 'en', 'Activation of Ca2+ channels', '0'),
('109', '28', 'A', 'en', 'Nucleotide Excision Repair (NER)', '0'),
('110', '28', 'B', 'en', 'Base Excision Repair (BER)', '0'),
('111', '28', 'C', 'en', 'Mismatch Repair (MMR)', '1'),
('112', '28', 'D', 'en', 'Homologous Recombination', '0'),
('113', '1', 'A', 'hi', '120%', '0'),
('114', '1', 'B', 'hi', '150%', '1'),
('115', '1', 'C', 'hi', '133.33%', '0'),
('116', '1', 'D', 'hi', '166.66%', '0'),
('117', '2', 'A', 'hi', '18%', '0'),
('118', '2', 'B', 'hi', '19%', '1'),
('119', '2', 'C', 'hi', '20%', '0'),
('120', '2', 'D', 'hi', '25%', '0'),
('121', '3', 'A', 'hi', 'FZQCDM', '1'),
('122', '3', 'B', 'hi', 'EYPBDL', '0'),
('123', '3', 'C', 'hi', 'FZRCEM', '0'),
('124', '3', 'D', 'hi', 'HBSEFO', '0'),
('125', '4', 'A', 'hi', 'Neither of the', '0'),
('126', '4', 'B', 'hi', 'two candidates', '0'),
('127', '4', 'C', 'hi', 'have submitted', '1'),
('128', '4', 'D', 'hi', 'their documents', '0'),
('129', '5', 'A', 'hi', 'अनुच्छेद 12-13', '1'),
('130', '5', 'B', 'hi', 'अनुच्छेद 14-18', '0'),
('131', '5', 'C', 'hi', 'अनुच्छेद 19-22', '0'),
('132', '5', 'D', 'hi', 'अनुच्छेद 25-28', '0'),
('133', '6', 'A', 'hi', '12', '0'),
('134', '6', 'B', 'hi', '16', '0'),
('135', '6', 'C', 'hi', '24', '0'),
('136', '6', 'D', 'hi', '48', '1'),
('137', '7', 'A', 'hi', '₹400', '0'),
('138', '7', 'B', 'hi', '₹450', '1'),
('139', '7', 'C', 'hi', '₹380', '0'),
('140', '7', 'D', 'hi', '₹420', '0'),
('141', '8', 'A', 'hi', '6 दिन', '0'),
('142', '8', 'B', 'hi', '8 दिन', '1'),
('143', '8', 'C', 'hi', '10 दिन', '0'),
('144', '8', 'D', 'hi', '12 दिन', '0'),
('145', '9', 'A', 'hi', '₹2,000', '0'),
('146', '9', 'B', 'hi', '₹2,100', '1'),
('147', '9', 'C', 'hi', '₹2,200', '0'),
('148', '9', 'D', 'hi', '₹2,050', '0'),
('149', '10', 'A', 'hi', '20', '0'),
('150', '10', 'B', 'hi', '21', '0'),
('151', '10', 'C', 'hi', '22', '1'),
('152', '10', 'D', 'hi', '24', '0'),
('153', '11', 'A', 'hi', 'आर्द्रता', '0'),
('154', '11', 'B', 'hi', 'दाब (Pressure)', '1'),
('155', '11', 'C', 'hi', 'विद्युत धारा', '0'),
('156', '11', 'D', 'hi', 'भूकंप', '0'),
('157', '12', 'A', 'hi', 'FZQCDM', '1'),
('158', '12', 'B', 'hi', 'FZQCEN', '0'),
('159', '12', 'C', 'hi', 'EYPBDM', '0'),
('160', '12', 'D', 'hi', 'GZQDDM', '0'),
('161', '13', 'A', 'hi', 'भाई', '0'),
('162', '13', 'B', 'hi', 'बेटा (Son)', '1'),
('163', '13', 'C', 'hi', 'पिता', '0'),
('164', '13', 'D', 'hi', 'भांजा/भतीजा', '0'),
('165', '14', 'A', 'hi', '50', '0'),
('166', '14', 'B', 'hi', '52', '0'),
('167', '14', 'C', 'hi', '54', '1'),
('168', '14', 'D', 'hi', '56', '0'),
('169', '15', 'A', 'hi', 'केवल I अनुसरण करता है', '0'),
('170', '15', 'B', 'hi', 'केवल II अनुसरण करता है', '0'),
('171', '15', 'C', 'hi', 'I और II दोनों अनुसरण करते हैं', '0'),
('172', '15', 'D', 'hi', 'कोई भी अनुसरण नहीं करता', '1'),
('173', '16', 'A', 'hi', 'Flexible (लचीला)', '0'),
('174', '16', 'B', 'hi', 'Stubborn (जिद्दी)', '0'),
('175', '16', 'C', 'hi', 'Gentle (सौम्य)', '1'),
('176', '16', 'D', 'hi', 'Docile (विनम्र)', '0'),
('177', '17', 'A', 'hi', 'Acommodate', '0'),
('178', '17', 'B', 'hi', 'Accomodate', '1'),
('179', '17', 'C', 'hi', 'Accommodate', '0'),
('180', '17', 'D', 'hi', 'Acomodate', '0'),
('181', '18', 'A', 'hi', 'Neither the principal', '0'),
('182', '18', 'B', 'hi', 'nor the teachers', '0'),
('183', '18', 'C', 'hi', 'was present (त्रुटि: were present होगा)', '1'),
('184', '18', 'D', 'hi', 'at the meeting', '0'),
('185', '19', 'A', 'hi', 'भोजन बर्बाद करना', '0'),
('186', '19', 'B', 'hi', 'रहस्य उजागर करना (To reveal a secret)', '1'),
('187', '19', 'C', 'hi', 'अच्छा खाना बनाना', '0'),
('188', '19', 'D', 'hi', 'देरी करना', '0'),
('189', '20', 'A', 'hi', 'अनुच्छेद 14', '0'),
('190', '20', 'B', 'hi', 'अनुच्छेद 17', '1'),
('191', '20', 'C', 'hi', 'अनुच्छेद 21', '0'),
('192', '20', 'D', 'hi', 'अनुच्छेद 23', '0'),
('193', '21', 'A', 'hi', 'लॉर्ड माउंटबेटन', '1'),
('194', '21', 'B', 'hi', 'सी. राजगोपालाचारी', '0'),
('195', '21', 'C', 'hi', 'डॉ. राजेंद्र प्रसाद', '0'),
('196', '21', 'D', 'hi', 'जवाहरलाल नेहरू', '0'),
('197', '22', 'A', 'hi', 'राजस्थान', '0'),
('198', '22', 'B', 'hi', 'छत्तीसगढ़', '1'),
('199', '22', 'C', 'hi', 'ओडिशा', '0'),
('200', '22', 'D', 'hi', 'त्रिपुरा', '0'),
('201', '23', 'A', 'hi', 'Data Business Management System', '1'),
('202', '23', 'B', 'hi', 'Database Management System', '0'),
('203', '23', 'C', 'hi', 'Digital Basic Multi System', '0'),
('204', '23', 'D', 'hi', 'Direct Binary Management Software', '0'),
('205', '24', 'A', 'hi', 'कांगो रेड (Congo Red)', '1'),
('206', '24', 'B', 'hi', 'पीरियोडिक एसिड-शिफ (PAS)', '0'),
('207', '24', 'C', 'hi', 'मैसन ट्राइक्रोम', '0'),
('208', '24', 'D', 'hi', 'ऑयल रेड ओ', '0'),
('209', '25', 'A', 'hi', 'Gs - cAMP को बढ़ाता है', '0'),
('210', '25', 'B', 'hi', 'Gi - cAMP को बढ़ाता है', '0'),
('211', '25', 'C', 'hi', 'Gq - IP3 को घटाता है', '1'),
('212', '25', 'D', 'hi', 'Gt - cGMP को बढ़ाता है', '0'),
('213', '26', 'A', 'hi', '85%', '1'),
('214', '26', 'B', 'hi', '90%', '0'),
('215', '26', 'C', 'hi', '92%', '0'),
('216', '26', 'D', 'hi', '95%', '0'),
('217', '27', 'A', 'hi', 'वोल्टेज-गेटेड Na+ चैनलों का निष्क्रिय होना', '0'),
('218', '27', 'B', 'hi', 'वोल्टेज-गेटेड K+ चैनलों का खुलना', '1'),
('219', '27', 'C', 'hi', 'Cl- चैनलों का बंद होना', '0'),
('220', '27', 'D', 'hi', 'Ca2+ चैनलों का सक्रिय होना', '0'),
('221', '28', 'A', 'hi', 'न्यूक्लियोटाइड एक्सीशन रिपेयर (NER)', '0'),
('222', '28', 'B', 'hi', 'बेस एक्सीशन रिपेयर (BER)', '0'),
('223', '28', 'C', 'hi', 'मिसमैच रिपेयर (MMR)', '1'),
('224', '28', 'D', 'hi', 'होमोलॉगस रीकॉम्बिनेशन', '0');

-- --------------------------------------------------------
-- Table structure for `question_reports`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_reports`;
CREATE TABLE `question_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `report_reason` enum('wrong_answer','multiple_correct','no_correct_option','explanation_conflict','typo','duplicate','outdated','wrong_taxonomy','broken_image','other') NOT NULL,
  `report_notes` text DEFAULT NULL,
  `status` enum('pending','under_review','resolved','dismissed') NOT NULL DEFAULT 'pending',
  `resolution_action` varchar(64) DEFAULT NULL,
  `resolution_note` text DEFAULT NULL,
  `resolved_by` int(11) DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_qr_q_status` (`question_id`,`status`),
  KEY `idx_qr_user` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `question_reports`
INSERT INTO `question_reports` (`id`, `question_id`, `user_id`, `report_reason`, `report_notes`, `status`, `resolution_action`, `resolution_note`, `resolved_by`, `resolved_at`, `created_at`) VALUES
('1', '1', '11', 'wrong_answer', 'Option B is mathematically correct according to official key.', 'pending', NULL, NULL, NULL, NULL, '2026-09-05 11:37:41');

-- --------------------------------------------------------
-- Table structure for `question_revisions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_revisions`;
CREATE TABLE `question_revisions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question_id` int(11) NOT NULL,
  `revision_no` int(11) NOT NULL DEFAULT 1,
  `question_text` text NOT NULL,
  `option_a` text NOT NULL,
  `option_b` text NOT NULL,
  `option_c` text NOT NULL,
  `option_d` text NOT NULL,
  `correct_option` varchar(8) NOT NULL,
  `explanation` text DEFAULT NULL,
  `shortcut_trick` text DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `topic_id` int(11) DEFAULT NULL,
  `difficulty` enum('easy','medium','hard') NOT NULL DEFAULT 'medium',
  `language` varchar(16) NOT NULL DEFAULT 'en',
  `change_reason` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `moderation_status` enum('draft','submitted','under_review','approved','published','rejected','unpublished') NOT NULL DEFAULT 'submitted',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_qr_question` (`question_id`),
  KEY `idx_qr_rev` (`question_id`,`revision_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `question_topup_runs`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_topup_runs`;
CREATE TABLE `question_topup_runs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `exam_id` int(11) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `difficulty` enum('easy','medium','hard') DEFAULT NULL,
  `requested` int(11) NOT NULL DEFAULT 0,
  `generated_count` int(11) NOT NULL DEFAULT 0,
  `duplicates_rejected` int(11) NOT NULL DEFAULT 0,
  `inserted` int(11) NOT NULL DEFAULT 0,
  `status` enum('running','completed','error') NOT NULL DEFAULT 'running',
  `error_message` text DEFAULT NULL,
  `started_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `finished_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_topup_started` (`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `question_translations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `question_translations`;
CREATE TABLE `question_translations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question_id` int(11) NOT NULL,
  `language` varchar(10) NOT NULL DEFAULT 'en',
  `question_text` longtext NOT NULL,
  `solution_text` longtext DEFAULT NULL,
  `shortcut_text` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `q_lang` (`question_id`,`language`),
  CONSTRAINT `question_translations_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `question_translations`
INSERT INTO `question_translations` (`id`, `question_id`, `language`, `question_text`, `solution_text`, `shortcut_text`) VALUES
('1', '1', 'en', 'If 20% of A is equal to 30% of B, then what percentage of B is A?', '0.20 * A = 0.30 * B => A / B = 3 / 2 = 1.5 => A is 150% of B.', 'A/B = 30/20 = 3/2 -> 1.5 -> 150%. Direct Ratio multiplier!'),
('2', '1', 'hi', 'यदि A का 20% B के 30% के बराबर है, तो A, B का कितना प्रतिशत है?', '0.20 * A = 0.30 * B => A / B = 3 / 2 = 1.5 => A, B का 150% है।', 'A/B = 3/2 = 1.5 -> 150%। सीधा अनुपात का नियम!'),
('3', '2', 'en', 'A shopkeeper marks an item 40% above cost price and allows a 15% discount. What is his profit percentage?', 'Let CP = 100. MP = 140. SP = 140 * 0.85 = 119. Profit = 19%.', 'Effective Profit % = x - y - (x*y)/100 = 40 - 15 - (40*15)/100 = 25 - 6 = 19%.'),
('4', '2', 'hi', 'एक दुकानदार किसी वस्तु का मूल्य क्रय मूल्य से 40% अधिक अंकित करता है और 15% की छूट देता है। उसका लाभ प्रतिशत क्या है?', 'माना क्रय मूल्य (CP) = 100. अंकित मूल्य (MP) = 140. विक्रय मूल्य (SP) = 140 * 0.85 = 119. लाभ = 19%.', 'प्रभावशाली लाभ % = 40 - 15 - (40*15)/100 = 19%.'),
('5', '3', 'en', 'In a certain code language, \"FLOWER\" is written as \"EKNVDQ\". How is \"GARDEN\" written in that code?', 'Each letter is shifted by -1: G->F, A->Z, R->Q, D->C, E->D, N->M => FZQCDM.', 'Shift pattern is -1 for all letters.'),
('6', '4', 'en', 'Identify the error in the sentence: \"Neither of the two candidates have submitted their documents.\"', '\"Neither of\" takes a singular verb. \"have submitted\" should be \"has submitted\".', 'Rule: Neither of + Plural Noun + Singular Verb!'),
('7', '5', 'en', 'Which Article of the Constitution of India deals with the Right to Equality?', 'Articles 14 to 18 of the Indian Constitution deal with the Right to Equality.', 'Articles 14-18 = Right to Equality.'),
('8', '6', 'en', 'If the ratio of two numbers is 3 : 4 and their HCF is 4, then their LCM is:', 'Numbers are 3*4 = 12 and 4*4 = 16. LCM(12, 16) = 48.', NULL),
('9', '7', 'en', 'A shopkeeper sells an article at a discount of 20% on the marked price and still gains 20%. If marked price is ₹600, find the cost price.', 'SP = 600 * 0.80 = 480. CP = 480 / 1.20 = ₹400.', NULL),
('10', '8', 'en', 'A and B can do a work in 12 days and 18 days respectively. They worked together for 4 days after which A left. In how many more days will B finish the remaining work?', 'Total work = 36 units. A = 3, B = 2. 4 days work = (3+2)*4 = 20 units. Remaining = 16 units. B time = 16/2 = 8 days.', NULL),
('11', '9', 'en', 'What is the compound interest on ₹10,000 for 2 years at 10% per annum, compounded annually?', 'A = 10000 * (1.1)^2 = 12100. CI = 12100 - 10000 = ₹2,100.', NULL),
('12', '10', 'en', 'The average of 5 consecutive numbers is 20. What is the largest of these numbers?', 'Let numbers be x, x+1, x+2, x+3, x+4. Average is x+2 = 20 => x = 18. Largest = x+4 = 22.', NULL),
('13', '11', 'en', 'Select the option that is related to the third word in the same way as the second word is related to the first word:\\nThermometer : Temperature :: Barometer : ?', 'Thermometer measures Temperature; Barometer measures Atmospheric Pressure.', NULL),
('14', '12', 'en', 'In a certain code language, \"FLOWER\" is written as \"EKNVDQ\". How will \"GARDEN\" be written in that language?', 'Shift of -1 for each letter => FZQCDM.', NULL),
('15', '13', 'en', 'Pointing to a photograph, a woman says, \"He is the son of the only daughter of my father.\" How is the man in the photograph related to the woman?', 'Only daughter of my father = Woman herself. Son of woman = Her son.', NULL),
('16', '14', 'en', 'Which number will replace the question mark (?) in the following series?\\n7, 10, 16, 25, 37, ?', 'Differences: +3, +6, +9, +12, +15 => 37 + 15 = 52.', NULL),
('17', '15', 'en', 'Statements:\n1. All dogs are mammals.\n2. All mammals are animals.\nConclusions:\nI. All dogs are animals.\nII. Some animals are dogs.', 'Both conclusions I and II logically follow.', NULL),
('18', '16', 'en', 'Select the most appropriate synonym of the given word:\\nOBSTINATE', 'Obstinate means stubbornly refusing to change one\'s opinion. Synonym is Stubborn.', NULL),
('19', '17', 'en', 'Select the correctly spelt word:', '\"Accommodate\" is the correct spelling with double c and double m.', NULL),
('20', '18', 'en', 'Identify the segment containing a grammatical error:\\n\"Neither the principal nor the teachers was present at the meeting.\"', 'When subjects are joined by \"neither...nor\", verb agrees with closer subject (teachers = plural => were present).', NULL),
('21', '19', 'en', 'Select the meaning of the given idiom:\\n\"Spill the beans\"', 'To \"spill the beans\" means to reveal a secret prematurely or indiscreetly.', NULL),
('22', '20', 'en', 'Which fundamental right in the Indian Constitution guarantees protection against untouchability?', 'Article 17 of the Indian Constitution abolishes Untouchability.', NULL),
('23', '21', 'en', 'Who was the first Governor-General of Independent India?', 'Lord Mountbatten was the first Governor-General of independent India. C. Rajagopalachari was the first Indian Governor-General.', NULL),
('24', '22', 'en', 'The Tropic of Cancer does NOT pass through which of the following Indian states?', 'Tropic of Cancer passes through 8 states: Gujarat, Rajasthan, MP, Chhattisgarh, Jharkhand, West Bengal, Tripura, Mizoram. It does NOT pass through Odisha.', NULL),
('25', '23', 'en', 'What is the full form of DBMS in computer science?', 'DBMS stands for Database Management System.', NULL),
('26', '24', 'en', 'A patient with long-standing rheumatoid arthritis undergoes a renal biopsy. Microscopic examination demonstrates extracellular amorphous eosinophilic deposits. Which special stain will display apple-green birefringence under polarized light?', 'Congo Red stain demonstrates apple-green birefringence under polarized light in amyloidosis.', NULL),
('27', '25', 'en', 'Which of the following G-protein subunits is correctly paired with its downstream second messenger mechanism?', 'Gs stimulates adenylyl cyclase, increasing cyclic AMP (cAMP).', NULL),
('28', '26', 'en', 'A diagnostic test for Malaria correctly identifies 180 out of 200 diseased individuals as positive. What is the sensitivity of this diagnostic test?', 'Sensitivity = True Positives / Total Diseased = 180 / 200 = 90%.', NULL),
('29', '27', 'en', 'During the absolute refractory period of a neuronal action potential, a second action potential cannot be elicited. Which mechanism primarily accounts for this phenomenon?', 'Inactivation of voltage-gated sodium (Na+) channels prevents generation of another action potential.', NULL),
('30', '28', 'en', 'A 6-year-old child presents with severe photosensitivity, freckling, and early skin neoplasms on sun-exposed areas (Xeroderma Pigmentosum). Which DNA repair mechanism is defective?', 'Xeroderma Pigmentosum is caused by a defect in Nucleotide Excision Repair (NER).', NULL),
('36', '3', 'hi', 'एक निश्चित कूट भाषा में, \"FLOWER\" को \"EKNVDQ\" लिखा जाता है। उसी कूट भाषा में \"GARDEN\" को कैसे लिखा जाएगा?', 'प्रत्येक अक्षर में -1 का बदलाव है: G->F, A->Z, R->Q, D->C, E->D, N->M => FZQCDM.', 'शॉर्टकट'),
('38', '4', 'hi', 'वाक्य में त्रुटि पहचानें: \"Neither of the two candidates have submitted their documents.\"', '\"Neither of\" के साथ एकवचन क्रिया (singular verb) का प्रयोग होता है। \"have submitted\" के स्थान पर \"has submitted\" होगा।', 'शॉर्टकट'),
('40', '5', 'hi', 'भारत के संविधान का कौन सा अनुच्छेद समानता के अधिकार (Right to Equality) से संबंधित है?', 'भारतीय संविधान के अनुच्छेद 14 से 18 समानता के अधिकार से संबंधित हैं।', 'शॉर्टकट'),
('42', '6', 'hi', 'यदि दो संख्याओं का अनुपात 3 : 4 है और उनका म.स.प. (HCF) 4 है, तो उनका ल.स.प. (LCM) क्या होगा?', 'संख्याएं 3*4 = 12 और 4*4 = 16 हैं। LCM(12, 16) = 48.', 'शॉर्टकट'),
('44', '7', 'hi', 'एक दुकानदार अंकित मूल्य पर 20% की छूट देकर भी 20% का लाभ कमाता है। यदि अंकित मूल्य ₹600 है, तो क्रय मूल्य ज्ञात कीजिए।', 'SP = 600 * 0.80 = 480. CP = 480 / 1.20 = ₹400.', 'शॉर्टकट'),
('46', '8', 'hi', 'A और B किसी काम को क्रमशः 12 दिन और 18 दिन में पूरा कर सकते हैं। उन्होंने 4 दिनों तक एक साथ काम किया, जिसके बाद A चला गया। B शेष कार्य को कितने और दिनों में पूरा करेगा?', 'कुल कार्य = 36 यूनिट। A = 3, B = 2. 4 दिनों का कार्य = 5*4 = 20 यूनिट। शेष = 16 यूनिट। B द्वारा लिया गया समय = 16/2 = 8 दिन।', 'शॉर्टकट'),
('48', '9', 'hi', '₹10,000 पर 10% वार्षिक दर से 2 वर्ष का वार्षिक संयोजित चक्रवृद्धि ब्याज (Compound Interest) क्या होगा?', 'A = 10000 * (1.1)^2 = 12100. CI = 12100 - 10000 = ₹2,100.', 'शॉर्टकट'),
('50', '10', 'hi', '5 क्रमागत (लगातार) संख्याओं का औसत 20 है। इनमें से सबसे बड़ी संख्या कौन सी है?', 'संख्याएं x, x+1, x+2, x+3, x+4 हैं। औसत = x+2 = 20 => x = 18. सबसे बड़ी संख्या = 18+4 = 22.', 'शॉर्टकट'),
('52', '11', 'hi', 'उस विकल्प का चयन करें जो तीसरे शब्द से उसी प्रकार संबंधित है जैसे दूसरा शब्द पहले शब्द से संबंधित है:\\nथर्मामीटर : तापमान :: बैरोमीटर : ?', 'थर्मामीटर तापमान मापता है; बैरोमीटर वायुमंडलीय दाब (Pressure) मापता है।', 'शॉर्टकट'),
('54', '12', 'hi', 'एक निश्चित कूट भाषा में, \"FLOWER\" को \"EKNVDQ\" लिखा जाता है। उसी भाषा में \"GARDEN\" को क्या लिखा जाएगा?', 'प्रत्येक अक्षर -1 घटता है => FZQCDM.', 'शॉर्टकट'),
('56', '13', 'hi', 'एक तस्वीर की ओर इशारा करते हुए एक महिला कहती है, \"वह मेरे पिता की इकलौती बेटी का बेटा है।\" तस्वीर वाला व्यक्ति उस महिला से किस प्रकार संबंधित है?', 'मेरे पिता की इकलौती बेटी = महिला स्वयं। महिला का बेटा = उसका पुत्र (Son)।', 'शॉर्टकट'),
('58', '14', 'hi', 'निम्नलिखित श्रृंखला में प्रश्न चिह्न (?) के स्थान पर कौन सी संख्या आएगी?\\n7, 10, 16, 25, 37, ?', 'अंतर: +3, +6, +9, +12, +15 => 37 + 15 = 52.', 'शॉर्टकट'),
('60', '15', 'hi', 'कथन:\n1. सभी कुत्ते स्तनधारी हैं।\n2. सभी स्तनधारी जानवर हैं।\nनिष्कर्ष:\nI. सभी कुत्ते जानवर हैं।\nII. कुछ जानवर कुत्ते हैं।', 'दोनों निष्कर्ष I और II तार्किक रूप से अनुसरण करते हैं।', 'शॉर्टकट'),
('62', '16', 'hi', 'दिए गए शब्द का सबसे उपयुक्त समानार्थी (Synonym) चुनें:\\nOBSTINATE (हठी/जिद्दी)', 'Obstinate का अर्थ जिद्दी/हठी होता है। इसका पर्यायवाची Stubborn है।', 'शॉर्टकट'),
('64', '17', 'hi', 'सही वर्तनी (Correctly spelt) वाले शब्द का चयन करें:', '\"Accommodate\" सही वर्तनी है (double c और double m के साथ)।', 'शॉर्टकट'),
('66', '18', 'hi', 'व्याकरणिक त्रुटि वाले भाग की पहचान करें:\\n\"Neither the principal nor the teachers was present at the meeting.\"', '\"neither...nor\" में क्रिया निकटतम कर्ता (teachers = बहुवचन) के अनुसार \"were present\" होनी चाहिए।', 'शॉर्टकट'),
('68', '19', 'hi', 'दिए गए मुहावरे (Idiom) का अर्थ चुनें:\\n\"Spill the beans\"', '\"Spill the beans\" का अर्थ रहस्य या गुप्त बात उजागर करना (To reveal a secret) होता है।', 'शॉर्टकट'),
('70', '20', 'hi', 'भारतीय संविधान का कौन सा मौलिक अधिकार अस्पृश्यता (छुआछूत) के उन्मूलन की गारंटी देता है?', 'भारतीय संविधान का अनुच्छेद 17 अस्पृश्यता का उन्मूलन करता है।', 'शॉर्टकट'),
('72', '21', 'hi', 'स्वतंत्र भारत के प्रथम गवर्नर जनरल कौन थे?', 'लॉर्ड माउंटबेटन स्वतंत्र भारत के प्रथम गवर्नर जनरल थे। सी. राजगोपालाचारी प्रथम भारतीय गवर्नर जनरल थे।', 'शॉर्टकट'),
('74', '22', 'hi', 'कर्क रेखा (Tropic of Cancer) निम्नलिखित में से किस भारतीय राज्य से होकर नहीं गुजरती है?', 'कर्क रेखा 8 राज्यों (गुजरात, राजस्थान, मध्य प्रदेश, छत्तीसगढ़, झारखंड, पश्चिम बंगाल, त्रिपुरा, मिजोरम) से गुजरती है। यह ओडिशा से होकर नहीं गुजरती।', 'शॉर्टकट'),
('76', '23', 'hi', 'कंप्यूटर विज्ञान में DBMS का पूर्ण रूप (Full Form) क्या है?', 'DBMS का पूरा नाम Database Management System (डेटाबेस मैनेजमेंट सिस्टम) है।', 'शॉर्टकट'),
('78', '24', 'hi', 'लंबे समय से रुमेटीइड गठिया से पीड़ित एक मरीज की रीनल बायोप्सी की जाती है। पोलराइज्ड लाइट के तहत कौन सा विशेष स्टेन सेब-हरा (Apple-green) बाइरिफ्रिंजेंस प्रदर्शित करता है?', 'कांगो रेड (Congo Red) स्टेन एमाइलॉयडोसिस में पोलराइज्ड प्रकाश के तहत सेब-हरा बाइरिफ्रिंजेंस दिखाता है।', 'शॉर्टकट'),
('80', '25', 'hi', 'निम्नलिखित में से कौन सा जी-प्रोटीन सबयूनिट अपने डाउनस्ट्रीम सेकंड मैसेंजर तंत्र के साथ सही रूप से युग्मित है?', 'Gs एडेनिलाइल साइक्लेज को उत्तेजित करता है, जिससे चक्रीय एएमपी (cAMP) बढ़ता है।', 'शॉर्टकट'),
('82', '26', 'hi', 'मलेरिया के लिए एक नैदानिक परीक्षण 200 रोगग्रस्त व्यक्तियों में से 180 की सही पहचान पॉजिटिव के रूप में करता है। इस परीक्षण की संवेदनशीलता (Sensitivity) क्या है?', 'संवेदनशीलता (Sensitivity) = सही पॉजिटिव / कुल रोगग्रस्त = 180 / 200 = 90%.', 'शॉर्टकट'),
('84', '27', 'hi', 'न्यूरोनल एक्शन पोटेंशियल के एब्सोल्यूट रिफ्रैक्टरी पीरियड के दौरान दूसरा एक्शन पोटेंशियल उत्पन्न नहीं हो सकता। इसके लिए कौन सा तंत्र प्राथमिक रूप से उत्तरदायी है?', 'वोल्टेज-गेटेड सोडियम (Na+) चैनलों का निष्क्रिय होना (Inactivation) प्राथमिक कारण है।', 'शॉर्टकट'),
('86', '28', 'hi', 'धूप के संपर्क में आने से गंभीर फोटोसेंसिटिविटी और त्वचा नियोप्लाज्म से पीड़ित जेरोडर्मा पिगमेंटोसम (Xeroderma Pigmentosum) में कौन सा डीएनए रिपेयर तंत्र दोषपूर्ण होता है?', 'जेरोडर्मा पिगमेंटोसम न्यूक्लियोटाइड एक्सीशन रिपेयर (NER) में दोष के कारण होता है।', 'शॉर्टकट');

-- --------------------------------------------------------
-- Table structure for `questions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `questions`;
CREATE TABLE `questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subject_id` int(11) NOT NULL,
  `chapter_id` int(11) DEFAULT NULL,
  `topic_id` int(11) DEFAULT NULL,
  `author_user_id` int(11) DEFAULT NULL,
  `question_type` enum('MCQ','NUMERICAL') DEFAULT 'MCQ',
  `difficulty` enum('easy','medium','hard') DEFAULT 'medium',
  `pyq_year` int(11) DEFAULT NULL,
  `pyq_shift` varchar(50) DEFAULT NULL,
  `status` enum('draft','review','published','rejected') DEFAULT 'published',
  `reviewed_by` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `rejection_reason` varchar(500) DEFAULT NULL,
  `content_hash` char(64) DEFAULT NULL,
  `structure_hash` char(64) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `subject_id` (`subject_id`),
  KEY `chapter_id` (`chapter_id`),
  KEY `topic_id` (`topic_id`),
  KEY `fk_questions_reviewer` (`reviewed_by`),
  KEY `idx_questions_author` (`author_user_id`,`status`),
  KEY `idx_questions_review_queue` (`status`,`created_at`),
  KEY `idx_questions_content_hash` (`content_hash`),
  KEY `idx_questions_structure_hash` (`structure_hash`),
  KEY `idx_questions_draw` (`status`,`subject_id`,`difficulty`),
  CONSTRAINT `fk_questions_author` FOREIGN KEY (`author_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_questions_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL,
  CONSTRAINT `questions_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `questions_ibfk_2` FOREIGN KEY (`chapter_id`) REFERENCES `chapters` (`id`) ON DELETE SET NULL,
  CONSTRAINT `questions_ibfk_3` FOREIGN KEY (`topic_id`) REFERENCES `topics` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `questions`
INSERT INTO `questions` (`id`, `subject_id`, `chapter_id`, `topic_id`, `author_user_id`, `question_type`, `difficulty`, `pyq_year`, `pyq_shift`, `status`, `reviewed_by`, `reviewed_at`, `rejection_reason`, `content_hash`, `structure_hash`, `created_at`) VALUES
('1', '1', '1', '1', NULL, 'MCQ', 'medium', '2023', 'Shift 1', 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-21 14:22:31'),
('2', '1', '2', '3', NULL, 'MCQ', 'easy', '2023', 'Shift 2', 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-21 14:22:31'),
('3', '2', '3', '4', NULL, 'MCQ', 'medium', '2022', 'Shift 1', 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-21 14:22:31'),
('4', '3', '5', '5', NULL, 'MCQ', 'medium', '2023', 'Shift 3', 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-21 14:22:31'),
('5', '4', '6', '6', NULL, 'MCQ', 'easy', '2023', 'Shift 1', 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-21 14:22:31'),
('6', '1', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('7', '1', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('8', '1', NULL, NULL, NULL, 'MCQ', 'hard', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('9', '1', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('10', '1', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('11', '2', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('12', '2', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('13', '2', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('14', '2', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('15', '2', NULL, NULL, NULL, 'MCQ', 'hard', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('16', '3', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('17', '3', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('18', '3', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('19', '3', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('20', '4', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('21', '4', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('22', '4', NULL, NULL, NULL, 'MCQ', 'easy', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-25 18:41:36'),
('23', '6', NULL, NULL, NULL, 'MCQ', 'medium', '2026', NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-08-31 16:16:14'),
('24', '1', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-09-02 17:21:37'),
('25', '1', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-09-02 17:21:37'),
('26', '1', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-09-02 17:21:37'),
('27', '1', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-09-02 17:21:37'),
('28', '1', NULL, NULL, NULL, 'MCQ', 'medium', NULL, NULL, 'published', NULL, NULL, NULL, NULL, NULL, '2026-09-02 17:21:37');

-- --------------------------------------------------------
-- Table structure for `real_result_verifications`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `real_result_verifications`;
CREATE TABLE `real_result_verifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `exam_year` int(11) NOT NULL,
  `roll_number` varchar(100) NOT NULL,
  `actual_rank` int(11) NOT NULL,
  `best_mock_rank` int(11) DEFAULT NULL,
  `score_card_url` varchar(255) DEFAULT NULL,
  `status` enum('pending','verified','rejected') DEFAULT 'pending',
  `admin_remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `exam_id` (`exam_id`),
  CONSTRAINT `real_result_verifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `real_result_verifications_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `referral_codes`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `referral_codes`;
CREATE TABLE `referral_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `code` varchar(32) NOT NULL,
  `status` enum('active','suspended') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  UNIQUE KEY `code` (`code`),
  KEY `idx_ref_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `referral_codes`
INSERT INTO `referral_codes` (`id`, `user_id`, `code`, `status`, `created_at`) VALUES
('6', '7', 'EV907A4E', 'active', '2026-09-08 13:49:43'),
('10', '1', 'TESTREF4767', 'active', '2026-09-09 11:44:18'),
('11', '38', 'EVDDB467', 'active', '2026-09-10 10:52:23');

-- --------------------------------------------------------
-- Table structure for `referral_rewards`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `referral_rewards`;
CREATE TABLE `referral_rewards` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `referral_id` int(11) NOT NULL,
  `beneficiary_user_id` int(11) NOT NULL,
  `reward_type` enum('premium_days','bonus_coins','voucher') NOT NULL DEFAULT 'premium_days',
  `reward_days` int(11) NOT NULL DEFAULT 7,
  `idempotency_key` varchar(64) NOT NULL,
  `status` enum('issued','reversed') NOT NULL DEFAULT 'issued',
  `issued_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idempotency_key` (`idempotency_key`),
  KEY `idx_rr_ben` (`beneficiary_user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `referral_rewards`
INSERT INTO `referral_rewards` (`id`, `referral_id`, `beneficiary_user_id`, `reward_type`, `reward_days`, `idempotency_key`, `status`, `issued_at`) VALUES
('14', '8', '11', 'premium_days', '30', 'REF_FRIEND_8_11', 'issued', '2026-09-09 11:44:18'),
('15', '8', '1', 'premium_days', '7', 'REF_REFERRER_8_1', 'issued', '2026-09-09 11:44:18'),
('16', '9', '39', 'premium_days', '30', 'REF_FRIEND_9_39', 'issued', '2026-09-10 10:52:23'),
('17', '9', '38', 'premium_days', '7', 'REF_REFERRER_9_38', 'issued', '2026-09-10 10:52:23');

-- --------------------------------------------------------
-- Table structure for `referrals`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `referrals`;
CREATE TABLE `referrals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `referrer_user_id` int(11) NOT NULL,
  `referred_user_id` int(11) NOT NULL,
  `referral_code` varchar(32) NOT NULL,
  `status` enum('attributed','pending_qualification','qualified','rewarded','fraud_flagged') NOT NULL DEFAULT 'attributed',
  `rejection_reason` varchar(255) DEFAULT NULL,
  `qualified_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `referred_user_id` (`referred_user_id`),
  KEY `idx_ref_referrer` (`referrer_user_id`),
  KEY `idx_ref_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `referrals`
INSERT INTO `referrals` (`id`, `referrer_user_id`, `referred_user_id`, `referral_code`, `status`, `rejection_reason`, `qualified_at`, `created_at`) VALUES
('7', '11', '12', 'TESTREF9008', 'rewarded', NULL, '2026-09-09 10:44:38', '2026-09-09 10:44:38'),
('8', '1', '11', 'TESTREF4767', 'rewarded', NULL, '2026-09-09 11:44:18', '2026-09-09 11:44:18'),
('9', '38', '39', 'EVDDB467', 'rewarded', NULL, '2026-09-10 10:52:23', '2026-09-10 10:52:23');

-- --------------------------------------------------------
-- Table structure for `regrade_jobs`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `regrade_jobs`;
CREATE TABLE `regrade_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `test_id` int(11) NOT NULL,
  `test_version_id` int(11) DEFAULT NULL,
  `question_id` int(11) NOT NULL,
  `old_answer` varchar(16) NOT NULL,
  `new_answer` varchar(16) NOT NULL,
  `scoring_action` enum('change_key','give_bonus','exclude_question') NOT NULL DEFAULT 'change_key',
  `affected_attempts_count` int(11) NOT NULL DEFAULT 0,
  `processed_attempts_count` int(11) NOT NULL DEFAULT 0,
  `status` enum('queued','running','completed','failed') NOT NULL DEFAULT 'queued',
  `reason` text NOT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_rj_test` (`test_id`),
  KEY `idx_rj_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `states`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `states`;
CREATE TABLE `states` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `states`
INSERT INTO `states` (`id`, `code`, `name`, `created_at`) VALUES
('1', 'DL', 'Delhi', '2026-08-21 14:22:02'),
('2', 'MH', 'Maharashtra', '2026-08-21 14:22:02'),
('3', 'UP', 'Uttar Pradesh', '2026-08-21 14:22:02'),
('4', 'BR', 'Bihar', '2026-08-21 14:22:02'),
('5', 'RJ', 'Rajasthan', '2026-08-21 14:22:02'),
('6', 'MP', 'Madhya Pradesh', '2026-08-21 14:22:02'),
('7', 'WB', 'West Bengal', '2026-08-21 14:22:02'),
('8', 'TN', 'Tamil Nadu', '2026-08-21 14:22:02'),
('9', 'KA', 'Karnataka', '2026-08-21 14:22:02'),
('10', 'GJ', 'Gujarat', '2026-08-21 14:22:02');

-- --------------------------------------------------------
-- Table structure for `strategy_simulations`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `strategy_simulations`;
CREATE TABLE `strategy_simulations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `strategy_name` varchar(150) NOT NULL,
  `section_order_json` text NOT NULL,
  `time_allocation_json` text NOT NULL,
  `predicted_score_min` int(11) NOT NULL,
  `predicted_score_max` int(11) NOT NULL,
  `confidence_level` varchar(50) DEFAULT 'Medium',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `exam_id` (`exam_id`),
  CONSTRAINT `strategy_simulations_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `strategy_simulations_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `study_materials`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `study_materials`;
CREATE TABLE `study_materials` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `creator_id` int(11) NOT NULL,
  `exam_id` int(11) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `title` varchar(200) NOT NULL,
  `slug` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `tags` varchar(500) DEFAULT NULL,
  `file_path` varchar(500) NOT NULL,
  `cover_image_url` varchar(500) DEFAULT NULL,
  `file_size_kb` int(11) DEFAULT 0,
  `total_pages` int(11) DEFAULT 0,
  `preview_pages` int(11) DEFAULT 5,
  `language` varchar(20) DEFAULT 'en',
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_free` tinyint(1) DEFAULT 0,
  `status` enum('draft','pending_review','approved','rejected','archived') DEFAULT 'pending_review',
  `rejection_reason` text DEFAULT NULL,
  `total_downloads` int(11) DEFAULT 0,
  `total_revenue` decimal(12,2) DEFAULT 0.00,
  `rating_avg` decimal(3,2) DEFAULT 0.00,
  `rating_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `creator_id` (`creator_id`),
  KEY `exam_id` (`exam_id`),
  KEY `subject_id` (`subject_id`),
  CONSTRAINT `study_materials_ibfk_1` FOREIGN KEY (`creator_id`) REFERENCES `creators` (`id`) ON DELETE CASCADE,
  CONSTRAINT `study_materials_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE SET NULL,
  CONSTRAINT `study_materials_ibfk_3` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `subjects`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `subjects`;
CREATE TABLE `subjects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `code` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `subjects`
INSERT INTO `subjects` (`id`, `name`, `code`, `created_at`) VALUES
('1', 'Quantitative Aptitude', 'QUANT', '2026-08-21 14:22:31'),
('2', 'Reasoning & Intelligence', 'REASONING', '2026-08-21 14:22:31'),
('3', 'English Language', 'ENGLISH', '2026-08-21 14:22:31'),
('4', 'General Awareness & GK', 'GA', '2026-08-21 14:22:31'),
('5', 'Physics', 'PHY', '2026-08-21 14:22:31'),
('6', 'Chemistry', 'CHEM', '2026-08-21 14:22:31'),
('7', 'Mathematics', 'MATH', '2026-08-21 14:22:31');

-- --------------------------------------------------------
-- Table structure for `subscription_plans`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `subscription_plans`;
CREATE TABLE `subscription_plans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `duration_days` int(11) NOT NULL DEFAULT 30,
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `subscription_plans`
INSERT INTO `subscription_plans` (`id`, `name`, `duration_days`, `price`, `description`, `is_active`, `created_at`) VALUES
('1', 'Free Referral / Trial Pass', '30', '0.00', 'Complimentary 30-day access for new invited aspirants', '1', '2026-09-05 11:02:01'),
('2', 'Pro Monthly Pass', '30', '299.00', 'Unlimited mock tests, AI Exam-Twin, step-by-step solutions & shortcut tricks', '1', '2026-09-05 11:02:01'),
('3', 'Pro Quarterly Sprint', '90', '699.00', 'Complete tier access for 3 months with priority test series', '1', '2026-09-05 11:02:01'),
('4', 'ExamVerse Elite Annual', '365', '1999.00', 'All-inclusive annual pass for all exams, pyqs, map learning & mentor notes', '1', '2026-09-05 11:02:01'),
('5', 'QA Pro 60-Day Sprint (Test Plan)', '60', '499.00', 'Unlimited test series, AI insights and full mock tests for 60 days.', '1', '2026-09-10 10:52:23');

-- --------------------------------------------------------
-- Table structure for `system_settings`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `system_settings`;
CREATE TABLE `system_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` longtext DEFAULT NULL,
  `is_encrypted` tinyint(1) DEFAULT 0,
  `category` enum('sms','payment','general','ai') DEFAULT 'general',
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting_key` (`setting_key`),
  KEY `idx_category` (`category`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `system_settings`
INSERT INTO `system_settings` (`id`, `setting_key`, `setting_value`, `is_encrypted`, `category`, `description`, `created_at`, `updated_at`) VALUES
('1', 'sms_enabled', '0', '0', 'sms', 'Enable or disable live SMS gateway', '2026-09-08 14:45:36', '2026-09-09 10:44:01'),
('2', 'sms_provider', 'fast2sms', '0', 'sms', 'Active SMS provider: fast2sms, msg91, twilio, dev_mock', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('3', 'sms_api_key', 'v1.lAJfd+Ldr7sNd5EB0n2wwwIPFcvNVmuOMM32qAj+eCexGx1fqBcRUnaFxX/5TCk=', '1', 'sms', 'SMS Gateway API Key / Auth Token', '2026-09-08 14:45:36', '2026-09-08 14:47:36'),
('4', 'sms_sender_id', 'EXAMVR', '0', 'sms', 'SMS Sender ID / Header', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('5', 'sms_template_id', '', '0', 'sms', 'DLT Template ID (Fast2SMS/MSG91)', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('6', 'sms_entity_id', '', '0', 'sms', 'DLT Principal Entity ID', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('7', 'sms_route', 'otp', '0', 'sms', 'Fast2SMS route: otp or dlt', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('8', 'payment_enabled', '0', '0', 'payment', 'Enable live payment gateway', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('9', 'payment_mode', 'mock', '0', 'payment', 'Payment mode: mock, test, live', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('10', 'razorpay_key_id', '', '0', 'payment', 'Razorpay Key ID (rzp_test_... or rzp_live_...)', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('11', 'razorpay_key_secret', '', '1', 'payment', 'Razorpay Key Secret', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('12', 'razorpay_webhook_secret', '', '1', 'payment', 'Razorpay Webhook Secret', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('13', 'payment_currency', 'INR', '0', 'payment', 'Default payment currency', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('14', 'app_name', 'EXAMVERSE', '0', 'general', 'Application Display Name', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('15', 'support_email', 'support@examverse.com', '0', 'general', 'Official Support Email', '2026-09-08 14:45:36', '2026-09-08 14:45:36'),
('16', 'support_phone', '+91 9876543210', '0', 'general', 'Official Support Phone', '2026-09-08 14:45:36', '2026-09-08 14:45:36');

-- --------------------------------------------------------
-- Table structure for `teacher_applications`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `teacher_applications`;
CREATE TABLE `teacher_applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `application_no` varchar(64) NOT NULL,
  `user_id` int(11) NOT NULL,
  `highest_qualification` varchar(100) NOT NULL,
  `degree_name` varchar(150) NOT NULL,
  `specialization` varchar(150) DEFAULT NULL,
  `institution_name` varchar(255) NOT NULL,
  `passing_year` int(11) NOT NULL,
  `score_value` decimal(5,2) DEFAULT NULL,
  `score_type` enum('percentage','cgpa','grade') NOT NULL DEFAULT 'percentage',
  `experience_years` decimal(4,1) NOT NULL DEFAULT 0.0,
  `current_organization` varchar(255) DEFAULT NULL,
  `preferred_languages` varchar(255) DEFAULT NULL,
  `subject_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`subject_ids`)),
  `exam_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`exam_ids`)),
  `status` enum('draft','submitted','under_review','changes_required','approved','rejected','withdrawn','suspended') NOT NULL DEFAULT 'draft',
  `assigned_reviewer_id` int(11) DEFAULT NULL,
  `decision_reason_code` varchar(64) DEFAULT NULL,
  `reviewer_message` text DEFAULT NULL,
  `declaration_accepted` tinyint(1) NOT NULL DEFAULT 0,
  `declaration_timestamp` datetime DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `application_no` (`application_no`),
  KEY `idx_ta_user` (`user_id`),
  KEY `idx_ta_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `teacher_applications`
INSERT INTO `teacher_applications` (`id`, `application_no`, `user_id`, `highest_qualification`, `degree_name`, `specialization`, `institution_name`, `passing_year`, `score_value`, `score_type`, `experience_years`, `current_organization`, `preferred_languages`, `subject_ids`, `exam_ids`, `status`, `assigned_reviewer_id`, `decision_reason_code`, `reviewer_message`, `declaration_accepted`, `declaration_timestamp`, `submitted_at`, `reviewed_at`, `approved_at`, `created_at`, `updated_at`) VALUES
('3', 'TCH-2025-4587', '7', 'Post Graduate', 'M.Sc Physics', NULL, 'Delhi University', '2020', NULL, 'percentage', '6.0', 'Apex IIT Academy', NULL, NULL, NULL, 'approved', '1', NULL, 'Application and credentials approved.', '0', NULL, '2026-09-05 11:37:16', '2026-09-10 11:59:23', '2026-09-10 11:59:23', '2026-09-05 11:37:16', '2026-09-10 11:59:23'),
('4', 'TCH-2025-4586', '8', 'Graduate', 'B.Tech Mechanical', NULL, 'IIT Delhi', '2021', NULL, 'percentage', '4.0', 'Target JEE Classes', NULL, NULL, NULL, 'approved', '1', NULL, 'Approved credentials & verified KYC documents.', '0', NULL, '2026-09-05 11:37:41', '2026-09-10 11:56:59', '2026-09-10 11:56:59', '2026-09-05 11:37:41', '2026-09-10 11:56:59'),
('5', 'TCH-2025-4585', '9', 'Post Graduate', 'M.A History', NULL, 'Jawaharlal Nehru University', '2018', NULL, 'percentage', '8.0', 'UPSC Mentors Guild', NULL, NULL, NULL, 'approved', '1', NULL, 'Application and credentials approved.', '0', NULL, '2026-09-05 11:37:41', '2026-09-10 11:58:16', '2026-09-10 11:58:16', '2026-09-05 11:37:41', '2026-09-10 11:58:16'),
('6', 'TCH-2025-4584', '10', 'Doctorate', 'Ph.D Mathematics', NULL, 'IIT Bombay', '2016', NULL, 'percentage', '10.0', 'National Test Prep', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, '0', NULL, '2026-09-05 11:37:41', NULL, NULL, '2026-09-05 11:37:41', '2026-09-05 11:37:41');

-- --------------------------------------------------------
-- Table structure for `teacher_documents`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `teacher_documents`;
CREATE TABLE `teacher_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `application_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `document_type` enum('identity','qualification','experience','resume','certification') NOT NULL,
  `document_subtype` varchar(64) DEFAULT NULL,
  `document_side` enum('front','back','single') NOT NULL DEFAULT 'single',
  `storage_key` varchar(255) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `mime_type` varchar(64) NOT NULL,
  `file_size` int(11) NOT NULL,
  `checksum` char(64) DEFAULT NULL,
  `verification_status` enum('pending','verified','invalid','unclear','reupload_required') NOT NULL DEFAULT 'pending',
  `reviewer_id` int(11) DEFAULT NULL,
  `reviewer_note` text DEFAULT NULL,
  `replaced_document_id` int(11) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `verified_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_td_app` (`application_id`),
  KEY `idx_td_user` (`user_id`),
  KEY `idx_td_status` (`verification_status`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `teacher_documents`
INSERT INTO `teacher_documents` (`id`, `application_id`, `user_id`, `document_type`, `document_subtype`, `document_side`, `storage_key`, `original_name`, `mime_type`, `file_size`, `checksum`, `verification_status`, `reviewer_id`, `reviewer_note`, `replaced_document_id`, `uploaded_at`, `verified_at`) VALUES
('3', '4', '8', 'identity', NULL, 'single', 'storage/teacher_docs/mock_pan.jpg', 'pan_card.jpg', 'image/jpeg', '524288', NULL, 'verified', '1', NULL, NULL, '2026-09-05 11:37:41', '2026-09-10 11:56:59'),
('4', '5', '9', 'identity', NULL, 'single', 'storage/teacher_docs/mock_pass.pdf', 'passport.pdf', 'application/pdf', '838860', NULL, 'verified', NULL, NULL, NULL, '2026-09-05 11:37:41', NULL),
('5', '6', '10', 'identity', NULL, 'single', 'storage/teacher_docs/mock_aadhaar.pdf', 'aadhaar.pdf', 'application/pdf', '1048576', NULL, 'verified', NULL, NULL, NULL, '2026-09-05 11:37:41', NULL);

-- --------------------------------------------------------
-- Table structure for `teacher_profiles`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `teacher_profiles`;
CREATE TABLE `teacher_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `display_name` varchar(150) NOT NULL,
  `qualification` varchar(255) DEFAULT NULL,
  `specialisation` varchar(255) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `questions_submitted` int(11) NOT NULL DEFAULT 0,
  `questions_approved` int(11) NOT NULL DEFAULT 0,
  `questions_rejected` int(11) NOT NULL DEFAULT 0,
  `status` enum('active','suspended') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `teacher_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `teacher_profiles`
INSERT INTO `teacher_profiles` (`id`, `user_id`, `display_name`, `qualification`, `specialisation`, `bio`, `questions_submitted`, `questions_approved`, `questions_rejected`, `status`, `created_at`) VALUES
('1', '10', 'Dr. Rahul Gupta', 'Ph.D Mathematics', 'Higher Algebra & Calculus', NULL, '0', '0', '0', 'active', '2026-09-05 11:37:41'),
('2', '7', 'Neha Sharma', 'M.Sc Physics, B.Ed', 'Physics & Quantitative Aptitude', 'Post Graduate in M.Sc Physics (Delhi University)', '0', '0', '0', 'active', '2026-09-09 12:11:10'),
('3', '8', '', NULL, NULL, 'Graduate in B.Tech Mechanical (IIT Delhi)', '0', '0', '0', 'active', '2026-09-10 11:56:59'),
('4', '9', '', NULL, NULL, 'Post Graduate in M.A History (Jawaharlal Nehru University)', '0', '0', '0', 'active', '2026-09-10 11:58:16'),
('6', '40', 'Prof. Sharma', 'M.Sc Mathematics, B.Ed', 'Quantitative Aptitude', NULL, '0', '0', '0', 'active', '2026-09-10 14:48:05');

-- --------------------------------------------------------
-- Table structure for `test_attempts`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `test_attempts`;
CREATE TABLE `test_attempts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `test_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `pattern_version` int(11) DEFAULT 1,
  `assembly_mode` enum('fixed','randomised') DEFAULT 'fixed',
  `status` enum('in_progress','submitted','evaluated') DEFAULT 'in_progress',
  `score` decimal(8,2) DEFAULT 0.00,
  `accuracy_percentage` decimal(5,2) DEFAULT 0.00,
  `total_time_spent_seconds` int(11) DEFAULT 0,
  `correct_count` int(11) DEFAULT 0,
  `wrong_count` int(11) DEFAULT 0,
  `unattempted_count` int(11) DEFAULT 0,
  `central_rank` int(11) DEFAULT NULL,
  `state_rank` int(11) DEFAULT NULL,
  `percentile` decimal(6,2) DEFAULT 0.00,
  `started_at` datetime DEFAULT current_timestamp(),
  `submitted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_attempts_ranking` (`test_id`,`status`,`score`),
  KEY `idx_attempts_user_status` (`user_id`,`status`),
  CONSTRAINT `test_attempts_ibfk_1` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `test_attempts_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `test_attempts`
INSERT INTO `test_attempts` (`id`, `test_id`, `user_id`, `pattern_version`, `assembly_mode`, `status`, `score`, `accuracy_percentage`, `total_time_spent_seconds`, `correct_count`, `wrong_count`, `unattempted_count`, `central_rank`, `state_rank`, `percentile`, `started_at`, `submitted_at`) VALUES
('4', '1', '11', '1', 'fixed', 'evaluated', '142.50', '86.30', '0', '0', '0', '0', NULL, NULL, '0.00', '2026-09-05 11:38:16', '2026-09-05 11:38:16'),
('5', '1', '11', '1', 'fixed', 'in_progress', '0.00', '0.00', '0', '0', '0', '0', NULL, NULL, '0.00', '2026-09-05 12:12:45', NULL),
('6', '1', '7', '1', 'fixed', 'evaluated', '0.00', '0.00', '0', '0', '0', '22', '2', NULL, '0.00', '2026-09-08 13:57:36', '2026-09-08 13:57:36'),
('7', '1', '1', '1', 'fixed', 'evaluated', '-0.50', '0.00', '45', '0', '1', '21', '3', NULL, '0.00', '2026-09-09 12:10:04', '2026-09-09 12:10:04'),
('8', '1', '1', '1', 'fixed', 'evaluated', '-0.50', '0.00', '45', '0', '1', '21', '3', NULL, '33.33', '2026-09-09 12:10:24', '2026-09-09 12:10:24'),
('9', '1', '1', '1', 'fixed', 'evaluated', '-0.50', '0.00', '45', '0', '1', '21', '3', NULL, '50.00', '2026-09-09 12:11:22', '2026-09-09 12:11:22'),
('10', '1', '1', '1', 'fixed', 'evaluated', '6.50', '31.82', '3', '7', '15', '0', '2', NULL, '80.00', '2026-09-09 12:20:24', '2026-09-09 12:40:05'),
('11', '1', '1', '1', 'fixed', 'evaluated', '-0.50', '0.00', '45', '0', '1', '21', '4', NULL, '50.00', '2026-09-09 12:40:30', '2026-09-09 12:57:05'),
('12', '1', '1', '1', 'fixed', 'in_progress', '0.00', '0.00', '0', '0', '0', '0', NULL, NULL, '0.00', '2026-09-09 12:57:36', NULL);

-- --------------------------------------------------------
-- Table structure for `test_questions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `test_questions`;
CREATE TABLE `test_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `test_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `section_id` int(11) DEFAULT NULL,
  `question_order` int(11) NOT NULL,
  `positive_marks` decimal(5,2) DEFAULT 2.00,
  `negative_marks` decimal(5,2) DEFAULT 0.50,
  PRIMARY KEY (`id`),
  KEY `test_id` (`test_id`),
  KEY `question_id` (`question_id`),
  CONSTRAINT `test_questions_ibfk_1` FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`) ON DELETE CASCADE,
  CONSTRAINT `test_questions_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=106 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `test_questions`
INSERT INTO `test_questions` (`id`, `test_id`, `question_id`, `section_id`, `question_order`, `positive_marks`, `negative_marks`) VALUES
('1', '1', '1', '1', '1', '2.00', '0.50'),
('2', '1', '2', '1', '2', '2.00', '0.50'),
('3', '1', '3', '2', '3', '2.00', '0.50'),
('4', '1', '4', '3', '4', '2.00', '0.50'),
('5', '1', '5', '4', '5', '2.00', '0.50'),
('6', '3', '1', '1', '1', '2.00', '0.50'),
('7', '3', '2', '1', '2', '2.00', '0.50'),
('8', '3', '3', '2', '3', '2.00', '0.50'),
('9', '3', '4', '3', '4', '2.00', '0.50'),
('10', '3', '5', '4', '5', '2.00', '0.50'),
('11', '1', '6', NULL, '1', '2.00', '0.50'),
('12', '1', '7', NULL, '2', '2.00', '0.50'),
('13', '1', '8', NULL, '3', '2.00', '0.50'),
('14', '1', '9', NULL, '4', '2.00', '0.50'),
('15', '1', '10', NULL, '5', '2.00', '0.50'),
('16', '1', '11', NULL, '6', '2.00', '0.50'),
('17', '1', '12', NULL, '7', '2.00', '0.50'),
('18', '1', '13', NULL, '8', '2.00', '0.50'),
('19', '1', '14', NULL, '9', '2.00', '0.50'),
('20', '1', '15', NULL, '10', '2.00', '0.50'),
('21', '1', '16', NULL, '11', '2.00', '0.50'),
('22', '1', '17', NULL, '12', '2.00', '0.50'),
('23', '1', '18', NULL, '13', '2.00', '0.50'),
('24', '1', '19', NULL, '14', '2.00', '0.50'),
('25', '1', '20', NULL, '15', '2.00', '0.50'),
('26', '1', '21', NULL, '16', '2.00', '0.50'),
('27', '1', '22', NULL, '17', '2.00', '0.50'),
('28', '2', '6', NULL, '1', '2.00', '0.50'),
('29', '2', '7', NULL, '2', '2.00', '0.50'),
('30', '2', '8', NULL, '3', '2.00', '0.50'),
('31', '2', '9', NULL, '4', '2.00', '0.50'),
('32', '2', '10', NULL, '5', '2.00', '0.50'),
('33', '2', '11', NULL, '6', '2.00', '0.50'),
('34', '2', '12', NULL, '7', '2.00', '0.50'),
('35', '2', '13', NULL, '8', '2.00', '0.50'),
('36', '2', '14', NULL, '9', '2.00', '0.50'),
('37', '2', '15', NULL, '10', '2.00', '0.50'),
('38', '2', '16', NULL, '11', '2.00', '0.50'),
('39', '2', '17', NULL, '12', '2.00', '0.50'),
('40', '2', '18', NULL, '13', '2.00', '0.50'),
('41', '2', '19', NULL, '14', '2.00', '0.50'),
('42', '2', '20', NULL, '15', '2.00', '0.50'),
('43', '2', '21', NULL, '16', '2.00', '0.50'),
('44', '2', '22', NULL, '17', '2.00', '0.50'),
('45', '3', '6', NULL, '1', '2.00', '0.50'),
('46', '3', '7', NULL, '2', '2.00', '0.50'),
('47', '3', '8', NULL, '3', '2.00', '0.50'),
('48', '3', '9', NULL, '4', '2.00', '0.50'),
('49', '3', '10', NULL, '5', '2.00', '0.50'),
('50', '3', '11', NULL, '6', '2.00', '0.50'),
('51', '3', '12', NULL, '7', '2.00', '0.50'),
('52', '3', '13', NULL, '8', '2.00', '0.50'),
('53', '3', '14', NULL, '9', '2.00', '0.50'),
('54', '3', '15', NULL, '10', '2.00', '0.50'),
('55', '3', '16', NULL, '11', '2.00', '0.50'),
('56', '3', '17', NULL, '12', '2.00', '0.50'),
('57', '3', '18', NULL, '13', '2.00', '0.50'),
('58', '3', '19', NULL, '14', '2.00', '0.50'),
('59', '3', '20', NULL, '15', '2.00', '0.50'),
('60', '3', '21', NULL, '16', '2.00', '0.50'),
('61', '3', '22', NULL, '17', '2.00', '0.50'),
('62', '4', '1', NULL, '1', '2.00', '0.50'),
('63', '4', '2', NULL, '2', '2.00', '0.50'),
('64', '4', '3', NULL, '3', '2.00', '0.50'),
('65', '4', '4', NULL, '4', '2.00', '0.50'),
('66', '4', '5', NULL, '5', '2.00', '0.50'),
('67', '4', '6', NULL, '6', '2.00', '0.50'),
('68', '4', '7', NULL, '7', '2.00', '0.50'),
('69', '4', '8', NULL, '8', '2.00', '0.50'),
('70', '4', '9', NULL, '9', '2.00', '0.50'),
('71', '4', '10', NULL, '10', '2.00', '0.50'),
('72', '4', '11', NULL, '11', '2.00', '0.50'),
('73', '4', '12', NULL, '12', '2.00', '0.50'),
('74', '4', '13', NULL, '13', '2.00', '0.50'),
('75', '4', '14', NULL, '14', '2.00', '0.50'),
('76', '4', '15', NULL, '15', '2.00', '0.50'),
('77', '4', '16', NULL, '16', '2.00', '0.50'),
('78', '4', '17', NULL, '17', '2.00', '0.50'),
('79', '4', '18', NULL, '18', '2.00', '0.50'),
('80', '4', '19', NULL, '19', '2.00', '0.50'),
('81', '4', '20', NULL, '20', '2.00', '0.50'),
('82', '4', '21', NULL, '21', '2.00', '0.50'),
('83', '4', '22', NULL, '22', '2.00', '0.50'),
('84', '5', '1', NULL, '1', '2.00', '0.50'),
('85', '5', '2', NULL, '2', '2.00', '0.50'),
('86', '5', '3', NULL, '3', '2.00', '0.50'),
('87', '5', '4', NULL, '4', '2.00', '0.50'),
('88', '5', '5', NULL, '5', '2.00', '0.50'),
('89', '5', '6', NULL, '6', '2.00', '0.50'),
('90', '5', '7', NULL, '7', '2.00', '0.50'),
('91', '5', '8', NULL, '8', '2.00', '0.50'),
('92', '5', '9', NULL, '9', '2.00', '0.50'),
('93', '5', '10', NULL, '10', '2.00', '0.50'),
('94', '5', '11', NULL, '11', '2.00', '0.50'),
('95', '5', '12', NULL, '12', '2.00', '0.50'),
('96', '5', '13', NULL, '13', '2.00', '0.50'),
('97', '5', '14', NULL, '14', '2.00', '0.50'),
('98', '5', '15', NULL, '15', '2.00', '0.50'),
('99', '5', '16', NULL, '16', '2.00', '0.50'),
('100', '5', '17', NULL, '17', '2.00', '0.50'),
('101', '5', '18', NULL, '18', '2.00', '0.50'),
('102', '5', '19', NULL, '19', '2.00', '0.50'),
('103', '5', '20', NULL, '20', '2.00', '0.50'),
('104', '5', '21', NULL, '21', '2.00', '0.50'),
('105', '5', '22', NULL, '22', '2.00', '0.50');

-- --------------------------------------------------------
-- Table structure for `test_versions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `test_versions`;
CREATE TABLE `test_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `test_id` int(11) NOT NULL,
  `version_no` int(11) NOT NULL DEFAULT 1,
  `title` varchar(255) NOT NULL,
  `instructions` text DEFAULT NULL,
  `duration_minutes` int(11) NOT NULL DEFAULT 60,
  `total_marks` decimal(6,2) NOT NULL DEFAULT 100.00,
  `pass_percentage` decimal(5,2) NOT NULL DEFAULT 40.00,
  `negative_marking` decimal(4,2) NOT NULL DEFAULT 0.50,
  `validation_status` enum('draft','valid','invalid','blocked') NOT NULL DEFAULT 'draft',
  `validation_summary` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`validation_summary`)),
  `is_locked` tinyint(1) NOT NULL DEFAULT 0,
  `locked_at` datetime DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_tv_test` (`test_id`),
  KEY `idx_tv_version` (`test_id`,`version_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `tests`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `tests`;
CREATE TABLE `tests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `exam_id` int(11) NOT NULL,
  `pattern_id` int(11) NOT NULL,
  `title` varchar(150) NOT NULL,
  `slug` varchar(150) NOT NULL,
  `test_type` enum('full_mock','sectional','topic','pyq','live','monthly_challenge') DEFAULT 'full_mock',
  `is_paid` tinyint(1) DEFAULT 0,
  `price` decimal(10,2) DEFAULT 0.00,
  `is_randomised` tinyint(1) DEFAULT 0,
  `instructions` longtext DEFAULT NULL,
  `status` enum('draft','scheduled','published','closed') DEFAULT 'published',
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `exam_id` (`exam_id`),
  KEY `pattern_id` (`pattern_id`),
  CONSTRAINT `tests_ibfk_1` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tests_ibfk_2` FOREIGN KEY (`pattern_id`) REFERENCES `exam_patterns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `tests`
INSERT INTO `tests` (`id`, `exam_id`, `pattern_id`, `title`, `slug`, `test_type`, `is_paid`, `price`, `is_randomised`, `instructions`, `status`, `start_time`, `end_time`, `created_at`) VALUES
('1', '1', '1', 'SSC CGL Full Mock Test 01 - All India Benchmark', 'ssc-cgl-full-mock-01', 'full_mock', '0', '0.00', '0', 'This test follows the official SSC CGL Tier 1 pattern (100 Questions, 200 Marks, 60 Minutes). Each correct answer awards +2 marks, and each wrong answer incurs a penalty of -0.50 marks.', 'published', NULL, NULL, '2026-08-21 14:22:31'),
('2', '1', '1', 'SSC CGL Sectional - Quant Special', 'ssc-cgl-sectional-quant', 'sectional', '0', '0.00', '0', 'Test your Quantitative Aptitude speed and accuracy under real exam timer pressure.', 'published', NULL, NULL, '2026-08-21 14:22:31'),
('3', '1', '1', 'Monthly All-India National Challenge - August 2026', 'national-challenge-august-2026', 'monthly_challenge', '0', '0.00', '0', 'Compete against candidates nationwide for All-India Central Rank and State-wise Rank. Results include AI twin readiness analysis.', 'published', NULL, NULL, '2026-08-21 14:22:31'),
('4', '1', '1', 'test exam', 'test-exam-1788172372', 'full_mock', '0', '0.00', '0', 'Standard exam rules apply: +2.00 marks for correct answers, -0.50 marks for wrong answers.', 'published', NULL, NULL, '2026-08-31 16:02:52'),
('5', '1', '1', 'fff', 'fff-1788172556', 'full_mock', '0', '0.00', '0', 'Standard exam rules apply: +2.00 marks for correct answers, -0.50 marks for wrong answers.', 'published', NULL, NULL, '2026-08-31 16:05:56');

-- --------------------------------------------------------
-- Table structure for `topics`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `topics`;
CREATE TABLE `topics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `chapter_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `chapter_id` (`chapter_id`),
  CONSTRAINT `topics_ibfk_1` FOREIGN KEY (`chapter_id`) REFERENCES `chapters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `topics`
INSERT INTO `topics` (`id`, `chapter_id`, `name`) VALUES
('1', '1', 'Basic Percentage Calculations'),
('2', '1', 'Successive Percentage & Population'),
('3', '2', 'Discounts & Marked Price'),
('4', '3', 'Letter-Number Coding'),
('5', '5', 'Subject-Verb Agreement'),
('6', '6', 'Fundamental Rights & Duties');

-- --------------------------------------------------------
-- Table structure for `topper_stories`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `topper_stories`;
CREATE TABLE `topper_stories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `student_name` varchar(150) NOT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `exam_name` varchar(150) NOT NULL,
  `year` int(11) NOT NULL,
  `verified_rank` int(11) NOT NULL,
  `best_mock_rank` int(11) NOT NULL,
  `story_text` text NOT NULL,
  `is_verified` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `topper_stories`
INSERT INTO `topper_stories` (`id`, `student_name`, `photo_url`, `exam_name`, `year`, `verified_rank`, `best_mock_rank`, `story_text`, `is_verified`, `created_at`) VALUES
('1', 'Rahul Sharma', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', 'SSC CGL', '2025', '4', '2', 'Consistent mock practice on ExamVerse helped me identify time pressure traps and improve accuracy from 72% to 94%.', '1', '2026-08-21 14:22:31');

-- --------------------------------------------------------
-- Table structure for `user_bookmarks`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_bookmarks`;
CREATE TABLE `user_bookmarks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `item_type` enum('question','article','material','test') NOT NULL DEFAULT 'question',
  `item_id` int(11) NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_item_bookmark` (`user_id`,`item_type`,`item_id`),
  CONSTRAINT `user_bookmarks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `user_contacts`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_contacts`;
CREATE TABLE `user_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `contact_phone_hash` varchar(64) NOT NULL,
  `matched_user_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_contact_hash` (`user_id`,`contact_phone_hash`),
  KEY `matched_user_id` (`matched_user_id`),
  CONSTRAINT `user_contacts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_contacts_ibfk_2` FOREIGN KEY (`matched_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `user_notifications`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_notifications`;
CREATE TABLE `user_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(64) DEFAULT 'general',
  `action_url` varchar(255) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `user_notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `user_notifications`
INSERT INTO `user_notifications` (`id`, `user_id`, `title`, `message`, `type`, `action_url`, `is_read`, `created_at`) VALUES
('6', '12', '🎁 30 Days Free Premium Unlocked!', 'Welcome to EXAMVERSE! Your 30-day free premium access has been activated.', 'referral_reward', NULL, '0', '2026-09-09 10:44:38'),
('7', '11', '🎉 Referral Bonus Earned!', 'Your friend completed their first test! 7 days have been added to your premium pass.', 'referral_reward', NULL, '0', '2026-09-09 10:44:38'),
('8', '11', '🎁 30 Days Free Premium Unlocked!', 'Welcome to EXAMVERSE! Your 30-day free premium access has been activated.', 'referral_reward', NULL, '0', '2026-09-09 11:44:18'),
('9', '1', '🎉 Referral Bonus Earned!', 'Your friend completed their first test! 7 days have been added to your premium pass.', 'referral_reward', NULL, '0', '2026-09-09 11:44:18'),
('10', '39', '🎁 30 Days Free Premium Unlocked!', 'Welcome to EXAMVERSE! Your 30-day free premium access has been activated.', 'referral_reward', NULL, '0', '2026-09-10 10:52:23'),
('11', '38', '🎉 Referral Bonus Earned!', 'Your friend completed their first test! 7 days have been added to your premium pass.', 'referral_reward', NULL, '0', '2026-09-10 10:52:23'),
('12', '39', '🌟 Pro Membership Updated', 'Your ExamVerse membership has been extended by 90 days. Valid until 08 Jan 2027.', 'subscription', NULL, '0', '2026-09-10 10:52:23'),
('13', '8', '🎉 Congratulations! You are now a Verified Teacher', 'Your teacher verification application has been approved. Teacher Mode is now unlocked in your app profile!', 'teacher_approval', NULL, '0', '2026-09-10 11:56:59'),
('14', '9', '🎉 Congratulations! You are now a Verified Teacher', 'Your teacher verification application has been approved. Teacher Mode is now unlocked in your app profile!', 'teacher_approval', NULL, '0', '2026-09-10 11:58:16'),
('15', '7', '🎉 Congratulations! You are now a Verified Teacher', 'Your teacher verification application has been approved. Teacher Mode is now unlocked in your app profile!', 'teacher_approval', NULL, '0', '2026-09-10 11:59:23');

-- --------------------------------------------------------
-- Table structure for `user_otps`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_otps`;
CREATE TABLE `user_otps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mobile_or_email` varchar(150) NOT NULL,
  `otp_code` varchar(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `is_used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_otp_lookup` (`mobile_or_email`,`is_used`,`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `user_otps`
INSERT INTO `user_otps` (`id`, `mobile_or_email`, `otp_code`, `expires_at`, `is_used`, `created_at`) VALUES
('1', '9876543210', 'b398fb5cb3045393d1551a531fb38b3332733b3604833b2c0599f876caf98dba', '2026-09-08 13:59:43', '1', '2026-09-08 13:49:43'),
('2', '9876543210', '5348166302b6d41bef3f313339aae29c158737bf7c3e34037740a514b3a01517', '2026-09-08 14:01:01', '1', '2026-09-08 13:51:01'),
('3', '9876543210', '67f3dabfbde3e4dc6446c68eab9a13646d574439e04b0cfad69ed389ed7398f2', '2026-09-08 14:03:23', '1', '2026-09-08 13:53:23'),
('4', '9876543210', '87f545c618945f8000b1f6d2141d15db9a5938d35e230c358eff29c0a8892507', '2026-09-09 10:56:07', '0', '2026-09-09 10:46:07');

-- --------------------------------------------------------
-- Table structure for `user_subscriptions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_subscriptions`;
CREATE TABLE `user_subscriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `plan_id` int(11) NOT NULL DEFAULT 1,
  `status` enum('trial','active','expiring','expired','cancelled','suspended') NOT NULL DEFAULT 'active',
  `expiry_date` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_us_user` (`user_id`),
  KEY `idx_us_status` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `user_subscriptions`
INSERT INTO `user_subscriptions` (`id`, `user_id`, `plan_id`, `status`, `expiry_date`, `created_at`, `updated_at`) VALUES
('3', '2', '1', 'active', '2026-11-04 07:09:43', '2026-09-05 10:39:43', '2026-09-05 10:43:08'),
('4', '1', '1', 'active', '2026-09-26 07:09:43', '2026-09-05 10:39:43', '2026-09-09 11:44:18'),
('5', '11', '2', 'active', '2026-11-11 11:37:41', '2026-09-05 11:37:41', '2026-09-09 11:44:18'),
('6', '12', '1', 'active', '2026-10-09 07:14:38', '2026-09-09 10:44:38', '2026-09-09 10:44:38'),
('7', '39', '5', 'active', '2027-01-08 06:22:23', '2026-09-10 10:52:23', '2026-09-10 10:52:23'),
('8', '38', '1', 'active', '2026-09-17 07:22:23', '2026-09-10 10:52:23', '2026-09-10 10:52:23');

-- --------------------------------------------------------
-- Table structure for `user_target_exams`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_target_exams`;
CREATE TABLE `user_target_exams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `target_year` int(11) DEFAULT 2026,
  `is_primary` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_exam_target` (`user_id`,`exam_id`),
  KEY `exam_id` (`exam_id`),
  CONSTRAINT `user_target_exams_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_target_exams_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `user_weak_topics`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_weak_topics`;
CREATE TABLE `user_weak_topics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `topic_id` int(11) NOT NULL,
  `accuracy` decimal(5,2) DEFAULT 0.00,
  `attempted_count` int(11) DEFAULT 0,
  `last_practiced_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_topic_unique` (`user_id`,`topic_id`),
  CONSTRAINT `user_weak_topics_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
-- Table structure for `user_wrong_questions`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_wrong_questions`;
CREATE TABLE `user_wrong_questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `attempt_id` int(11) NOT NULL,
  `user_selected_key` varchar(10) DEFAULT NULL,
  `correct_key` varchar(10) NOT NULL,
  `review_status` enum('unreviewed','mastered','needs_practice') DEFAULT 'unreviewed',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_attempt_q` (`user_id`,`attempt_id`,`question_id`),
  KEY `question_id` (`question_id`),
  KEY `attempt_id` (`attempt_id`),
  CONSTRAINT `user_wrong_questions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_wrong_questions_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_wrong_questions_ibfk_3` FOREIGN KEY (`attempt_id`) REFERENCES `test_attempts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `user_wrong_questions`
INSERT INTO `user_wrong_questions` (`id`, `user_id`, `question_id`, `attempt_id`, `user_selected_key`, `correct_key`, `review_status`, `created_at`) VALUES
('30', '1', '1', '7', 'A', 'B', 'unreviewed', '2026-09-09 12:10:04'),
('31', '1', '1', '8', 'A', 'B', 'unreviewed', '2026-09-09 12:10:24'),
('32', '1', '1', '9', 'A', 'B', 'unreviewed', '2026-09-09 12:11:22'),
('33', '1', '2', '10', 'C', 'B', 'unreviewed', '2026-09-09 12:40:05'),
('34', '1', '3', '10', 'C', 'A', 'unreviewed', '2026-09-09 12:40:05'),
('35', '1', '4', '10', 'B', 'C', 'unreviewed', '2026-09-09 12:40:05'),
('36', '1', '5', '10', 'C', 'A', 'unreviewed', '2026-09-09 12:40:05'),
('37', '1', '6', '10', 'B', 'D', 'unreviewed', '2026-09-09 12:40:05'),
('38', '1', '7', '10', 'D', 'B', 'unreviewed', '2026-09-09 12:40:05'),
('39', '1', '9', '10', 'D', 'B', 'unreviewed', '2026-09-09 12:40:05'),
('40', '1', '10', '10', 'B', 'C', 'unreviewed', '2026-09-09 12:40:05'),
('41', '1', '11', '10', 'A', 'B', 'unreviewed', '2026-09-09 12:40:05'),
('42', '1', '12', '10', 'C', 'A', 'unreviewed', '2026-09-09 12:40:05'),
('43', '1', '15', '10', 'B', 'D', 'unreviewed', '2026-09-09 12:40:05'),
('44', '1', '18', '10', 'B', 'C', 'unreviewed', '2026-09-09 12:40:05'),
('45', '1', '19', '10', 'C', 'B', 'unreviewed', '2026-09-09 12:40:05'),
('46', '1', '20', '10', 'D', 'B', 'unreviewed', '2026-09-09 12:40:05'),
('47', '1', '21', '10', 'B', 'A', 'unreviewed', '2026-09-09 12:40:05'),
('48', '1', '1', '11', 'A', 'B', 'unreviewed', '2026-09-09 12:57:05');

-- --------------------------------------------------------
-- Table structure for `users`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(150) NOT NULL,
  `mobile` varchar(20) NOT NULL,
  `mobile_hash` char(64) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `state_id` int(11) DEFAULT NULL,
  `qualification_id` int(11) DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT 0,
  `status` enum('active','suspended','pending') DEFAULT 'active',
  `user_type` enum('student','creator','teacher') NOT NULL DEFAULT 'student',
  `avatar_url` varchar(255) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `mobile` (`mobile`),
  KEY `state_id` (`state_id`),
  KEY `qualification_id` (`qualification_id`),
  KEY `idx_users_mobile_hash` (`mobile_hash`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`) ON DELETE SET NULL,
  CONSTRAINT `users_ibfk_2` FOREIGN KEY (`qualification_id`) REFERENCES `qualifications` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `users`
INSERT INTO `users` (`id`, `full_name`, `email`, `mobile`, `mobile_hash`, `password_hash`, `state_id`, `qualification_id`, `is_verified`, `status`, `user_type`, `avatar_url`, `bio`, `created_at`, `updated_at`) VALUES
('1', 'Demo Student', 'demo@examverse.com', '9876543200', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-09 11:10:42', '2026-09-10 14:48:05'),
('7', 'Neha Sharma', 'neha.sharma@example.com', '9876543210', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'teacher', NULL, NULL, '2026-09-05 11:36:52', '2026-09-10 14:48:05'),
('8', 'Amit Verma', 'amit.verma@example.com', '9876543211', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'teacher', NULL, NULL, '2026-09-05 11:36:52', '2026-09-10 14:48:05'),
('9', 'Priya Nair', 'priya.nair@example.com', '9876543212', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'teacher', NULL, NULL, '2026-09-05 11:36:52', '2026-09-10 14:48:05'),
('10', 'Rahul Gupta', 'rahul.gupta@example.com', '9876543213', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'teacher', NULL, NULL, '2026-09-05 11:36:52', '2026-09-10 14:48:05'),
('11', 'Arjun Patel', 'arjun.patel@example.com', '9876543214', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-05 11:36:52', '2026-09-10 14:48:05'),
('12', 'Riya Sharma', 'riya.sharma@example.com', '9876543215', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-05 11:36:52', '2026-09-10 14:48:05'),
('13', 'Karan Verma', 'karan.verma@example.com', '9876543216', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-05 11:36:52', '2026-09-10 14:48:05'),
('35', 'Test User', 'testuser_1788855583@example.com', '9922705357', '15df223712faaa64391e2daf1d2368e52b9012f6d3097269d875415959f98b22', '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'suspended', 'student', NULL, NULL, '2026-09-08 13:49:43', '2026-09-10 14:48:05'),
('36', 'Test User', 'testuser_1788855661@example.com', '9690386679', '14f2327d8efd1ff95d06ad663f681be1c2fd1a6e51d6137622df5717b0a3c72d', '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-08 13:51:01', '2026-09-10 14:48:05'),
('37', 'Test User', 'testuser_1788930967@example.com', '9121745199', 'e0dad81d1731ad34861c8578cda4b664fca839a1355c5384be9db3c72c3698eb', '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-09 10:46:07', '2026-09-10 14:48:05'),
('38', 'Referrer Test User', 'referrer_test@examverse.com', '9999000001', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-10 10:52:23', '2026-09-10 14:48:05'),
('39', 'Referred Student', 'referred_student@examverse.com', '9999000002', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'student', NULL, NULL, '2026-09-10 10:52:23', '2026-09-10 14:48:05'),
('40', 'Faculty Teacher', 'teacher@examverse.com', '9876543299', NULL, '$2y$10$64OyRWj63NopuK/mgT/w0e1icrmg9vYQQoqWc1WtA.f5GKjX8I/Xa', NULL, NULL, '1', 'active', 'teacher', NULL, NULL, '2026-09-10 14:48:05', '2026-09-10 14:48:05');

-- --------------------------------------------------------
-- Default Super Administrator (admin / Admin@12345678)
-- --------------------------------------------------------
INSERT INTO `admins` (`id`, `username`, `email`, `password_hash`, `full_name`, `role`, `status`) 
VALUES (1, 'admin', 'admin@examverse.com', '$2y$10$ycQ0KGf55zsuo0AuYw/ZVOHUUxM3Ka9ZT.rAfcWM0vTtHRMsX6K4W', 'Super Administrator', 'super_admin', 'active')
ON DUPLICATE KEY UPDATE `password_hash` = VALUES(`password_hash`), `status` = 'active';

SET FOREIGN_KEY_CHECKS = 1;
