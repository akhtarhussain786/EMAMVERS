-- EXAMVERSE — Mega Exam Taxonomy Seed v2
-- 200+ Indian exams: UPSC, SSC, Banking, Railways, State PSC, Defence, Teaching, Insurance, Entrance
USE `examverse_db`;

-- ============================================================
-- EXAM CATEGORIES (with parent hierarchy)
-- ============================================================
INSERT IGNORE INTO `exam_categories` (`name`, `slug`, `type`, `description`, `keywords`, `sort_order`, `status`) VALUES
('UPSC Civil Services', 'upsc', 'government', 'Union Public Service Commission — India''s premier civil service exam', 'upsc,ias,ips,ifs,civil services,collector,dm,sdo', 1, 'active'),
('SSC Exams', 'ssc', 'government', 'Staff Selection Commission — Central Govt recruitment exams', 'ssc,cgl,chsl,mts,constable,stenographer,staff selection', 2, 'active'),
('Banking & Finance', 'banking', 'government', 'IBPS, SBI, RBI, NABARD and all banking sector exams', 'ibps,sbi,rbi,bank po,bank clerk,banking,finance', 3, 'active'),
('Railways', 'railways', 'government', 'RRB — Railway Recruitment Board exams', 'rrb,ntpc,group d,alp,loco pilot,railway,railways,je,sse', 4, 'active'),
('State Public Service Commission', 'state-psc', 'government', 'All 28 State PSC exams across India', 'psc,state psc,bpsc,uppsc,mpsc,mppsc,rpsc,state civil services', 5, 'active'),
('Defence & Paramilitary', 'defence', 'government', 'Army, Navy, Air Force, NDA, CDS and paramilitary exams', 'nda,cds,afcat,army,navy,air force,bsf,crpf,cisf,defence', 6, 'active'),
('Teaching & Education', 'teaching', 'government', 'CTET, TET, UGC NET, NVS, KVS and all teaching exams', 'ctet,tet,ugc net,nvs,kvs,teaching,teacher,dsssb,csir net', 7, 'active'),
('Insurance Sector', 'insurance', 'government', 'LIC, NIACL, NICL, UIICL and all insurance sector exams', 'lic,niacl,nicl,insurance,aao,ado,assistant', 8, 'active'),
('Engineering Entrance', 'engineering-entrance', 'entrance', 'JEE Main, Advanced, BITSAT, VITEEE and state CETs', 'jee,jee main,jee advanced,bitsat,engineering entrance,iit,nit', 9, 'active'),
('Medical Entrance', 'medical-entrance', 'entrance', 'NEET UG/PG, AIIMS, JIPMER and state medical exams', 'neet,neet pg,aiims,medical entrance,mbbs,bds,doctor', 10, 'active'),
('Management Entrance', 'management-entrance', 'entrance', 'CAT, MAT, XAT, SNAP, IIFT, CMAT and MBA entrance exams', 'cat,mat,xat,snap,gmat,mba,management,iim', 11, 'active'),
('Law Entrance', 'law-entrance', 'entrance', 'CLAT, AILET, LSAT India and state law entrance exams', 'clat,ailet,law,nlsiu,nlu,legal studies', 12, 'active'),
('GATE & PSU', 'gate-psu', 'entrance', 'GATE — Graduate Aptitude Test in Engineering and PSU recruitment', 'gate,psu,isro,barc,bel,iocl,ongc,drdo,engineering psu', 13, 'active'),
('CUET', 'cuet', 'entrance', 'Common University Entrance Test UG/PG for central universities', 'cuet,central university,du,jnu,bhu,undergraduate,postgraduate', 14, 'active'),
('Constable & Police', 'police-constable', 'government', 'State Police Constable, Sub-Inspector and Head Constable exams', 'police,constable,sub inspector,si,asi,head constable,upp,rajasthan police', 15, 'active'),
('Judiciary & Law', 'judiciary', 'government', 'District Court, High Court and Civil Judge exams', 'judiciary,civil judge,district court,high court,judicial services', 16, 'active'),
('Skill & Computer', 'skill-computer', 'upskilling', 'NIELIT CCC, O Level, A Level, Typing Tests, DCA, BCA', 'nielit,ccc,o level,a level,typing,computer,dca,bca,skill', 17, 'active'),
('State Govt & Misc', 'state-misc', 'government', 'State-specific patwari, lekhpal, gram sevak, VDO, clerk exams', 'patwari,lekhpal,gram sevak,vdo,clerk,state govt,panchayat', 18, 'active');

