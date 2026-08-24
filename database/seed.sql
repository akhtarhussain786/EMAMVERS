-- EXAMVERSE Seed Data (SRD v2.0 Baseline)
USE `examverse_db`;

-- Insert Indian States
INSERT INTO `states` (`code`, `name`) VALUES
('DL', 'Delhi'),
('MH', 'Maharashtra'),
('UP', 'Uttar Pradesh'),
('BR', 'Bihar'),
('RJ', 'Rajasthan'),
('MP', 'Madhya Pradesh'),
('WB', 'West Bengal'),
('TN', 'Tamil Nadu'),
('KA', 'Karnataka'),
('GJ', 'Gujarat')
ON DUPLICATE KEY UPDATE `name`=`name`;

-- Insert Qualifications
INSERT INTO `qualifications` (`code`, `name`) VALUES
('10TH', '10th Pass (Matriculation)'),
('12TH', '12th Pass (Intermediate / Senior Secondary)'),
('GRAD', 'Graduation / Bachelor Degree'),
('POSTGRAD', 'Post Graduation / Master Degree'),
('ENGG', 'B.Tech / B.E. (Engineering)'),
('MED', 'MBBS / Medical')
ON DUPLICATE KEY UPDATE `name`=`name`;

-- Insert Exam Categories
INSERT INTO `exam_categories` (`name`, `slug`, `type`, `description`, `sort_order`) VALUES
('Government Exams', 'govt-exams', 'government', 'SSC, UPSC, Banking, Railways, Defence, State Exams', 1),
('Entrance Examinations', 'entrance-exams', 'entrance', 'JEE Main/Advanced, NEET UG, CUET, GATE, CAT, CLAT', 2),
('Private Jobs & Placement', 'private-jobs', 'private_job', 'IT Hiring, Aptitude, Coding Tests, Corporate Roles', 3),
('Upskilling & Certifications', 'upskilling', 'upskilling', 'AI Tools, Data Analytics, Full Stack, Digital Marketing', 4),
('10th/12th/Graduation Paths', 'career-paths', 'qualification', 'Qualification-based career pathways and higher studies', 5)
ON DUPLICATE KEY UPDATE `name`=`name`;

-- Insert Organizations
INSERT INTO `organizations` (`name`, `short_name`, `website`) VALUES
('Staff Selection Commission', 'SSC', 'https://ssc.gov.in'),
('Union Public Service Commission', 'UPSC', 'https://upsc.gov.in'),
('Institute of Banking Personnel Selection', 'IBPS', 'https://ibps.in'),
('National Testing Agency', 'NTA', 'https://nta.ac.in'),
('Indian Institutes of Technology', 'IIT', 'https://jeeadv.ac.in');

-- Insert Core Exams
INSERT INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `overview_text`, `syllabus_text`, `status`) VALUES
(1, 1, 'SSC CGL (Combined Graduate Level)', 'ssc-cgl', 'Premier exam for Group B & C posts in Ministries and Departments of Govt of India.', 'SSC CGL comprises Tier 1 (Qualifying) and Tier 2 examination testing Quantitative Aptitude, English, Reasoning, and General Awareness.', 'Maths (Arithmetic + Advanced), English Language & Comprehension, Reasoning & Intelligence, General Knowledge & Current Affairs.', 'active'),
(1, 3, 'IBPS PO (Probationary Officer)', 'ibps-po', 'National competitive exam for Officer cadre roles in Indian Public Sector Banks.', 'IBPS PO tests Prelims and Mains followed by Interview. Focuses on Data Interpretation, Reasoning, Banking Awareness and English.', 'Reasoning Ability, Quantitative Aptitude, English Language, General/Economy/Banking Awareness.', 'active'),
(2, 4, 'JEE Main', 'jee-main', 'National level engineering entrance test for admission to NITs, IIITs and CFTIs.', 'JEE Main consists of Physics, Chemistry and Mathematics testing conceptual speed, accuracy and analytical problem solving.', 'Physics (Mechanics, Electrodynamics, Modern Physics), Chemistry (Organic, Inorganic, Physical), Mathematics (Algebra, Calculus, Coordinate Geometry).', 'active');

