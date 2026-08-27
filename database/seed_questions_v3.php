<?php
require_once __DIR__ . '/../api/config/db.php';

try {
    $db = Database::getConnection();
    echo "=== Seeding High-Yield Question Bank & Test Mapping ===\n";

    // Standard subjects (1: Quant, 2: Reasoning, 3: English, 4: GA)
    $qData = [
        // QUANT (subject_id = 1)
        [
            'subject_id' => 1,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'If the ratio of two numbers is 3 : 4 and their HCF is 4, then their LCM is:',
            'solution' => 'Let numbers be 3x and 4x. HCF = x = 4. Numbers are 12 and 16. LCM(12, 16) = 48.',
            'options' => [
                ['A', '12', 0],
                ['B', '16', 0],
                ['C', '24', 0],
                ['D', '48', 1]
            ]
        ],
        [
            'subject_id' => 1,
            'question_type' => 'MCQ',
            'difficulty' => 'medium',
            'text' => 'A shopkeeper sells an article at a discount of 20% on the marked price and still gains 20%. If marked price is ₹600, find the cost price.',
            'solution' => 'Selling Price = 80% of 600 = ₹480. Cost Price = 480 / 1.20 = ₹400.',
            'options' => [
                ['A', '₹360', 0],
                ['B', '₹400', 1],
                ['C', '₹450', 0],
                ['D', '₹480', 0]
            ]
        ],
        [
            'subject_id' => 1,
            'question_type' => 'MCQ',
            'difficulty' => 'hard',
            'text' => 'A and B can do a work in 12 days and 18 days respectively. They worked together for 4 days after which A left. In how many more days will B finish the remaining work?',
            'solution' => 'Work per day: A = 1/12, B = 1/18. Combined = 5/36 per day. In 4 days = 20/36 = 5/9 work done. Remaining = 4/9. B alone time = (4/9) / (1/18) = 8 days.',
            'options' => [
                ['A', '6 days', 0],
                ['B', '8 days', 1],
                ['C', '10 days', 0],
                ['D', '12 days', 0]
            ]
        ],
        [
            'subject_id' => 1,
            'question_type' => 'MCQ',
            'difficulty' => 'medium',
            'text' => 'What is the compound interest on ₹10,000 for 2 years at 10% per annum, compounded annually?',
            'solution' => 'A = P(1 + r/100)^n = 10000 * 1.10^2 = ₹12,100. CI = 12,100 - 10,000 = ₹2,100.',
            'options' => [
                ['A', '₹2,000', 0],
                ['B', '₹2,100', 1],
                ['C', '₹2,200', 0],
                ['D', '₹2,500', 0]
            ]
        ],
        [
            'subject_id' => 1,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'The average of 5 consecutive numbers is 20. What is the largest of these numbers?',
            'solution' => 'Average of consecutive numbers is the middle (3rd) number. Middle = 20. 5th number = 20 + 2 = 22.',
            'options' => [
                ['A', '20', 0],
                ['B', '21', 0],
                ['C', '22', 1],
                ['D', '24', 0]
            ]
        ],

        // REASONING (subject_id = 2)
        [
            'subject_id' => 2,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'Select the option that is related to the third word in the same way as the second word is related to the first word:\nThermometer : Temperature :: Barometer : ?',
            'solution' => 'Thermometer measures Temperature; Barometer measures Atmospheric Pressure.',
            'options' => [
                ['A', 'Humidity', 0],
                ['B', 'Pressure', 1],
                ['C', 'Density', 0],
                ['D', 'Thickness', 0]
            ]
        ],
        [
            'subject_id' => 2,
            'question_type' => 'MCQ',
            'difficulty' => 'medium',
            'text' => 'In a certain code language, "FLOWER" is written as "EKNVDQ". How will "GARDEN" be written in that language?',
            'solution' => 'Pattern: Each letter is shifted by -1 position in alphabetical order (F->E, L->K, O->N, W->V, E->D, R->Q). So G->F, A->Z, R->Q, D->C, E->D, N->M. "FZQCDM".',
            'options' => [
                ['A', 'FZQCDM', 1],
                ['B', 'FZQDEM', 0],
                ['C', 'HBSEFO', 0],
                ['D', 'FYPBDL', 0]
            ]
        ],
        [
            'subject_id' => 2,
            'question_type' => 'MCQ',
            'difficulty' => 'medium',
            'text' => 'Pointing to a photograph, a woman says, "He is the son of the only daughter of my father." How is the man in the photograph related to the woman?',
            'solution' => '"Only daughter of my father" = the woman herself. So the man is her Son.',
            'options' => [
                ['A', 'Brother', 0],
                ['B', 'Son', 1],
                ['C', 'Father', 0],
                ['D', 'Nephew', 0]
            ]
        ],
        [
            'subject_id' => 2,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'Which number will replace the question mark (?) in the following series?\n7, 10, 16, 25, 37, ?',
            'solution' => 'Differences: +3, +6, +9, +12, +15. Next difference = +15. 37 + 15 = 52.',
            'options' => [
                ['A', '49', 0],
                ['B', '50', 0],
                ['C', '52', 1],
                ['D', '55', 0]
            ]
        ],
        [
            'subject_id' => 2,
            'question_type' => 'MCQ',
            'difficulty' => 'hard',
            'text' => 'Statements:\n1. All dogs are mammals.\n2. All mammals are animals.\nConclusions:\nI. All dogs are animals.\nII. Some animals are dogs.',
            'solution' => 'By Syllogism Venn Diagram: Dogs inside Mammals, Mammals inside Animals. Both Conclusion I and Conclusion II follow.',
            'options' => [
                ['A', 'Only Conclusion I follows', 0],
                ['B', 'Only Conclusion II follows', 0],
                ['C', 'Neither Conclusion I nor II follows', 0],
                ['D', 'Both Conclusion I and II follow', 1]
            ]
        ],

        // ENGLISH (subject_id = 3)
        [
            'subject_id' => 3,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'Select the most appropriate synonym of the given word:\nOBSTINATE',
            'solution' => 'Obstinate means stubborn or unyielding. Synonym is Stubborn.',
            'options' => [
                ['A', 'Docile', 0],
                ['B', 'Flexible', 0],
                ['C', 'Stubborn', 1],
                ['D', 'Soft', 0]
            ]
        ],
        [
            'subject_id' => 3,
            'question_type' => 'MCQ',
            'difficulty' => 'medium',
            'text' => 'Select the correctly spelt word:',
            'solution' => 'The correct spelling is "ACCOMMODATE" (double c, double m).',
            'options' => [
                ['A', 'Acommodate', 0],
                ['B', 'Accommodate', 1],
                ['C', 'Accomodate', 0],
                ['D', 'Acomodate', 0]
            ]
        ],
        [
            'subject_id' => 3,
            'question_type' => 'MCQ',
            'difficulty' => 'medium',
            'text' => 'Identify the segment containing a grammatical error:\n"Neither the principal nor the teachers was present at the meeting."',
            'solution' => 'With "neither... nor", the verb agrees with the subject closest to it ("teachers", plural). So it should be "were present", not "was present". Error is in "was present".',
            'options' => [
                ['A', 'Neither the principal', 0],
                ['B', 'nor the teachers', 0],
                ['C', 'was present', 1],
                ['D', 'at the meeting', 0]
            ]
        ],
        [
            'subject_id' => 3,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'Select the meaning of the given idiom:\n"Spill the beans"',
            'solution' => '"Spill the beans" means to reveal a secret prematurely.',
            'options' => [
                ['A', 'To drop food', 0],
                ['B', 'To reveal a secret', 1],
                ['C', 'To waste money', 0],
                ['D', 'To work hard', 0]
            ]
        ],

        // GENERAL AWARENESS (subject_id = 4)
        [
            'subject_id' => 4,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'Which fundamental right in the Indian Constitution guarantees protection against untouchability?',
            'solution' => 'Article 17 of the Constitution of India abolishes Untouchability and forbids its practice in any form.',
            'options' => [
                ['A', 'Article 14', 0],
                ['B', 'Article 17', 1],
                ['C', 'Article 19', 0],
                ['D', 'Article 21', 0]
            ]
        ],
        [
            'subject_id' => 4,
            'question_type' => 'MCQ',
            'difficulty' => 'medium',
            'text' => 'Who was the first Governor-General of Independent India?',
            'solution' => 'Lord Mountbatten served as the first Governor-General of Independent India (1947–1948). C. Rajagopalachari was the first Indian Governor-General.',
            'options' => [
                ['A', 'Lord Mountbatten', 1],
                ['B', 'C. Rajagopalachari', 0],
                ['C', 'Dr. Rajendra Prasad', 0],
                ['D', 'Jawaharlal Nehru', 0]
            ]
        ],
        [
            'subject_id' => 4,
            'question_type' => 'MCQ',
            'difficulty' => 'easy',
            'text' => 'The Tropic of Cancer does NOT pass through which of the following Indian states?',
            'solution' => 'Tropic of Cancer passes through 8 Indian states: Gujarat, Rajasthan, MP, Chhattisgarh, Jharkhand, West Bengal, Tripura, Mizoram. It does NOT pass through Odisha.',
            'options' => [
                ['A', 'Rajasthan', 0],
                ['B', 'Odisha', 1],
                ['C', 'Chhattisgarh', 0],
                ['D', 'Tripura', 0]
            ]
        ]
    ];

    $newQIds = [];

    foreach ($qData as $q) {
        $qStmt = $db->prepare("INSERT INTO questions (subject_id, question_type, difficulty, status) VALUES (?, ?, ?, 'published')");
        $qStmt->execute([$q['subject_id'], $q['question_type'], $q['difficulty']]);
        $qId = $db->lastInsertId();
        $newQIds[] = $qId;

        $tStmt = $db->prepare("INSERT INTO question_translations (question_id, language, question_text, solution_text) VALUES (?, 'en', ?, ?)");
        $tStmt->execute([$qId, $q['text'], $q['solution']]);

        foreach ($q['options'] as $opt) {
            $oStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
            $oStmt->execute([$qId, $opt[0], $opt[1], $opt[2]]);
        }
    }

    echo "Seeded " . count($newQIds) . " new questions.\n";

    // Map new questions into Test #1 (SSC CGL Full Mock) and Test #3 (Monthly Challenge)
    $testIds = [1, 2, 3];
    foreach ($testIds as $tId) {
        // Clear and remap
        $order = 1;
        foreach ($newQIds as $qId) {
            $db->prepare("
                INSERT INTO test_questions (test_id, question_id, question_order, positive_marks, negative_marks)
                VALUES (?, ?, ?, 2.00, 0.50)
                ON DUPLICATE KEY UPDATE question_order = VALUES(question_order)
            ")->execute([$tId, $qId, $order++]);
        }
    }

    echo "Mapped questions across tests 1, 2, 3 successfully!\n";

} catch (Exception $e) {
    echo "Error seeding questions: " . $e->getMessage() . "\n";
}
