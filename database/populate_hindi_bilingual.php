<?php
require_once __DIR__ . '/../api/config/db.php';

$db = Database::getConnection();

// Comprehensive Bilingual Translations for all 28 questions and their options
$bilingualData = [
    1 => [
        'en' => [
            'question' => 'If 20% of A is equal to 30% of B, then what percentage of B is A?',
            'solution' => '0.20 * A = 0.30 * B => A / B = 3 / 2 = 1.5 => A is 150% of B.',
            'options' => [
                'A' => '120%',
                'B' => '150%',
                'C' => '133.33%',
                'D' => '166.66%'
            ]
        ],
        'hi' => [
            'question' => 'यदि A का 20% B के 30% के बराबर है, तो A, B का कितना प्रतिशत है?',
            'solution' => '0.20 * A = 0.30 * B => A / B = 3 / 2 = 1.5 => A, B का 150% है।',
            'options' => [
                'A' => '120%',
                'B' => '150%',
                'C' => '133.33%',
                'D' => '166.66%'
            ]
        ]
    ],
    2 => [
        'en' => [
            'question' => 'A shopkeeper marks an item 40% above cost price and allows a 15% discount. What is his profit percentage?',
            'solution' => 'Let CP = 100. MP = 140. SP = 140 * 0.85 = 119. Profit = 19%.',
            'options' => [
                'A' => '18%',
                'B' => '19%',
                'C' => '20%',
                'D' => '25%'
            ]
        ],
        'hi' => [
            'question' => 'एक दुकानदार किसी वस्तु का मूल्य क्रय मूल्य से 40% अधिक अंकित करता है और 15% की छूट देता है। उसका लाभ प्रतिशत क्या है?',
            'solution' => 'माना क्रय मूल्य (CP) = 100. अंकित मूल्य (MP) = 140. विक्रय मूल्य (SP) = 140 * 0.85 = 119. लाभ = 19%.',
            'options' => [
                'A' => '18%',
                'B' => '19%',
                'C' => '20%',
                'D' => '25%'
            ]
        ]
    ],
    3 => [
        'en' => [
            'question' => 'In a certain code language, "FLOWER" is written as "EKNVDQ". How is "GARDEN" written in that code?',
            'solution' => 'Each letter is shifted by -1: G->F, A->Z, R->Q, D->C, E->D, N->M => FZQCDM.',
            'options' => [
                'A' => 'FZQCDM',
                'B' => 'EYPBDL',
                'C' => 'FZRCEM',
                'D' => 'HBSEFO'
            ]
        ],
        'hi' => [
            'question' => 'एक निश्चित कूट भाषा में, "FLOWER" को "EKNVDQ" लिखा जाता है। उसी कूट भाषा में "GARDEN" को कैसे लिखा जाएगा?',
            'solution' => 'प्रत्येक अक्षर में -1 का बदलाव है: G->F, A->Z, R->Q, D->C, E->D, N->M => FZQCDM.',
            'options' => [
                'A' => 'FZQCDM',
                'B' => 'EYPBDL',
                'C' => 'FZRCEM',
                'D' => 'HBSEFO'
            ]
        ]
    ],
    4 => [
        'en' => [
            'question' => 'Identify the error in the sentence: "Neither of the two candidates have submitted their documents."',
            'solution' => '"Neither of" takes a singular verb. "have submitted" should be "has submitted".',
            'options' => [
                'A' => 'Neither of the',
                'B' => 'two candidates',
                'C' => 'have submitted',
                'D' => 'their documents'
            ]
        ],
        'hi' => [
            'question' => 'वाक्य में त्रुटि पहचानें: "Neither of the two candidates have submitted their documents."',
            'solution' => '"Neither of" के साथ एकवचन क्रिया (singular verb) का प्रयोग होता है। "have submitted" के स्थान पर "has submitted" होगा।',
            'options' => [
                'A' => 'Neither of the',
                'B' => 'two candidates',
                'C' => 'have submitted',
                'D' => 'their documents'
            ]
        ]
    ],
    5 => [
        'en' => [
            'question' => 'Which Article of the Constitution of India deals with the Right to Equality?',
            'solution' => 'Articles 14 to 18 of the Indian Constitution deal with the Right to Equality.',
            'options' => [
                'A' => 'Article 12-13',
                'B' => 'Article 14-18',
                'C' => 'Article 19-22',
                'D' => 'Article 25-28'
            ]
        ],
        'hi' => [
            'question' => 'भारत के संविधान का कौन सा अनुच्छेद समानता के अधिकार (Right to Equality) से संबंधित है?',
            'solution' => 'भारतीय संविधान के अनुच्छेद 14 से 18 समानता के अधिकार से संबंधित हैं।',
            'options' => [
                'A' => 'अनुच्छेद 12-13',
                'B' => 'अनुच्छेद 14-18',
                'C' => 'अनुच्छेद 19-22',
                'D' => 'अनुच्छेद 25-28'
            ]
        ]
    ],
    6 => [
        'en' => [
            'question' => 'If the ratio of two numbers is 3 : 4 and their HCF is 4, then their LCM is:',
            'solution' => 'Numbers are 3*4 = 12 and 4*4 = 16. LCM(12, 16) = 48.',
            'options' => [
                'A' => '12',
                'B' => '16',
                'C' => '24',
                'D' => '48'
            ]
        ],
        'hi' => [
            'question' => 'यदि दो संख्याओं का अनुपात 3 : 4 है और उनका म.स.प. (HCF) 4 है, तो उनका ल.स.प. (LCM) क्या होगा?',
            'solution' => 'संख्याएं 3*4 = 12 और 4*4 = 16 हैं। LCM(12, 16) = 48.',
            'options' => [
                'A' => '12',
                'B' => '16',
                'C' => '24',
                'D' => '48'
            ]
        ]
    ],
    7 => [
        'en' => [
            'question' => 'A shopkeeper sells an article at a discount of 20% on the marked price and still gains 20%. If marked price is ₹600, find the cost price.',
            'solution' => 'SP = 600 * 0.80 = 480. CP = 480 / 1.20 = ₹400.',
            'options' => [
                'A' => '₹400',
                'B' => '₹450',
                'C' => '₹380',
                'D' => '₹420'
            ]
        ],
        'hi' => [
            'question' => 'एक दुकानदार अंकित मूल्य पर 20% की छूट देकर भी 20% का लाभ कमाता है। यदि अंकित मूल्य ₹600 है, तो क्रय मूल्य ज्ञात कीजिए।',
            'solution' => 'SP = 600 * 0.80 = 480. CP = 480 / 1.20 = ₹400.',
            'options' => [
                'A' => '₹400',
                'B' => '₹450',
                'C' => '₹380',
                'D' => '₹420'
            ]
        ]
    ],
    8 => [
        'en' => [
            'question' => 'A and B can do a work in 12 days and 18 days respectively. They worked together for 4 days after which A left. In how many more days will B finish the remaining work?',
            'solution' => 'Total work = 36 units. A = 3, B = 2. 4 days work = (3+2)*4 = 20 units. Remaining = 16 units. B time = 16/2 = 8 days.',
            'options' => [
                'A' => '6 days',
                'B' => '8 days',
                'C' => '10 days',
                'D' => '12 days'
            ]
        ],
        'hi' => [
            'question' => 'A और B किसी काम को क्रमशः 12 दिन और 18 दिन में पूरा कर सकते हैं। उन्होंने 4 दिनों तक एक साथ काम किया, जिसके बाद A चला गया। B शेष कार्य को कितने और दिनों में पूरा करेगा?',
            'solution' => 'कुल कार्य = 36 यूनिट। A = 3, B = 2. 4 दिनों का कार्य = 5*4 = 20 यूनिट। शेष = 16 यूनिट। B द्वारा लिया गया समय = 16/2 = 8 दिन।',
            'options' => [
                'A' => '6 दिन',
                'B' => '8 दिन',
                'C' => '10 दिन',
                'D' => '12 दिन'
            ]
        ]
    ],
    9 => [
        'en' => [
            'question' => 'What is the compound interest on ₹10,000 for 2 years at 10% per annum, compounded annually?',
            'solution' => 'A = 10000 * (1.1)^2 = 12100. CI = 12100 - 10000 = ₹2,100.',
            'options' => [
                'A' => '₹2,000',
                'B' => '₹2,100',
                'C' => '₹2,200',
                'D' => '₹2,050'
            ]
        ],
        'hi' => [
            'question' => '₹10,000 पर 10% वार्षिक दर से 2 वर्ष का वार्षिक संयोजित चक्रवृद्धि ब्याज (Compound Interest) क्या होगा?',
            'solution' => 'A = 10000 * (1.1)^2 = 12100. CI = 12100 - 10000 = ₹2,100.',
            'options' => [
                'A' => '₹2,000',
                'B' => '₹2,100',
                'C' => '₹2,200',
                'D' => '₹2,050'
            ]
        ]
    ],
    10 => [
        'en' => [
            'question' => 'The average of 5 consecutive numbers is 20. What is the largest of these numbers?',
            'solution' => 'Let numbers be x, x+1, x+2, x+3, x+4. Average is x+2 = 20 => x = 18. Largest = x+4 = 22.',
            'options' => [
                'A' => '20',
                'B' => '21',
                'C' => '22',
                'D' => '24'
            ]
        ],
        'hi' => [
            'question' => '5 क्रमागत (लगातार) संख्याओं का औसत 20 है। इनमें से सबसे बड़ी संख्या कौन सी है?',
            'solution' => 'संख्याएं x, x+1, x+2, x+3, x+4 हैं। औसत = x+2 = 20 => x = 18. सबसे बड़ी संख्या = 18+4 = 22.',
            'options' => [
                'A' => '20',
                'B' => '21',
                'C' => '22',
                'D' => '24'
            ]
        ]
    ],
    11 => [
        'en' => [
            'question' => 'Select the option that is related to the third word in the same way as the second word is related to the first word:\nThermometer : Temperature :: Barometer : ?',
            'solution' => 'Thermometer measures Temperature; Barometer measures Atmospheric Pressure.',
            'options' => [
                'A' => 'Humidity',
                'B' => 'Pressure',
                'C' => 'Current',
                'D' => 'Earthquake'
            ]
        ],
        'hi' => [
            'question' => 'उस विकल्प का चयन करें जो तीसरे शब्द से उसी प्रकार संबंधित है जैसे दूसरा शब्द पहले शब्द से संबंधित है:\nथर्मामीटर : तापमान :: बैरोमीटर : ?',
            'solution' => 'थर्मामीटर तापमान मापता है; बैरोमीटर वायुमंडलीय दाब (Pressure) मापता है।',
            'options' => [
                'A' => 'आर्द्रता',
                'B' => 'दाब (Pressure)',
                'C' => 'विद्युत धारा',
                'D' => 'भूकंप'
            ]
        ]
    ],
    12 => [
        'en' => [
            'question' => 'In a certain code language, "FLOWER" is written as "EKNVDQ". How will "GARDEN" be written in that language?',
            'solution' => 'Shift of -1 for each letter => FZQCDM.',
            'options' => [
                'A' => 'FZQCDM',
                'B' => 'FZQCEN',
                'C' => 'EYPBDM',
                'D' => 'GZQDDM'
            ]
        ],
        'hi' => [
            'question' => 'एक निश्चित कूट भाषा में, "FLOWER" को "EKNVDQ" लिखा जाता है। उसी भाषा में "GARDEN" को क्या लिखा जाएगा?',
            'solution' => 'प्रत्येक अक्षर -1 घटता है => FZQCDM.',
            'options' => [
                'A' => 'FZQCDM',
                'B' => 'FZQCEN',
                'C' => 'EYPBDM',
                'D' => 'GZQDDM'
            ]
        ]
    ],
    13 => [
        'en' => [
            'question' => 'Pointing to a photograph, a woman says, "He is the son of the only daughter of my father." How is the man in the photograph related to the woman?',
            'solution' => 'Only daughter of my father = Woman herself. Son of woman = Her son.',
            'options' => [
                'A' => 'Brother',
                'B' => 'Son',
                'C' => 'Father',
                'D' => 'Nephew'
            ]
        ],
        'hi' => [
            'question' => 'एक तस्वीर की ओर इशारा करते हुए एक महिला कहती है, "वह मेरे पिता की इकलौती बेटी का बेटा है।" तस्वीर वाला व्यक्ति उस महिला से किस प्रकार संबंधित है?',
            'solution' => 'मेरे पिता की इकलौती बेटी = महिला स्वयं। महिला का बेटा = उसका पुत्र (Son)।',
            'options' => [
                'A' => 'भाई',
                'B' => 'बेटा (Son)',
                'C' => 'पिता',
                'D' => 'भांजा/भतीजा'
            ]
        ]
    ],
    14 => [
        'en' => [
            'question' => 'Which number will replace the question mark (?) in the following series?\n7, 10, 16, 25, 37, ?',
            'solution' => 'Differences: +3, +6, +9, +12, +15 => 37 + 15 = 52.',
            'options' => [
                'A' => '50',
                'B' => '52',
                'C' => '54',
                'D' => '56'
            ]
        ],
        'hi' => [
            'question' => 'निम्नलिखित श्रृंखला में प्रश्न चिह्न (?) के स्थान पर कौन सी संख्या आएगी?\n7, 10, 16, 25, 37, ?',
            'solution' => 'अंतर: +3, +6, +9, +12, +15 => 37 + 15 = 52.',
            'options' => [
                'A' => '50',
                'B' => '52',
                'C' => '54',
                'D' => '56'
            ]
        ]
    ],
    15 => [
        'en' => [
            'question' => "Statements:\n1. All dogs are mammals.\n2. All mammals are animals.\nConclusions:\nI. All dogs are animals.\nII. Some animals are dogs.",
            'solution' => 'Both conclusions I and II logically follow.',
            'options' => [
                'A' => 'Only I follows',
                'B' => 'Only II follows',
                'C' => 'Both I and II follow',
                'D' => 'Neither follows'
            ]
        ],
        'hi' => [
            'question' => "कथन:\n1. सभी कुत्ते स्तनधारी हैं।\n2. सभी स्तनधारी जानवर हैं।\nनिष्कर्ष:\nI. सभी कुत्ते जानवर हैं।\nII. कुछ जानवर कुत्ते हैं।",
            'solution' => 'दोनों निष्कर्ष I और II तार्किक रूप से अनुसरण करते हैं।',
            'options' => [
                'A' => 'केवल I अनुसरण करता है',
                'B' => 'केवल II अनुसरण करता है',
                'C' => 'I और II दोनों अनुसरण करते हैं',
                'D' => 'कोई भी अनुसरण नहीं करता'
            ]
        ]
    ],
    16 => [
        'en' => [
            'question' => 'Select the most appropriate synonym of the given word:\nOBSTINATE',
            'solution' => 'Obstinate means stubbornly refusing to change one\'s opinion. Synonym is Stubborn.',
            'options' => [
                'A' => 'Flexible',
                'B' => 'Stubborn',
                'C' => 'Gentle',
                'D' => 'Docile'
            ]
        ],
        'hi' => [
            'question' => 'दिए गए शब्द का सबसे उपयुक्त समानार्थी (Synonym) चुनें:\nOBSTINATE (हठी/जिद्दी)',
            'solution' => 'Obstinate का अर्थ जिद्दी/हठी होता है। इसका पर्यायवाची Stubborn है।',
            'options' => [
                'A' => 'Flexible (लचीला)',
                'B' => 'Stubborn (जिद्दी)',
                'C' => 'Gentle (सौम्य)',
                'D' => 'Docile (विनम्र)'
            ]
        ]
    ],
    17 => [
        'en' => [
            'question' => 'Select the correctly spelt word:',
            'solution' => '"Accommodate" is the correct spelling with double c and double m.',
            'options' => [
                'A' => 'Acommodate',
                'B' => 'Accomodate',
                'C' => 'Accommodate',
                'D' => 'Acomodate'
            ]
        ],
        'hi' => [
            'question' => 'सही वर्तनी (Correctly spelt) वाले शब्द का चयन करें:',
            'solution' => '"Accommodate" सही वर्तनी है (double c और double m के साथ)।',
            'options' => [
                'A' => 'Acommodate',
                'B' => 'Accomodate',
                'C' => 'Accommodate',
                'D' => 'Acomodate'
            ]
        ]
    ],
    18 => [
        'en' => [
            'question' => 'Identify the segment containing a grammatical error:\n"Neither the principal nor the teachers was present at the meeting."',
            'solution' => 'When subjects are joined by "neither...nor", verb agrees with closer subject (teachers = plural => were present).',
            'options' => [
                'A' => 'Neither the principal',
                'B' => 'nor the teachers',
                'C' => 'was present',
                'D' => 'at the meeting'
            ]
        ],
        'hi' => [
            'question' => 'व्याकरणिक त्रुटि वाले भाग की पहचान करें:\n"Neither the principal nor the teachers was present at the meeting."',
            'solution' => '"neither...nor" में क्रिया निकटतम कर्ता (teachers = बहुवचन) के अनुसार "were present" होनी चाहिए।',
            'options' => [
                'A' => 'Neither the principal',
                'B' => 'nor the teachers',
                'C' => 'was present (त्रुटि: were present होगा)',
                'D' => 'at the meeting'
            ]
        ]
    ],
    19 => [
        'en' => [
            'question' => 'Select the meaning of the given idiom:\n"Spill the beans"',
            'solution' => 'To "spill the beans" means to reveal a secret prematurely or indiscreetly.',
            'options' => [
                'A' => 'To waste food',
                'B' => 'To reveal a secret',
                'C' => 'To cook well',
                'D' => 'To cause delay'
            ]
        ],
        'hi' => [
            'question' => 'दिए गए मुहावरे (Idiom) का अर्थ चुनें:\n"Spill the beans"',
            'solution' => '"Spill the beans" का अर्थ रहस्य या गुप्त बात उजागर करना (To reveal a secret) होता है।',
            'options' => [
                'A' => 'भोजन बर्बाद करना',
                'B' => 'रहस्य उजागर करना (To reveal a secret)',
                'C' => 'अच्छा खाना बनाना',
                'D' => 'देरी करना'
            ]
        ]
    ],
    20 => [
        'en' => [
            'question' => 'Which fundamental right in the Indian Constitution guarantees protection against untouchability?',
            'solution' => 'Article 17 of the Indian Constitution abolishes Untouchability.',
            'options' => [
                'A' => 'Article 14',
                'B' => 'Article 17',
                'C' => 'Article 21',
                'D' => 'Article 23'
            ]
        ],
        'hi' => [
            'question' => 'भारतीय संविधान का कौन सा मौलिक अधिकार अस्पृश्यता (छुआछूत) के उन्मूलन की गारंटी देता है?',
            'solution' => 'भारतीय संविधान का अनुच्छेद 17 अस्पृश्यता का उन्मूलन करता है।',
            'options' => [
                'A' => 'अनुच्छेद 14',
                'B' => 'अनुच्छेद 17',
                'C' => 'अनुच्छेद 21',
                'D' => 'अनुच्छेद 23'
            ]
        ]
    ],
    21 => [
        'en' => [
            'question' => 'Who was the first Governor-General of Independent India?',
            'solution' => 'Lord Mountbatten was the first Governor-General of independent India. C. Rajagopalachari was the first Indian Governor-General.',
            'options' => [
                'A' => 'Lord Mountbatten',
                'B' => 'C. Rajagopalachari',
                'C' => 'Dr. Rajendra Prasad',
                'D' => 'Jawaharlal Nehru'
            ]
        ],
        'hi' => [
            'question' => 'स्वतंत्र भारत के प्रथम गवर्नर जनरल कौन थे?',
            'solution' => 'लॉर्ड माउंटबेटन स्वतंत्र भारत के प्रथम गवर्नर जनरल थे। सी. राजगोपालाचारी प्रथम भारतीय गवर्नर जनरल थे।',
            'options' => [
                'A' => 'लॉर्ड माउंटबेटन',
                'B' => 'सी. राजगोपालाचारी',
                'C' => 'डॉ. राजेंद्र प्रसाद',
                'D' => 'जवाहरलाल नेहरू'
            ]
        ]
    ],
    22 => [
        'en' => [
            'question' => 'The Tropic of Cancer does NOT pass through which of the following Indian states?',
            'solution' => 'Tropic of Cancer passes through 8 states: Gujarat, Rajasthan, MP, Chhattisgarh, Jharkhand, West Bengal, Tripura, Mizoram. It does NOT pass through Odisha.',
            'options' => [
                'A' => 'Rajasthan',
                'B' => 'Chhattisgarh',
                'C' => 'Odisha',
                'D' => 'Tripura'
            ]
        ],
        'hi' => [
            'question' => 'कर्क रेखा (Tropic of Cancer) निम्नलिखित में से किस भारतीय राज्य से होकर नहीं गुजरती है?',
            'solution' => 'कर्क रेखा 8 राज्यों (गुजरात, राजस्थान, मध्य प्रदेश, छत्तीसगढ़, झारखंड, पश्चिम बंगाल, त्रिपुरा, मिजोरम) से गुजरती है। यह ओडिशा से होकर नहीं गुजरती।',
            'options' => [
                'A' => 'राजस्थान',
                'B' => 'छत्तीसगढ़',
                'C' => 'ओडिशा',
                'D' => 'त्रिपुरा'
            ]
        ]
    ],
    23 => [
        'en' => [
            'question' => 'What is the full form of DBMS in computer science?',
            'solution' => 'DBMS stands for Database Management System.',
            'options' => [
                'A' => 'Data Business Management System',
                'B' => 'Database Management System',
                'C' => 'Digital Basic Multi System',
                'D' => 'Direct Binary Management Software'
            ]
        ],
        'hi' => [
            'question' => 'कंप्यूटर विज्ञान में DBMS का पूर्ण रूप (Full Form) क्या है?',
            'solution' => 'DBMS का पूरा नाम Database Management System (डेटाबेस मैनेजमेंट सिस्टम) है।',
            'options' => [
                'A' => 'Data Business Management System',
                'B' => 'Database Management System',
                'C' => 'Digital Basic Multi System',
                'D' => 'Direct Binary Management Software'
            ]
        ]
    ],
    24 => [
        'en' => [
            'question' => 'A patient with long-standing rheumatoid arthritis undergoes a renal biopsy. Microscopic examination demonstrates extracellular amorphous eosinophilic deposits. Which special stain will display apple-green birefringence under polarized light?',
            'solution' => 'Congo Red stain demonstrates apple-green birefringence under polarized light in amyloidosis.',
            'options' => [
                'A' => 'Congo Red',
                'B' => 'Periodic acid-Schiff',
                'C' => 'Masson trichrome',
                'D' => 'Oil Red O'
            ]
        ],
        'hi' => [
            'question' => 'लंबे समय से रुमेटीइड गठिया से पीड़ित एक मरीज की रीनल बायोप्सी की जाती है। पोलराइज्ड लाइट के तहत कौन सा विशेष स्टेन सेब-हरा (Apple-green) बाइरिफ्रिंजेंस प्रदर्शित करता है?',
            'solution' => 'कांगो रेड (Congo Red) स्टेन एमाइलॉयडोसिस में पोलराइज्ड प्रकाश के तहत सेब-हरा बाइरिफ्रिंजेंस दिखाता है।',
            'options' => [
                'A' => 'कांगो रेड (Congo Red)',
                'B' => 'पीरियोडिक एसिड-शिफ (PAS)',
                'C' => 'मैसन ट्राइक्रोम',
                'D' => 'ऑयल रेड ओ'
            ]
        ]
    ],
    25 => [
        'en' => [
            'question' => 'Which of the following G-protein subunits is correctly paired with its downstream second messenger mechanism?',
            'solution' => 'Gs stimulates adenylyl cyclase, increasing cyclic AMP (cAMP).',
            'options' => [
                'A' => 'Gs - Increases cAMP',
                'B' => 'Gi - Increases cAMP',
                'C' => 'Gq - Decreases IP3',
                'D' => 'Gt - Increases cGMP'
            ]
        ],
        'hi' => [
            'question' => 'निम्नलिखित में से कौन सा जी-प्रोटीन सबयूनिट अपने डाउनस्ट्रीम सेकंड मैसेंजर तंत्र के साथ सही रूप से युग्मित है?',
            'solution' => 'Gs एडेनिलाइल साइक्लेज को उत्तेजित करता है, जिससे चक्रीय एएमपी (cAMP) बढ़ता है।',
            'options' => [
                'A' => 'Gs - cAMP को बढ़ाता है',
                'B' => 'Gi - cAMP को बढ़ाता है',
                'C' => 'Gq - IP3 को घटाता है',
                'D' => 'Gt - cGMP को बढ़ाता है'
            ]
        ]
    ],
    26 => [
        'en' => [
            'question' => 'A diagnostic test for Malaria correctly identifies 180 out of 200 diseased individuals as positive. What is the sensitivity of this diagnostic test?',
            'solution' => 'Sensitivity = True Positives / Total Diseased = 180 / 200 = 90%.',
            'options' => [
                'A' => '85%',
                'B' => '90%',
                'C' => '92%',
                'D' => '95%'
            ]
        ],
        'hi' => [
            'question' => 'मलेरिया के लिए एक नैदानिक परीक्षण 200 रोगग्रस्त व्यक्तियों में से 180 की सही पहचान पॉजिटिव के रूप में करता है। इस परीक्षण की संवेदनशीलता (Sensitivity) क्या है?',
            'solution' => 'संवेदनशीलता (Sensitivity) = सही पॉजिटिव / कुल रोगग्रस्त = 180 / 200 = 90%.',
            'options' => [
                'A' => '85%',
                'B' => '90%',
                'C' => '92%',
                'D' => '95%'
            ]
        ]
    ],
    27 => [
        'en' => [
            'question' => 'During the absolute refractory period of a neuronal action potential, a second action potential cannot be elicited. Which mechanism primarily accounts for this phenomenon?',
            'solution' => 'Inactivation of voltage-gated sodium (Na+) channels prevents generation of another action potential.',
            'options' => [
                'A' => 'Inactivation of voltage-gated Na+ channels',
                'B' => 'Opening of voltage-gated K+ channels',
                'C' => 'Closure of Cl- channels',
                'D' => 'Activation of Ca2+ channels'
            ]
        ],
        'hi' => [
            'question' => 'न्यूरोनल एक्शन पोटेंशियल के एब्सोल्यूट रिफ्रैक्टरी पीरियड के दौरान दूसरा एक्शन पोटेंशियल उत्पन्न नहीं हो सकता। इसके लिए कौन सा तंत्र प्राथमिक रूप से उत्तरदायी है?',
            'solution' => 'वोल्टेज-गेटेड सोडियम (Na+) चैनलों का निष्क्रिय होना (Inactivation) प्राथमिक कारण है।',
            'options' => [
                'A' => 'वोल्टेज-गेटेड Na+ चैनलों का निष्क्रिय होना',
                'B' => 'वोल्टेज-गेटेड K+ चैनलों का खुलना',
                'C' => 'Cl- चैनलों का बंद होना',
                'D' => 'Ca2+ चैनलों का सक्रिय होना'
            ]
        ]
    ],
    28 => [
        'en' => [
            'question' => 'A 6-year-old child presents with severe photosensitivity, freckling, and early skin neoplasms on sun-exposed areas (Xeroderma Pigmentosum). Which DNA repair mechanism is defective?',
            'solution' => 'Xeroderma Pigmentosum is caused by a defect in Nucleotide Excision Repair (NER).',
            'options' => [
                'A' => 'Nucleotide Excision Repair (NER)',
                'B' => 'Base Excision Repair (BER)',
                'C' => 'Mismatch Repair (MMR)',
                'D' => 'Homologous Recombination'
            ]
        ],
        'hi' => [
            'question' => 'धूप के संपर्क में आने से गंभीर फोटोसेंसिटिविटी और त्वचा नियोप्लाज्म से पीड़ित जेरोडर्मा पिगमेंटोसम (Xeroderma Pigmentosum) में कौन सा डीएनए रिपेयर तंत्र दोषपूर्ण होता है?',
            'solution' => 'जेरोडर्मा पिगमेंटोसम न्यूक्लियोटाइड एक्सीशन रिपेयर (NER) में दोष के कारण होता है।',
            'options' => [
                'A' => 'न्यूक्लियोटाइड एक्सीशन रिपेयर (NER)',
                'B' => 'बेस एक्सीशन रिपेयर (BER)',
                'C' => 'मिसमैच रिपेयर (MMR)',
                'D' => 'होमोलॉगस रीकॉम्बिनेशन'
            ]
        ]
    ]
];