-- Insert Subjects
INSERT INTO `subjects` (`name`, `code`) VALUES
('Quantitative Aptitude', 'QUANT'),
('Reasoning & Intelligence', 'REASONING'),
('English Language', 'ENGLISH'),
('General Awareness & GK', 'GA'),
('Physics', 'PHY'),
('Chemistry', 'CHEM'),
('Mathematics', 'MATH');

-- Insert Chapters
INSERT INTO `chapters` (`subject_id`, `name`) VALUES
(1, 'Percentage & Ratio'),
(1, 'Profit & Loss'),
(2, 'Coding-Decoding'),
(2, 'Syllogism'),
(3, 'Grammar & Error Spotting'),
(4, 'Indian Polity & Constitution');

-- Insert Topics
INSERT INTO `topics` (`chapter_id`, `name`) VALUES
(1, 'Basic Percentage Calculations'),
(1, 'Successive Percentage & Population'),
(2, 'Discounts & Marked Price'),
(3, 'Letter-Number Coding'),
(5, 'Subject-Verb Agreement'),
(6, 'Fundamental Rights & Duties');

-- Insert Exam Patterns
INSERT INTO `exam_patterns` (`exam_id`, `name`, `pattern_version`, `timer_mode`, `total_duration_seconds`, `total_questions`, `total_marks`, `default_positive_marks`, `default_negative_marks`, `navigation_policy`, `languages`) VALUES
(1, 'SSC CGL Tier-1 Pattern (60 Mins)', 1, 'TOTAL', 3600, 100, 200.00, 2.00, 0.50, 'FREE', 'en,hi'),
(2, 'IBPS PO Prelims Pattern (60 Mins Sectional)', 1, 'SECTIONAL', 3600, 100, 100.00, 1.00, 0.25, 'SECTION_LOCKED', 'en,hi'),
(3, 'JEE Main NTA Pattern (180 Mins)', 1, 'TOTAL', 10800, 90, 300.00, 4.00, 1.00, 'FREE', 'en,hi');

-- Insert Pattern Sections for SSC CGL Tier 1
INSERT INTO `pattern_sections` (`pattern_id`, `subject_id`, `section_name`, `question_count`, `positive_marks`, `negative_marks`, `sort_order`) VALUES
(1, 1, 'Quantitative Aptitude', 25, 2.00, 0.50, 1),
(1, 2, 'General Intelligence & Reasoning', 25, 2.00, 0.50, 2),
(1, 3, 'English Comprehension', 25, 2.00, 0.50, 3),
(1, 4, 'General Awareness', 25, 2.00, 0.50, 4);

-- Insert Sample Questions in Question Bank
INSERT INTO `questions` (`subject_id`, `chapter_id`, `topic_id`, `question_type`, `difficulty`, `pyq_year`, `pyq_shift`, `status`) VALUES
(1, 1, 1, 'MCQ', 'medium', 2023, 'Shift 1', 'published'),
(1, 2, 3, 'MCQ', 'easy', 2023, 'Shift 2', 'published'),
(2, 3, 4, 'MCQ', 'medium', 2022, 'Shift 1', 'published'),
(3, 5, 5, 'MCQ', 'medium', 2023, 'Shift 3', 'published'),
(4, 6, 6, 'MCQ', 'easy', 2023, 'Shift 1', 'published');