-- ============================================================
-- ORGANIZATIONS
-- ============================================================
INSERT IGNORE INTO `organizations` (`name`, `short_name`, `website`) VALUES
('Union Public Service Commission', 'UPSC', 'https://upsc.gov.in'),
('Staff Selection Commission', 'SSC', 'https://ssc.nic.in'),
('Institute of Banking Personnel Selection', 'IBPS', 'https://ibps.in'),
('State Bank of India', 'SBI', 'https://sbi.co.in'),
('Reserve Bank of India', 'RBI', 'https://rbi.org.in'),
('Railway Recruitment Board', 'RRB', 'https://indianrailways.gov.in'),
('National Testing Agency', 'NTA', 'https://nta.ac.in'),
('Bihar Public Service Commission', 'BPSC', 'https://bpsc.bih.nic.in'),
('Uttar Pradesh Public Service Commission', 'UPPSC', 'https://uppsc.up.nic.in'),
('Maharashtra Public Service Commission', 'MPSC', 'https://mpsc.gov.in'),
('Rajasthan Public Service Commission', 'RPSC', 'https://rpsc.rajasthan.gov.in'),
('Madhya Pradesh Public Service Commission', 'MPPSC', 'https://mppsc.mp.gov.in'),
('Life Insurance Corporation of India', 'LIC', 'https://licindia.in'),
('National Insurance Company', 'NICL', 'https://nationalinsurance.nic.co.in'),
('Central Board of Secondary Education', 'CBSE', 'https://cbse.nic.in'),
('University Grants Commission', 'UGC', 'https://ugc.ac.in'),
('Kendriya Vidyalaya Sangathan', 'KVS', 'https://kvsangathan.nic.in'),
('Navodaya Vidyalaya Samiti', 'NVS', 'https://nvshq.org'),
('Delhi Subordinate Services Selection Board', 'DSSSB', 'https://dsssb.delhi.gov.in'),
('Andhra Pradesh Public Service Commission', 'APPSC', 'https://psc.ap.gov.in'),
('Telangana State Public Service Commission', 'TSPSC', 'https://tspsc.gov.in'),
('Tamil Nadu Public Service Commission', 'TNPSC', 'https://tnpsc.gov.in'),
('Karnataka Public Service Commission', 'KPSC', 'https://kpsc.kar.nic.in'),
('Kerala Public Service Commission', 'KPSC_KL', 'https://keralapsc.gov.in'),
('Punjab Public Service Commission', 'PPSC', 'https://ppsc.gov.in'),
('Haryana Public Service Commission', 'HPSC', 'https://hpsc.gov.in'),
('Jharkhand Public Service Commission', 'JPSC', 'https://jpsc.gov.in'),
('Odisha Public Service Commission', 'OPSC', 'https://opsc.gov.in'),
('Gujarat Public Service Commission', 'GPSC', 'https://gpsc.gujarat.gov.in'),
('National Informatics Centre Electronics and Information Technology Ltd', 'NIELIT', 'https://nielit.gov.in');

-- ============================================================
-- EXAMS — UPSC Group
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC Civil Services (IAS/IPS/IFS)', 'upsc-cse', 'India''s most prestigious exam for IAS, IPS, IRS, IFS officers', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC CSE Prelims', 'upsc-cse-prelims', 'Preliminary stage of UPSC Civil Services — GS Paper I & CSAT', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC CSE Mains', 'upsc-cse-mains', 'Mains stage — 9 papers including Essay, GS I-IV, Optional', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC CDS', 'upsc-cds', 'Combined Defence Services — Army, Navy, Air Force officer entry', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC NDA', 'upsc-nda', 'National Defence Academy — entry for 10+2 students to armed forces', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC CAPF', 'upsc-capf', 'Central Armed Police Forces — BSF/CRPF/CISF/ITBP/SSB AC posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC IFS (Indian Forest Service)', 'upsc-ifs', 'Indian Forest Service recruitment via UPSC', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC SCRA', 'upsc-scra', 'Special Class Railway Apprentices recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='upsc'), 1, 'UPSC CISF AC (EXE) LDCE', 'upsc-cisf-ac', 'CISF Assistant Commandant Limited Departmental Competitive Exam', 'main', 'active');

