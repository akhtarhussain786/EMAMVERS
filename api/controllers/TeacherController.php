<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';
require_once __DIR__ . '/../utils/question_fingerprint.php';

/**
 * Teacher question authoring and management controller.
 *
 * Teachers are a distinct account type (users.user_type = 'teacher').
 * Everything a teacher submits lands with status='review' (or 'draft')
 * and is strictly invisible to students until an admin approves it.
 */
class TeacherController {

    /**
     * Resolves the teacher profile for the caller, or terminates.
     */
    private static function requireTeacher(&$db) {
        $auth = AuthMiddleware::getAuthenticatedUser('teacher');
        $userId = $auth['sub'];

        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT tp.*, u.full_name, u.email
            FROM teacher_profiles tp
            JOIN users u ON tp.user_id = u.id
            WHERE tp.user_id = ?
        ");
        $stmt->execute([$userId]);
        $profile = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$profile) {
            $uStmt = $db->prepare("SELECT id, full_name, user_type FROM users WHERE id = ?");
            $uStmt->execute([$userId]);
            $u = $uStmt->fetch(PDO::FETCH_ASSOC);
            if ($u && ($u['user_type'] === 'teacher' || $auth['type'] === 'teacher')) {
                $db->prepare("INSERT INTO teacher_profiles (user_id, display_name, status) VALUES (?, ?, 'active') ON DUPLICATE KEY UPDATE status = 'active'")
                   ->execute([$userId, $u['full_name'] ?: 'Teacher']);
                $stmt->execute([$userId]);
                $profile = $stmt->fetch(PDO::FETCH_ASSOC);
            }
        }