echo "Starting Bilingual Database Population...\n";

foreach ($bilingualData as $qid => $data) {
    // 1. English Translation
    $db->prepare("
        INSERT INTO question_translations (question_id, language, question_text, solution_text, shortcut_text)
        VALUES (?, 'en', ?, ?, 'Shortcut')
        ON DUPLICATE KEY UPDATE question_text = VALUES(question_text), solution_text = VALUES(solution_text)
    ")->execute([$qid, $data['en']['question'], $data['en']['solution']]);

    // 2. Hindi Translation
    $db->prepare("
        INSERT INTO question_translations (question_id, language, question_text, solution_text, shortcut_text)
        VALUES (?, 'hi', ?, ?, 'शॉर्टकट')
        ON DUPLICATE KEY UPDATE question_text = VALUES(question_text), solution_text = VALUES(solution_text)
    ")->execute([$qid, $data['hi']['question'], $data['hi']['solution']]);

    // 3. Options for English & Hindi
    // Retrieve correct options mapping
    $existingOpts = $db->query("SELECT option_key, is_correct FROM question_options WHERE question_id = $qid AND language = 'en'")->fetchAll(PDO::FETCH_KEY_PAIR);

    foreach (['A', 'B', 'C', 'D'] as $optKey) {
        $isCorr = $existingOpts[$optKey] ?? ($optKey === 'A' ? 1 : 0);
        $enText = $data['en']['options'][$optKey] ?? "Option $optKey";
        $hiText = $data['hi']['options'][$optKey] ?? "विकल्प $optKey";

        // Upsert English Option
        $chkEn = $db->prepare("SELECT id FROM question_options WHERE question_id = ? AND option_key = ? AND language = 'en'");
        $chkEn->execute([$qid, $optKey]);
        if ($chkEn->fetch()) {
            $db->prepare("UPDATE question_options SET option_text = ?, is_correct = ? WHERE question_id = ? AND option_key = ? AND language = 'en'")
               ->execute([$enText, $isCorr, $qid, $optKey]);
        } else {
            $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)")
               ->execute([$qid, $optKey, $enText, $isCorr]);
        }

        // Upsert Hindi Option
        $chkHi = $db->prepare("SELECT id FROM question_options WHERE question_id = ? AND option_key = ? AND language = 'hi'");
        $chkHi->execute([$qid, $optKey]);
        if ($chkHi->fetch()) {
            $db->prepare("UPDATE question_options SET option_text = ?, is_correct = ? WHERE question_id = ? AND option_key = ? AND language = 'hi'")
               ->execute([$hiText, $isCorr, $qid, $optKey]);
        } else {
            $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'hi', ?, ?)")
               ->execute([$qid, $optKey, $hiText, $isCorr]);
        }
    }
    echo "  ✓ Question #$qid populated in English and Hindi\n";
}

echo "Bilingual population successfully completed!\n";