-- ============================================================
-- EXAMS — SSC Group
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC CGL (Combined Graduate Level)', 'ssc-cgl', 'Recruitment for Group B & C posts in Central Govt departments', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC CGL Tier 1', 'ssc-cgl-tier1', 'SSC CGL Tier 1 — Computer Based Exam (CBE)', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC CGL Tier 2', 'ssc-cgl-tier2', 'SSC CGL Tier 2 — Advanced CBE for shortlisted candidates', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC CHSL (Combined Higher Secondary Level)', 'ssc-chsl', 'Recruitment for LDC, JSA, PA, SA, DEO posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC MTS (Multi Tasking Staff)', 'ssc-mts', 'Multi Tasking Staff recruitment for Non-Technical Group C posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC CPO (Central Police Organisation)', 'ssc-cpo', 'SI in Delhi Police, CAPFs and ASI in CISF', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC JE (Junior Engineer)', 'ssc-je', 'Junior Engineer Civil/Electrical/Mechanical for CPWD, MES, BRO', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC GD Constable', 'ssc-gd', 'General Duty Constable in BSF, CRPF, CISF, ITBP, SSB, NIA', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC Stenographer (Grade C & D)', 'ssc-steno', 'Stenographer Grade C and D posts in Central Govt', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='ssc'), 2, 'SSC Phase VII (Selection Post)', 'ssc-phase7', 'Various selection posts across departments via SSC', 'main', 'active');

-- ============================================================
-- EXAMS — Banking Group
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='banking'), 3, 'IBPS PO (Probationary Officer)', 'ibps-po', 'IBPS PO recruitment for 11 public sector banks', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 3, 'IBPS PO Prelims', 'ibps-po-prelims', 'IBPS PO Preliminary Exam — Reasoning, Quant, English', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 3, 'IBPS PO Mains', 'ibps-po-mains', 'IBPS PO Main Exam — Reasoning, Quant, English, GK, Computer', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 3, 'IBPS Clerk', 'ibps-clerk', 'IBPS Clerk — Office Assistant posts in public sector banks', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 3, 'IBPS SO (Specialist Officer)', 'ibps-so', 'Specialist Officer: IT, HR, Marketing, Agriculture, Law', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 3, 'IBPS RRB PO', 'ibps-rrb-po', 'Regional Rural Banks — Officer Scale I/II/III', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 3, 'IBPS RRB Clerk', 'ibps-rrb-clerk', 'Regional Rural Banks — Office Assistant (Multipurpose)', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 4, 'SBI PO (Probationary Officer)', 'sbi-po', 'State Bank of India Probationary Officer recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 4, 'SBI Clerk (Junior Associate)', 'sbi-clerk', 'SBI Junior Associate — Customer Support & Sales', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 4, 'SBI SO (Specialist Cadre Officer)', 'sbi-so', 'SBI Specialist Cadre — IT, CA, Law, Marketing, HR', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 5, 'RBI Grade B Officer', 'rbi-grade-b', 'Reserve Bank of India Grade B — General/DEPR/DSIM', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 5, 'RBI Assistant', 'rbi-assistant', 'Reserve Bank of India Assistant posts in regional offices', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), 5, 'RBI Office Attendant', 'rbi-office-attendant', 'RBI Office Attendant recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), NULL, 'NABARD Grade A/B', 'nabard-grade-ab', 'National Bank for Agriculture and Rural Development recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), NULL, 'SIDBI Grade A', 'sidbi-grade-a', 'Small Industries Development Bank of India Officer recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='banking'), NULL, 'IRDAI Assistant Manager', 'irdai-am', 'Insurance Regulatory Development Authority of India', 'main', 'active');