        if (!$profile) {
            Response::error('No teacher profile found for this account', 403);
        }
        if ($profile['status'] !== 'active') {
            Response::error('Your teacher account has been suspended. Please contact the administrator.', 403);
        }
        return $profile;
    }

    /** Subjects, chapters, and topics a teacher can file a question under. */
    public static function getTaxonomy() {
        $db = null;
        self::requireTeacher($db);

        $subjects = $db->query("SELECT id, name, code FROM subjects ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);

        $topics = $db->query("
            SELECT t.id, t.name, c.subject_id, c.name AS chapter_name, c.id AS chapter_id
            FROM topics t
            JOIN chapters c ON t.chapter_id = c.id
            ORDER BY c.subject_id ASC, t.name ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        $chapters = $db->query("SELECT id, subject_id, name FROM chapters ORDER BY subject_id ASC, name ASC")->fetchAll(PDO::FETCH_ASSOC);

        $bySubjectTopics = [];
        foreach ($topics as $t) {
            $bySubjectTopics[$t['subject_id']][] = $t;
        }

        $bySubjectChapters = [];
        foreach ($chapters as $c) {
            $bySubjectChapters[$c['subject_id']][] = $c;
        }

        foreach ($subjects as &$s) {
            $s['topics']   = $bySubjectTopics[$s['id']] ?? [];
            $s['chapters'] = $bySubjectChapters[$s['id']] ?? [];
        }
        unset($s);

        $exams = $db->query("
            SELECT e.id, e.title, ec.name AS category_name
            FROM exams e
            LEFT JOIN exam_categories ec ON e.category_id = ec.id
            WHERE e.status = 'active' ORDER BY e.title ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        Response::json([
            'subjects'     => $subjects,
            'exams'        => $exams,
            'difficulties' => ['easy', 'medium', 'hard'],
        ], 'Question taxonomy loaded');
    }

    /**
     * Submits a question for review or saves as a draft.
     * Also supports editing & resubmitting an existing question.
     */
    public static function submitQuestion() {
        $db = null;
        $profile = self::requireTeacher($db);

        $input = json_decode(file_get_contents('php://input'), true) ?: [];

        $questionId   = intval($input['id'] ?? ($input['question_id'] ?? 0));
        $subjectId    = intval($input['subject_id'] ?? 0);
        $chapterId    = !empty($input['chapter_id']) ? intval($input['chapter_id']) : null;
        $topicId      = !empty($input['topic_id']) ? intval($input['topic_id']) : null;
        $difficulty   = in_array($input['difficulty'] ?? '', ['easy','medium','hard'], true) ? $input['difficulty'] : 'medium';
        $marks         = floatval($input['marks'] ?? 2.00);
        $negativeMarks = floatval($input['negative_marks'] ?? 0.50);
        $questionText = trim($input['question_text'] ?? '');
        $explanation  = trim($input['explanation'] ?? ($input['solution_text'] ?? ''));
        $imageUrl     = trim($input['image_url'] ?? '');
        $options      = $input['options'] ?? [];
        $correctKey   = strtoupper(trim($input['correct_option'] ?? ''));
        $examIds      = array_values(array_unique(array_filter(array_map('intval', (array)($input['exam_ids'] ?? [])))));
        $isDraft      = !empty($input['is_draft']) || ($input['status'] ?? '') === 'draft';
        $targetStatus = $isDraft ? 'draft' : 'review';

        // ── Validation ───────────────────────────────────────────────────
        $errors = [];
        if (!$subjectId) $errors['subject_id'] = 'Select the subject this question belongs to';
        if ($questionText === '') $errors['question_text'] = 'Question text is required';
        if (mb_strlen($questionText) > 2000) $errors['question_text'] = 'Question text must be under 2000 characters';
        if ($explanation === '' && !$isDraft) $errors['explanation'] = 'An explanation is required so students learn from the answer';

        if (!is_array($options) || count($options) !== 4) {
            $errors['options'] = 'Exactly four options (A, B, C, D) are required';
        } else {
            $seen = [];
            foreach (['A','B','C','D'] as $i => $key) {
                $text = trim((string)($options[$i]['option_text'] ?? $options[$i] ?? ''));
                if ($text === '' && !$isDraft) {
                    $errors['options'] = "Option $key cannot be empty";
                    break;
                }
                $norm = mb_strtolower($text);
                if ($text !== '' && isset($seen[$norm])) {
                    $errors['options'] = "Options $seen[$norm] and $key are identical";
                    break;
                }
                $seen[$norm] = $key;
            }
        }

        if (!in_array($correctKey, ['A','B','C','D'], true) && !$isDraft) {
            $errors['correct_option'] = 'Mark which option (A, B, C or D) is correct';
        }

        if ($errors) {
            Response::json(null, 'Please correct the highlighted fields', 'error', 422, $errors);
            return;
        }

        // Subject check
        $sCheck = $db->prepare("SELECT 1 FROM subjects WHERE id = ?");
        $sCheck->execute([$subjectId]);
        if (!$sCheck->fetchColumn()) Response::error('Selected subject no longer exists', 422);

        // Ownership verification for edits
        $existingQuestion = null;
        if ($questionId > 0) {
            $ownStmt = $db->prepare("SELECT * FROM questions WHERE id = ?");
            $ownStmt->execute([$questionId]);
            $existingQuestion = $ownStmt->fetch(PDO::FETCH_ASSOC);

            if (!$existingQuestion) {
                Response::error('Question not found', 404);
            }
            if ($existingQuestion['author_user_id'] != $profile['user_id']) {
                Response::error('Unauthorized: You can only edit questions you authored', 403);
            }
            if ($existingQuestion['status'] === 'published') {
                Response::error('Approved questions cannot be edited directly. Please request changes from admin.', 403);
            }
        }

        // Format options
        $formattedOptions = [];
        $optionTexts = [];
        foreach (['A','B','C','D'] as $i => $key) {
            $text = trim((string)($options[$i]['option_text'] ?? $options[$i] ?? ''));
            $isCorr = ($key === $correctKey || !empty($options[$i]['is_correct'])) ? 1 : 0;
            $formattedOptions[] = ['option_key' => $key, 'option_text' => $text, 'is_correct' => $isCorr];
            $optionTexts[] = $text;
        }
        $optionsJson = json_encode($formattedOptions, JSON_UNESCAPED_UNICODE);

        // Hashes for duplicate checks
        $contentHash   = QuestionFingerprint::contentHash($questionText, $optionTexts);
        $structureHash = QuestionFingerprint::structureHash($questionText, $optionTexts);

        // Check duplicates if new question
        if ($questionId <= 0 && QuestionFingerprint::findDuplicate($db, $contentHash)) {
            Response::error('This question already exists in the bank', 409);
        }

        $db->beginTransaction();
        try {
            if ($questionId > 0) {
                // Update existing submission (resubmit or update draft)
                $upStmt = $db->prepare("
                    UPDATE questions
                    SET subject_id = ?, chapter_id = ?, topic_id = ?, image_url = ?,
                        difficulty = ?, marks = ?, negative_marks = ?, options_json = ?,
                        status = ?, content_hash = ?, structure_hash = ?, updated_at = NOW()
                    WHERE id = ? AND author_user_id = ?
                ");
                $upStmt->execute([
                    $subjectId, $chapterId ?: null, $topicId ?: null, $imageUrl ?: null,
                    $difficulty, $marks, $negativeMarks, $optionsJson,
                    $targetStatus, $contentHash, $structureHash, $questionId, $profile['user_id']
                ]);

                // Update translation
                $db->prepare("
                    INSERT INTO question_translations (question_id, language, question_text, solution_text)
                    VALUES (?, 'en', ?, ?)
                    ON DUPLICATE KEY UPDATE question_text = VALUES(question_text), solution_text = VALUES(solution_text)
                ")->execute([$questionId, $questionText, $explanation]);

                // Update options
                $db->prepare("DELETE FROM question_options WHERE question_id = ? AND language = 'en'")->execute([$questionId]);
                $optStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
                foreach ($formattedOptions as $fo) {
                    $optStmt->execute([$questionId, $fo['option_key'], $fo['option_text'], $fo['is_correct']]);
                }

                // If resubmitting from rejected or changes_requested, increment submitted count
                if ($targetStatus === 'review' && in_array($existingQuestion['status'], ['rejected', 'changes_requested', 'draft'], true)) {
                    $db->prepare("UPDATE teacher_profiles SET questions_submitted = questions_submitted + 1 WHERE user_id = ?")
                       ->execute([$profile['user_id']]);
                }

                $finalId = $questionId;
            } else {
                // Insert new question
                $qStmt = $db->prepare("
                    INSERT INTO questions (subject_id, chapter_id, topic_id, author_user_id, question_type,
                                          image_url, difficulty, marks, negative_marks, options_json, status,
                                          content_hash, structure_hash, created_at)
                    VALUES (?, ?, ?, ?, 'MCQ', ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                ");
                $qStmt->execute([
                    $subjectId, $chapterId ?: null, $topicId ?: null, $profile['user_id'],
                    $imageUrl ?: null, $difficulty, $marks, $negativeMarks, $optionsJson,
                    $targetStatus, $contentHash, $structureHash
                ]);
                $finalId = $db->lastInsertId();

                $db->prepare("
                    INSERT INTO question_translations (question_id, language, question_text, solution_text)
                    VALUES (?, 'en', ?, ?)
                ")->execute([$finalId, $questionText, $explanation]);

                $optStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
                foreach ($formattedOptions as $fo) {
                    $optStmt->execute([$finalId, $fo['option_key'], $fo['option_text'], $fo['is_correct']]);
                }

                if (!empty($examIds)) {
                    $link = $db->prepare("INSERT IGNORE INTO question_exams (question_id, exam_id) VALUES (?, ?)");
                    foreach ($examIds as $examId) $link->execute([$finalId, $examId]);
                }

                if ($targetStatus === 'review') {
                    $db->prepare("UPDATE teacher_profiles SET questions_submitted = questions_submitted + 1 WHERE user_id = ?")
                       ->execute([$profile['user_id']]);
                }
            }

            $db->commit();
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }

        $message = $targetStatus === 'draft'
            ? 'Question saved as draft successfully.'
            : ($questionId > 0 ? 'Question resubmitted for admin approval!' : 'Question submitted for review. It will go live once approved by admin.');

        Response::json([
            'question_id' => intval($finalId),
            'status'      => $targetStatus,
        ], $message, 'success', $questionId > 0 ? 200 : 201);
    }

    /** The teacher's own submissions, newest first, filterable by status. */
    public static function myQuestions() {
        $db = null;
        $profile = self::requireTeacher($db);

        $status = $_GET['status'] ?? '';
        $where  = ['q.author_user_id = ?'];
        $params = [$profile['user_id']];

        if (in_array($status, ['review','published','rejected','changes_requested','draft'], true)) {
            $where[] = 'q.status = ?';
            $params[] = $status;
        }
        $whereSql = implode(' AND ', $where);

        $stmt = $db->prepare("
            SELECT q.id, q.status, q.difficulty, q.image_url, q.marks, q.negative_marks,
                   q.rejection_reason, q.admin_comment, q.created_at, q.updated_at, q.reviewed_at,
                   q.subject_id, q.chapter_id, q.topic_id,
                   qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, c.name AS chapter_name, t.name AS topic_name
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN chapters c ON q.chapter_id = c.id
            LEFT JOIN topics t ON q.topic_id = t.id
            WHERE $whereSql
            ORDER BY q.id DESC
            LIMIT 200
        ");
        $stmt->execute($params);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if ($questions) {
            $ids = array_column($questions, 'id');
            $ph  = implode(',', array_fill(0, count($ids), '?'));
            $opt = $db->prepare("SELECT question_id, option_key, option_text, is_correct FROM question_options WHERE question_id IN ($ph) AND language='en' ORDER BY option_key");
            $opt->execute($ids);
            $byQ = [];
            foreach ($opt->fetchAll(PDO::FETCH_ASSOC) as $o) $byQ[$o['question_id']][] = $o;
            foreach ($questions as &$q) $q['options'] = $byQ[$q['id']] ?? [];
            unset($q);
        }

        // Live counts for tabs
        $cntStmt = $db->prepare("
            SELECT status, COUNT(*) as cnt 
            FROM questions 
            WHERE author_user_id = ? 
            GROUP BY status
        ");
        $cntStmt->execute([$profile['user_id']]);
        $countsMap = ['review' => 0, 'published' => 0, 'rejected' => 0, 'changes_requested' => 0, 'draft' => 0];
        foreach ($cntStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $countsMap[$row['status']] = intval($row['cnt']);
        }

        Response::json([
            'questions' => $questions,
            'counts'    => [
                'all'               => array_sum($countsMap),
                'pending'           => $countsMap['review'],
                'approved'          => $countsMap['published'],
                'changes_requested' => $countsMap['changes_requested'],
                'rejected'          => $countsMap['rejected'],
                'draft'             => $countsMap['draft'],
            ],
        ], 'Your submitted questions');
    }

    /** Secure Image Upload for Teachers. */
    public static function uploadImage() {
        $db = null;
        self::requireTeacher($db);

        if (empty($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
            Response::error('No image file uploaded', 400);
        }

        $file     = $_FILES['image'];
        $maxBytes = 5 * 1024 * 1024; // 5 MB
        if ($file['size'] > $maxBytes) Response::error('Image must be under 5 MB', 422);

        $allowedMimes = [
            'image/jpeg' => 'jpg',
            'image/png'  => 'png',
            'image/webp' => 'webp',
            'image/gif'  => 'gif'
        ];

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime  = $finfo->file($file['tmp_name']);
        if (!isset($allowedMimes[$mime])) {
            Response::error('Invalid image type. Allowed: JPG, PNG, WEBP, GIF', 422);
        }

        $filename = 'tq_' . time() . '_' . bin2hex(random_bytes(8)) . '.' . $allowedMimes[$mime];
        $destDir  = __DIR__ . '/../../uploads/questions';
        if (!is_dir($destDir)) mkdir($destDir, 0777, true);
        $destPath = $destDir . '/' . $filename;

        if (!move_uploaded_file($file['tmp_name'], $destPath)) {
            Response::error('Could not save uploaded image', 500);
        }

        $publicUrl = '/EXAMVERSE/uploads/questions/' . $filename;
        Response::json(['url' => $publicUrl], 'Image uploaded successfully');
    }

    /** Get single question detail for editing. */
    public static function getQuestionDetail($id) {
        $db = null;
        $profile = self::requireTeacher($db);

        $id = intval($id);
        $stmt = $db->prepare("
            SELECT q.*, qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, c.name AS chapter_name, t.name AS topic_name
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN chapters c ON q.chapter_id = c.id
            LEFT JOIN topics t ON q.topic_id = t.id
            WHERE q.id = ? AND q.author_user_id = ?
        ");
        $stmt->execute([$id, $profile['user_id']]);
        $q = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$q) Response::error('Question not found or unauthorized', 404);

        $optStmt = $db->prepare("SELECT option_key, option_text, is_correct FROM question_options WHERE question_id = ? AND language = 'en' ORDER BY option_key ASC");
        $optStmt->execute([$id]);
        $q['options'] = $optStmt->fetchAll(PDO::FETCH_ASSOC);

        Response::json($q, 'Question details loaded');
    }

    /** Headline figures for the teacher dashboard. */
    public static function dashboard() {
        $db = null;
        $profile = self::requireTeacher($db);

        $stmt = $db->prepare("
            SELECT q.status, COUNT(*) AS total
            FROM questions q WHERE q.author_user_id = ?
            GROUP BY q.status
        ");
        $stmt->execute([$profile['user_id']]);
        $byStatus = ['review' => 0, 'published' => 0, 'rejected' => 0, 'changes_requested' => 0, 'draft' => 0];
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) $byStatus[$row['status']] = intval($row['total']);

        $recent = $db->prepare("
            SELECT q.id, q.status, q.created_at, q.updated_at, qt.question_text, s.name AS subject_name,
                   q.rejection_reason, q.admin_comment
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            WHERE q.author_user_id = ?
            ORDER BY q.id DESC LIMIT 5
        ");
        $recent->execute([$profile['user_id']]);

        $totalReviewed = $byStatus['published'] + $byStatus['rejected'];

        Response::json([
            'teacher' => [
                'display_name'   => $profile['display_name'],
                'full_name'      => $profile['full_name'],
                'specialisation' => $profile['specialisation'],
            ],
            'stats' => [
                'pending_review'    => $byStatus['review'],
                'approved'          => $byStatus['published'],
                'changes_requested' => $byStatus['changes_requested'],
                'rejected'          => $byStatus['rejected'],
                'draft'             => $byStatus['draft'],
                'total'             => array_sum($byStatus),
                'approval_rate'     => $totalReviewed > 0
                    ? round(($byStatus['published'] / $totalReviewed) * 100, 1)
                    : null,
            ],
            'recent_submissions' => $recent->fetchAll(PDO::FETCH_ASSOC),
        ], 'Teacher dashboard loaded');
    }
}