-- Insert Question Translations (English & Hindi)
INSERT INTO `question_translations` (`question_id`, `language`, `question_text`, `solution_text`, `shortcut_text`) VALUES
(1, 'en', 'If 20% of A is equal to 30% of B, then what percentage of B is A?', 'Let 0.20 * A = 0.30 * B. Therefore A/B = 30/20 = 3/2. A = (3/2) * B = 1.5 * B = 150% of B.', 'A/B = 30/20 = 3/2 -> 1.5 -> 150%. Direct Ratio multiplier!'),
(1, 'hi', 'यदि A का 20%, B के 30% के बराबर है, तो A, B का कितना प्रतिशत है?', 'मान लीजिए 0.20 * A = 0.30 * B. इसलिए A/B = 30/20 = 3/2. A = 150% B का।', 'A/B = 3/2 = 1.5 -> 150%। सीधा अनुपात का नियम!'),
(2, 'en', 'A shopkeeper marks an item 40% above cost price and allows a 15% discount. What is his profit percentage?', 'Let CP = 100. Marked Price MP = 140. Discount = 15% of 140 = 21. Selling Price SP = 140 - 21 = 119. Profit = 119 - 100 = 19%.', 'Effective Profit % = x - y - (x*y)/100 = 40 - 15 - (40*15)/100 = 25 - 6 = 19%.'),
(2, 'hi', 'एक दुकानदार वस्तु का मूल्य लागत मूल्य से 40% अधिक अंकित करता है और 15% की छूट देता है। उसका लाभ प्रतिशत क्या है?', 'माना CP = 100, MP = 140. छूट = 140 का 15% = 21. SP = 119. लाभ = 19%.', 'प्रभावशाली लाभ % = 40 - 15 - (40*15)/100 = 19%.'),
(3, 'en', 'In a certain code language, "FLOWER" is written as "EKNVDQ". How is "GARDEN" written in that code?', 'Each letter is moved -1 backward in the alphabet: F-1=E, L-1=K, O-1=N, W-1=V, E-1=D, R-1=Q. For GARDEN: G-1=F, A-1=Z, R-1=Q, D-1=C, E-1=D, N-1=M. Code: FZQCDM.', 'Shift pattern is -1 for all letters.'),
(4, 'en', 'Identify the error in the sentence: "Neither of the two candidates have submitted their documents."', 'Error is in "have submitted". "Neither of" takes a singular verb. The correct verb is "has submitted".', 'Rule: Neither of + Plural Noun + Singular Verb!'),
(5, 'en', 'Which Article of the Constitution of India deals with the Right to Equality?', 'Articles 14 to 18 of the Indian Constitution deal with the Right to Equality. Article 14 guarantees equality before law.', 'Articles 14-18 = Right to Equality.');

-- Insert Options for Questions
INSERT INTO `question_options` (`question_id`, `option_key`, `language`, `option_text`, `is_correct`) VALUES
(1, 'A', 'en', '120%', 0),
(1, 'B', 'en', '150%', 1),
(1, 'C', 'en', '133.33%', 0),
(1, 'D', 'en', '166.66%', 0),

(2, 'A', 'en', '25%', 0),
(2, 'B', 'en', '19%', 1),
(2, 'C', 'en', '20%', 0),
(2, 'D', 'en', '22.5%', 0),

(3, 'A', 'en', 'FZQCDM', 1),
(3, 'B', 'en', 'HBSEFO', 0),
(3, 'C', 'en', 'FYPBDL', 0),
(3, 'D', 'en', 'FZQDEN', 0),

(4, 'A', 'en', 'Neither of', 0),
(4, 'B', 'en', 'the two candidates', 0),
(4, 'C', 'en', 'have submitted', 1),
(4, 'D', 'en', 'their documents', 0),

(5, 'A', 'en', 'Article 14-18', 1),
(5, 'B', 'en', 'Article 19-22', 0),
(5, 'C', 'en', 'Article 23-24', 0),
(5, 'D', 'en', 'Article 25-28', 0);

-- Insert Tests
INSERT INTO `tests` (`exam_id`, `pattern_id`, `title`, `slug`, `test_type`, `is_paid`, `price`, `instructions`, `status`) VALUES
(1, 1, 'SSC CGL Full Mock Test 01 - All India Benchmark', 'ssc-cgl-full-mock-01', 'full_mock', 0, 0.00, 'This test follows the official SSC CGL Tier 1 pattern (100 Questions, 200 Marks, 60 Minutes). Each correct answer awards +2 marks, and each wrong answer incurs a penalty of -0.50 marks.', 'published'),
(1, 1, 'SSC CGL Sectional - Quant Special', 'ssc-cgl-sectional-quant', 'sectional', 0, 0.00, 'Test your Quantitative Aptitude speed and accuracy under real exam timer pressure.', 'published'),
(1, 1, 'Monthly All-India National Challenge - August 2026', 'national-challenge-august-2026', 'monthly_challenge', 0, 0.00, 'Compete against candidates nationwide for All-India Central Rank and State-wise Rank. Results include AI twin readiness analysis.', 'published');