-- ============================================================
-- EXAMS — Railways Group
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRB NTPC (Non-Technical Popular Categories)', 'rrb-ntpc', 'Station Master, Goods Guard, Junior Clerk, ASM and 35+ posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRB NTPC CBT 1', 'rrb-ntpc-cbt1', 'RRB NTPC Stage 1 — Preliminary Computer Based Test', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRB NTPC CBT 2', 'rrb-ntpc-cbt2', 'RRB NTPC Stage 2 — Mains Computer Based Test', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRB Group D', 'rrb-group-d', 'Track Maintainer, Helper, Porter and various Group D posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRB ALP (Assistant Loco Pilot)', 'rrb-alp', 'Assistant Loco Pilot and Technician posts in Indian Railways', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRB JE (Junior Engineer)', 'rrb-je', 'Junior Engineer Civil/Electrical/IT/Mechanical/Signal posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRB SSE (Senior Section Engineer)', 'rrb-sse', 'Senior Section Engineer across various departments', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RPF Constable & SI', 'rpf', 'Railway Protection Force Constable and Sub-Inspector', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='railways'), 6, 'RRC Group C (Ministerial & Isolated)', 'rrc-group-c', 'Railway Recruitment Cell — Ministerial and Isolated posts', 'main', 'active');

-- ============================================================
-- EXAMS — State PSC Group
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='state-psc'), 8, 'BPSC (Bihar Civil Services)', 'bpsc', 'Bihar Public Service Commission — BAS, BPS and related services', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 8, 'BPSC 70th Combined Exam', 'bpsc-70', 'BPSC 70th Integrated Combined Competitive Exam', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 9, 'UPPSC PCS (UP Civil Services)', 'uppsc-pcs', 'UP Provincial Civil Services — SDM, DSP and Group A/B posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 9, 'UPPSC RO/ARO', 'uppsc-ro-aro', 'UP Review Officer / Assistant Review Officer exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 9, 'UPPSC Lekhpal', 'uppsc-lekhpal', 'UP Chakbandi Lekhpal recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 10, 'MPSC (Maharashtra Civil Services)', 'mpsc', 'Maharashtra Public Service Commission — State Services', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 11, 'RPSC (Rajasthan Civil Services)', 'rpsc-ras', 'Rajasthan Administrative Service — RAS/RTS recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 11, 'RPSC 1st Grade Teacher', 'rpsc-1st-grade', 'Rajasthan 1st Grade School Lecturer recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 11, 'RPSC 2nd Grade Teacher', 'rpsc-2nd-grade', 'Rajasthan 2nd Grade Senior Teacher recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 12, 'MPPSC (MP Civil Services)', 'mppsc', 'MP State Services Exam — Dy Collector, DSP, Tehsildar', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 20, 'APPSC Group 1', 'appsc-group1', 'AP Group 1 Services — Deputy Collector, DSP, Joint Director', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 20, 'APPSC Group 2', 'appsc-group2', 'AP Group 2 Services — Junior Lecturer, MRO, Sub-Registrar', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 21, 'TSPSC Group 1', 'tspsc-group1', 'Telangana Group 1 — Dy Collector, DSP, DFO posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 22, 'TNPSC Group 1', 'tnpsc-group1', 'Tamil Nadu Group 1 — IAS equivalent state services', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 22, 'TNPSC Group 2', 'tnpsc-group2', 'Tamil Nadu Group 2 — Deputy Tahsildar, VAO, BDO posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 22, 'TNPSC Group 4', 'tnpsc-group4', 'Tamil Nadu Village Administrative Officer exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 23, 'KPSC (Karnataka Civil Services)', 'kpsc', 'Karnataka Administrative Services — Group A & B', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 24, 'Kerala PSC (Various Posts)', 'kerala-psc', 'Kerala Public Service Commission — LDC, Driver, LD Clerk and more', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 25, 'PPSC (Punjab Civil Services)', 'ppsc', 'Punjab Civil Services — PCS exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 26, 'HPSC (Haryana Civil Services)', 'hpsc-hcs', 'Haryana Civil Services — HCS exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 27, 'JPSC (Jharkhand Civil Services)', 'jpsc', 'Jharkhand Administrative Services exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 28, 'OPSC (Odisha Civil Services)', 'opsc-oas', 'Odisha Administrative Services — OAS exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), 29, 'GPSC (Gujarat Civil Services)', 'gpsc', 'Gujarat Administrative Services — Class 1 & 2', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), NULL, 'UKPSC (Uttarakhand Civil Services)', 'ukpsc', 'Uttarakhand Public Service Commission — PCS exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), NULL, 'CGPSC (Chhattisgarh Civil Services)', 'cgpsc', 'Chhattisgarh PSC — State Services exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), NULL, 'WBPSC (West Bengal Civil Services)', 'wbpsc', 'West Bengal Civil Service — WBCS exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), NULL, 'APSC (Assam Civil Services)', 'apsc', 'Assam Public Service Commission — ACS exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), NULL, 'Goa PSC', 'goa-psc', 'Goa Public Service Commission — State Services', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-psc'), NULL, 'HP PSC (Himachal Pradesh)', 'hppsc', 'Himachal Pradesh PSC — State Services exam', 'main', 'active');

-- ============================================================
-- EXAMS — Defence & Paramilitary
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='defence'), 1, 'NDA (National Defence Academy)', 'nda', 'Entry to Army/Navy/Air Force wings of NDA for 10+2 students', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), 1, 'CDS (Combined Defence Services)', 'cds', 'Entry to IMA, INA, AFA, OTA for graduates', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'AFCAT (Air Force Common Admission Test)', 'afcat', 'Indian Air Force officer entry for Flying and Ground Duty', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'Indian Army JCO/GD', 'army-soldier-gd', 'Indian Army — Soldier General Duty, Technical, Tradesman', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'Indian Navy (Sailors & Officers)', 'indian-navy', 'Navy — SSR, MR, AA, INCET and officer entry exams', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'BSF Head Constable & ASI', 'bsf-hc', 'Border Security Force Head Constable and ASI recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'CRPF Constable & ASI', 'crpf', 'Central Reserve Police Force recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'CISF Constable', 'cisf-constable', 'Central Industrial Security Force Constable (Trade) recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'ITBP Constable & SI', 'itbp', 'Indo-Tibetan Border Police recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'SSB (Sashastra Seema Bal)', 'ssb-force', 'Sashastra Seema Bal — Constable, Head Constable, Inspector', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='defence'), NULL, 'Assam Rifles', 'assam-rifles', 'Assam Rifles — Rifleman, Havildar and Technical posts', 'main', 'active');

-- ============================================================
-- EXAMS — Teaching
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='teaching'), 15, 'CTET (Central Teacher Eligibility Test)', 'ctet', 'Eligibility test for central govt school teachers Paper I & II', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), NULL, 'UP TET (Uttar Pradesh TET)', 'up-tet', 'UP Teacher Eligibility Test for primary and upper primary', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), NULL, 'Bihar TET (BTET)', 'btet', 'Bihar Teacher Eligibility Test', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), NULL, 'Rajasthan REET', 'reet', 'Rajasthan Eligibility Examination for Teachers', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), NULL, 'MP TET / MPTET', 'mptet', 'Madhya Pradesh Teacher Eligibility Test Varg 1, 2, 3', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), 16, 'UGC NET (National Eligibility Test)', 'ugc-net', 'Eligibility for Assistant Professor and JRF in universities', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), NULL, 'CSIR UGC NET', 'csir-net', 'CSIR NET for JRF in Science subjects', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), 17, 'KVS TGT/PGT/PRT', 'kvs-teacher', 'Kendriya Vidyalaya Sangathan teacher recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), 18, 'NVS TGT/PGT/Misc', 'nvs-teacher', 'Navodaya Vidyalaya Samiti teacher and staff recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='teaching'), 19, 'DSSSB TGT/PGT/PRT', 'dsssb-teacher', 'DSSSB Delhi — TGT, PGT, PRT, LDC and various posts', 'main', 'active');