-- Insert Questions into Test 1
INSERT INTO `test_questions` (`test_id`, `question_id`, `section_id`, `question_order`, `positive_marks`, `negative_marks`) VALUES
(1, 1, 1, 1, 2.00, 0.50),
(1, 2, 1, 2, 2.00, 0.50),
(1, 3, 2, 3, 2.00, 0.50),
(1, 4, 3, 4, 2.00, 0.50),
(1, 5, 4, 5, 2.00, 0.50),
(3, 1, 1, 1, 2.00, 0.50),
(3, 2, 1, 2, 2.00, 0.50),
(3, 3, 2, 3, 2.00, 0.50),
(3, 4, 3, 4, 2.00, 0.50),
(3, 5, 4, 5, 2.00, 0.50);

-- Insert Monthly National Challenge Entry
INSERT INTO `monthly_challenges` (`exam_id`, `test_id`, `title`, `month_year`, `start_window`, `end_window`, `status`) VALUES
(1, 3, 'August 2026 National SSC CGL Rank Challenge', 'August 2026', '2026-08-01 00:00:00', '2026-08-31 23:59:59', 'live');

-- Insert Content: Current Affairs, Jobs, Topper Stories
INSERT INTO `current_affairs` (`title`, `category`, `publish_date`, `content_body`) VALUES
('Reserve Bank of India Keeps Repo Rate Unchanged at 6.5%', 'Banking & Economy', '2026-08-20', 'The Monetary Policy Committee (MPC) of the Reserve Bank of India has decided to maintain the repo rate at 6.50% to maintain inflation target alignment.'),
('National Space Day Celebrations Highlight Gaganyaan Progress', 'Science & Tech', '2026-08-21', 'ISRO announces successful test fire of human-rated Vikas engine for upcoming Gaganyaan crewed spaceflight program.');

INSERT INTO `jobs` (`title`, `organization_name`, `job_type`, `total_vacancies`, `eligibility_criteria`, `last_date_to_apply`, `apply_link`) VALUES
('SSC CGL 2026 Notification for 17,727 Vacancies', 'Staff Selection Commission', 'government', 17727, 'Bachelor Degree in any discipline from a recognized University.', '2026-09-15', 'https://ssc.gov.in'),
('IBPS PO XIV Online Application Open', 'Institute of Banking Personnel Selection', 'government', 4455, 'Graduate in any discipline. Age limit 20 to 30 years.', '2026-09-05', 'https://ibps.in');

INSERT INTO `topper_stories` (`student_name`, `photo_url`, `exam_name`, `year`, `verified_rank`, `best_mock_rank`, `story_text`) VALUES
('Rahul Sharma', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb', 'SSC CGL', 2025, 4, 2, 'Consistent mock practice on ExamVerse helped me identify time pressure traps and improve accuracy from 72% to 94%.');

-- Insert Admin User (Username: admin, Password: password123)
-- Hash generated via password_hash('password123', PASSWORD_BCRYPT)
INSERT INTO `admins` (`username`, `email`, `password_hash`, `full_name`, `role`) VALUES
('admin', 'admin@examverse.com', '$2y$10$wE1VfW3uKqYx1W.H8rV8u.Jv9z9y0q/7n1J2X3Y4Z5W6V7U8T9S0R1Q', 'Super Administrator', 'super_admin')
ON DUPLICATE KEY UPDATE `full_name`=`full_name`;

-- Insert Demo Student Candidate User (Email: demo@examverse.com, Password: password123)
INSERT INTO `users` (`full_name`, `email`, `mobile`, `password_hash`, `state_id`, `qualification_id`, `is_verified`, `status`) VALUES
('Aarav Sharma', 'demo@examverse.com', '9876543210', '$2y$10$wE1VfW3uKqYx1W.H8rV8u.Jv9z9y0q/7n1J2X3Y4Z5W6V7U8T9S0R1Q', 1, 3, 1, 'active')
ON DUPLICATE KEY UPDATE `full_name`=`full_name`;