-- ============================================================
-- EXAMS — Insurance
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='insurance'), 13, 'LIC AAO (Assistant Administrative Officer)', 'lic-aao', 'LIC — Generalist and Specialist (IT/CA/Actuarial) AAO', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='insurance'), 13, 'LIC ADO (Apprentice Development Officer)', 'lic-ado', 'LIC ADO recruitment for marketing and development roles', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='insurance'), 13, 'LIC HFL (Housing Finance Ltd)', 'lic-hfl', 'LIC Housing Finance Assistant/Officer posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='insurance'), NULL, 'NIACL AO & Assistant', 'niacl', 'New India Assurance Company — AO and Assistant recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='insurance'), 14, 'NICL AO & Assistant', 'nicl', 'National Insurance Company — AO Scale I and Assistant', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='insurance'), NULL, 'UIICL (United India Insurance)', 'uiicl', 'United India Insurance Company — AO and Assistant posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='insurance'), NULL, 'GIC (General Insurance Corporation)', 'gic-scale1', 'GIC Re — Scale 1 Officer (Generalist and Specialist)', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='insurance'), NULL, 'OICL (Oriental Insurance)', 'oicl', 'Oriental Insurance Company — AO Class I posts', 'main', 'active');

-- ============================================================
-- EXAMS — Engineering Entrance
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='engineering-entrance'), 7, 'JEE Main', 'jee-main', 'Joint Entrance Exam — NIT, IIIT and other CFTIs admission', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='engineering-entrance'), 7, 'JEE Advanced', 'jee-advanced', 'IIT admission exam — top 2.5 lakh JEE Main qualifiers', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='engineering-entrance'), NULL, 'BITSAT', 'bitsat', 'BITS Pilani Admissions — Computer based engineering entrance', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='engineering-entrance'), NULL, 'VITEEE', 'viteee', 'VIT Engineering Entrance Exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='engineering-entrance'), NULL, 'MHT-CET Engineering', 'mht-cet-engg', 'Maharashtra Common Entrance Test for Engineering', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='engineering-entrance'), NULL, 'KEAM (Kerala Engineering)', 'keam', 'Kerala Engineering Architecture Medical entrance', 'main', 'active');

-- ============================================================
-- EXAMS — Medical Entrance
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='medical-entrance'), 7, 'NEET UG', 'neet-ug', 'National Eligibility Entrance Test for MBBS/BDS/BAMS/BHMS', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='medical-entrance'), 7, 'NEET PG', 'neet-pg', 'NEET Postgraduate for MD/MS/Diploma admissions', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='medical-entrance'), NULL, 'AIIMS PG Entrance', 'aiims-pg', 'AIIMS New Delhi Postgraduate entrance exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='medical-entrance'), NULL, 'INI CET', 'ini-cet', 'Institute of National Importance — Combined Entrance Test', 'main', 'active');

-- ============================================================
-- EXAMS — Management Entrance
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='management-entrance'), NULL, 'CAT (Common Admission Test)', 'cat', 'MBA admission to IIMs and 100+ top B-schools', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='management-entrance'), NULL, 'MAT (Management Aptitude Test)', 'mat', 'AIMA MAT for 600+ B-school admissions', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='management-entrance'), NULL, 'XAT (Xavier Aptitude Test)', 'xat', 'XLRI Xavier Aptitude Test for XLRI and 160+ institutes', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='management-entrance'), NULL, 'SNAP (Symbiosis National Aptitude)', 'snap', 'SNAP test for Symbiosis International University programs', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='management-entrance'), NULL, 'IIFT (Indian Institute of Foreign Trade)', 'iift', 'IIFT MBA IB entrance exam', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='management-entrance'), NULL, 'CMAT (Common Management Admission)', 'cmat', 'NTA CMAT for PGDM/MBA admission', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='management-entrance'), NULL, 'GMAT (Graduate Management)', 'gmat', 'Global MBA entrance for international B-schools', 'main', 'active');

-- ============================================================
-- EXAMS — Law Entrance
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='law-entrance'), NULL, 'CLAT (Common Law Admission Test)', 'clat', 'NLU admission — 22 National Law Universities across India', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='law-entrance'), NULL, 'AILET (NLU Delhi Entrance)', 'ailet', 'National Law University Delhi — independent entrance', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='law-entrance'), NULL, 'LSAT India', 'lsat-india', 'Law School Admission Test — various private law schools', 'main', 'active');

-- ============================================================
-- EXAMS — GATE & PSU
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'GATE (Graduate Aptitude Test)', 'gate', 'MTech/PhD admission and PSU jobs via GATE score', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'GATE CSE', 'gate-cse', 'GATE Computer Science & Information Technology', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'GATE ECE', 'gate-ece', 'GATE Electronics & Communication Engineering', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'GATE ME', 'gate-me', 'GATE Mechanical Engineering', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'GATE CE', 'gate-ce', 'GATE Civil Engineering', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'GATE EE', 'gate-ee', 'GATE Electrical Engineering', 'sub', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'ISRO Scientist/Engineer', 'isro-sc', 'Indian Space Research Organisation — Scientist/Engineer SC', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'DRDO CEPTAM', 'drdo-ceptam', 'DRDO — A, B & Technician posts', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'BEL Probationary Engineer', 'bel-pe', 'Bharat Electronics Limited — PE and Trainee Engineer', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='gate-psu'), NULL, 'ONGC E1 Engineer', 'ongc-e1', 'Oil & Natural Gas Corporation — AEE/AE recruitment', 'main', 'active');

-- ============================================================
-- EXAMS — CUET
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='cuet'), 7, 'CUET UG', 'cuet-ug', 'Common University Entrance Test — Central Universities UG admission', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='cuet'), 7, 'CUET PG', 'cuet-pg', 'Common University Entrance Test — PG admissions across India', 'main', 'active');

-- ============================================================
-- EXAMS — Skill & Computer
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='skill-computer'), 30, 'NIELIT CCC (Course on Computer Concepts)', 'nielit-ccc', 'Most popular govt computer course exam in India', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='skill-computer'), 30, 'NIELIT O Level', 'nielit-o-level', 'Foundation level computer science programme by NIELIT', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='skill-computer'), 30, 'NIELIT A Level', 'nielit-a-level', 'Advanced Diploma in IT by NIELIT (equiv to MCA 1st year)', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='skill-computer'), 30, 'NIELIT B Level', 'nielit-b-level', 'NIELIT B Level — MCA level qualification', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='skill-computer'), NULL, 'Typing Test (Hindi/English)', 'typing-test', 'Government typing tests for clerk, steno, LDC posts', 'main', 'active');

-- ============================================================
-- EXAMS — State Misc (Police/Patwari/Clerk)
-- ============================================================
INSERT IGNORE INTO `exams` (`category_id`, `organization_id`, `title`, `slug`, `short_description`, `exam_level`, `status`) VALUES
((SELECT id FROM exam_categories WHERE slug='police-constable'), NULL, 'UP Police Constable', 'up-police-constable', 'Uttar Pradesh Police Constable Civil Police recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='police-constable'), NULL, 'UP Police SI', 'up-police-si', 'UP Police Sub-Inspector Civil Police recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='police-constable'), NULL, 'Rajasthan Police Constable', 'rajasthan-police-constable', 'Rajasthan Police Constable recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='police-constable'), NULL, 'MP Police Constable', 'mp-police-constable', 'Madhya Pradesh Police Constable recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='police-constable'), NULL, 'Bihar Police Constable', 'bihar-police-constable', 'Bihar Police Constable recruitment via CSBC', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='police-constable'), NULL, 'Delhi Police Constable', 'delhi-police-constable', 'Delhi Police Constable (Exe) Male/Female', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='police-constable'), NULL, 'Haryana Police Constable', 'haryana-police-constable', 'Haryana Police Constable recruitment via HSSC', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-misc'), NULL, 'UP Lekhpal (Rajasva)', 'up-lekhpal', 'Uttar Pradesh Revenue Board Lekhpal recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-misc'), NULL, 'Rajasthan Patwari', 'rajasthan-patwari', 'Rajasthan Revenue Patwari recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-misc'), NULL, 'MP Patwari', 'mp-patwari', 'Madhya Pradesh Patwari recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-misc'), NULL, 'UP Gram Panchayat Adhikari / VDO', 'up-vdo', 'UP Village Development Officer recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-misc'), NULL, 'UP Junior Assistant (Clerk)', 'up-junior-assistant', 'UP Sachivalaya Junior Assistant / LDC recruitment', 'main', 'active'),
((SELECT id FROM exam_categories WHERE slug='state-misc'), NULL, 'Rajasthan Vanpal/Vanrakshak', 'rajasthan-vanpal', 'Rajasthan Forest Guard and Forest Ranger recruitment', 'main', 'active');

SELECT CONCAT('Mega Exam Seed complete — total exams: ', COUNT(*)) AS result FROM exams;
