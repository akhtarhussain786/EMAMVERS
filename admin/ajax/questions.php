<?php
/**
 * Admin AJAX: Question Management CRUD, filters, and image upload.
 * URL: /EXAMVERSE/admin/ajax/questions.php?action=...
 * Auth: PHP session + CSRF (_guard.php)
 */
require_once __DIR__ . '/_guard.php';
require_once __DIR__ . '/../../api/config/db.php';
require_once __DIR__ . '/../../api/utils/question_fingerprint.php';

$db      = Database::getConnection();
$action  = $_GET['action'] ?? '';
$adminId = $_SESSION['admin_user']['id'] ?? 1;

switch ($action) {

    // ── TAXONOMY FOR SELECT DROPDOWNS ────────────────────────────────────
    case 'taxonomy':
        $categories = $db->query("SELECT id, name, slug FROM exam_categories WHERE status='active' ORDER BY sort_order ASC, name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $exams      = $db->query("SELECT id, category_id, title FROM exams WHERE status='active' ORDER BY title ASC")->fetchAll(PDO::FETCH_ASSOC);
        $subjects   = $db->query("SELECT id, name, code FROM subjects ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $chapters   = $db->query("SELECT id, subject_id, name FROM chapters ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $topics     = $db->query("SELECT id, chapter_id, name FROM topics ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);

        ajaxOk([
            'categories' => $categories,
            'exams'      => $exams,
            'subjects'   => $subjects,
            'chapters'   => $chapters,
            'topics'     => $topics
        ], 'Taxonomy loaded');
        break;

    // ── LIST QUESTIONS WITH SEARCH, FILTERS & PAGINATION ──────────────────
    case 'list':
        $search     = trim($_GET['search'] ?? '');
        $subjectId  = intval($_GET['subject_id'] ?? 0);
        $chapterId  = intval($_GET['chapter_id'] ?? 0);
        $topicId    = intval($_GET['topic_id'] ?? 0);
        $categoryId = intval($_GET['category_id'] ?? 0);
        $difficulty = trim($_GET['difficulty'] ?? '');
        $type       = trim($_GET['type'] ?? '');
        $status     = trim($_GET['status'] ?? '');
        $authorType = trim($_GET['author_type'] ?? ''); // 'admin', 'teacher'
        $page       = max(1, intval($_GET['page'] ?? 1));
        $limit      = min(100, max(5, intval($_GET['limit'] ?? 20)));
        $offset     = ($page - 1) * $limit;

        $where  = ['1=1'];
        $params = [];

        if ($search !== '') {
            $where[] = '(qt.question_text LIKE ? OR q.id = ?)';
            $params[] = '%' . $search . '%';
            $params[] = intval(preg_replace('/[^0-9]/', '', $search) ?: 0);
        }
        if ($subjectId > 0) {
            $where[] = 'q.subject_id = ?';
            $params[] = $subjectId;
        }
        if ($chapterId > 0) {
            $where[] = 'q.chapter_id = ?';
            $params[] = $chapterId;
        }
        if ($topicId > 0) {
            $where[] = 'q.topic_id = ?';
            $params[] = $topicId;
        }
        if ($categoryId > 0) {
            $where[] = 'EXISTS (SELECT 1 FROM question_exams qe JOIN exams e ON qe.exam_id = e.id WHERE qe.question_id = q.id AND e.category_id = ?)';
            $params[] = $categoryId;
        }
        if ($difficulty !== '' && in_array($difficulty, ['easy', 'medium', 'hard'], true)) {
            $where[] = 'q.difficulty = ?';
            $params[] = $difficulty;
        }
        if ($type !== '' && in_array($type, ['MCQ', 'TRUE_FALSE', 'DESCRIPTIVE', 'NUMERICAL'], true)) {
            $where[] = 'q.question_type = ?';
            $params[] = $type;
        }
        if ($status !== '' && in_array($status, ['published', 'draft', 'review', 'changes_requested', 'rejected'], true)) {
            $where[] = 'q.status = ?';
            $params[] = $status;
        }
        if ($authorType === 'admin') {
            $where[] = 'q.author_user_id IS NULL';
        } elseif ($authorType === 'teacher') {
            $where[] = 'q.author_user_id IS NOT NULL';
        }

        $whereSql = implode(' AND ', $where);

        // Count total
        $countStmt = $db->prepare("
            SELECT COUNT(DISTINCT q.id)
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            WHERE $whereSql
        ");
        $countStmt->execute($params);
        $total = intval($countStmt->fetchColumn());

        // Select items
        $stmt = $db->prepare("
            SELECT q.id, q.subject_id, q.chapter_id, q.topic_id, q.author_user_id, q.created_by_admin_id,
                   q.question_type, q.image_url, q.difficulty, q.marks, q.negative_marks, q.status,
                   q.created_at, q.updated_at, q.rejection_reason, q.admin_comment,
                   qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, c.name AS chapter_name, t.name AS topic_name,
                   u.full_name AS teacher_name, tp.display_name AS teacher_display_name,
                   adm.full_name AS admin_creator_name
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN chapters c ON q.chapter_id = c.id
            LEFT JOIN topics t ON q.topic_id = t.id
            LEFT JOIN users u ON q.author_user_id = u.id
            LEFT JOIN teacher_profiles tp ON tp.user_id = q.author_user_id
            LEFT JOIN admins adm ON q.created_by_admin_id = adm.id
            WHERE $whereSql
            ORDER BY q.id DESC
            LIMIT $limit OFFSET $offset
        ");
        $stmt->execute($params);
        $questions = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch options for these questions
        if (!empty($questions)) {
            $ids = array_column($questions, 'id');
            $ph = implode(',', array_fill(0, count($ids), '?'));
            $optStmt = $db->prepare("
                SELECT question_id, option_key, option_text, is_correct
                FROM question_options
                WHERE question_id IN ($ph) AND language = 'en'
                ORDER BY option_key ASC
            ");
            $optStmt->execute($ids);
            $optionsMap = [];
            foreach ($optStmt->fetchAll(PDO::FETCH_ASSOC) as $opt) {
                $optionsMap[$opt['question_id']][] = $opt;
            }

            // Also fetch linked exams
            $examStmt = $db->prepare("
                SELECT qe.question_id, e.id AS exam_id, e.title AS exam_title
                FROM question_exams qe
                JOIN exams e ON qe.exam_id = e.id
                WHERE qe.question_id IN ($ph)
            ");
            $examStmt->execute($ids);
            $examsMap = [];
            foreach ($examStmt->fetchAll(PDO::FETCH_ASSOC) as $ex) {
                $examsMap[$ex['question_id']][] = $ex;
            }

            foreach ($questions as &$q) {
                $q['options'] = $optionsMap[$q['id']] ?? [];
                $q['exams']   = $examsMap[$q['id']] ?? [];
                // Calculate correct_answer string for quick display
                $corr = [];
                foreach ($q['options'] as $o) {
                    if (!empty($o['is_correct'])) $corr[] = $o['option_key'];
                }
                $q['correct_answer'] = implode(', ', $corr);
            }
            unset($q);
        }

        // Aggregate statistics for quick counter tabs
        $stats = [
            'total'             => intval($db->query("SELECT COUNT(*) FROM questions")->fetchColumn()),
            'published'         => intval($db->query("SELECT COUNT(*) FROM questions WHERE status='published'")->fetchColumn()),
            'draft'             => intval($db->query("SELECT COUNT(*) FROM questions WHERE status='draft'")->fetchColumn()),
            'review'            => intval($db->query("SELECT COUNT(*) FROM questions WHERE status='review'")->fetchColumn()),
            'changes_requested' => intval($db->query("SELECT COUNT(*) FROM questions WHERE status='changes_requested'")->fetchColumn()),
            'rejected'          => intval($db->query("SELECT COUNT(*) FROM questions WHERE status='rejected'")->fetchColumn()),
        ];

        ajaxOk([
            'questions' => $questions,
            'total'     => $total,
            'page'      => $page,
            'limit'     => $limit,
            'pages'     => ceil($total / $limit) ?: 1,
            'stats'     => $stats,
        ], 'Questions loaded');
        break;

    // ── GET SINGLE QUESTION ──────────────────────────────────────────────
    case 'get':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('Question ID required', 422);

        $stmt = $db->prepare("
            SELECT q.*, qt.question_text, qt.solution_text AS explanation,
                   s.name AS subject_name, c.name AS chapter_name, t.name AS topic_name
            FROM questions q
            LEFT JOIN question_translations qt ON q.id = qt.question_id AND qt.language = 'en'
            LEFT JOIN subjects s ON q.subject_id = s.id
            LEFT JOIN chapters c ON q.chapter_id = c.id
            LEFT JOIN topics t ON q.topic_id = t.id
            WHERE q.id = ?
        ");
        $stmt->execute([$id]);
        $question = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$question) ajaxErr('Question not found', 404);

        $optStmt = $db->prepare("SELECT option_key, option_text, is_correct FROM question_options WHERE question_id = ? AND language = 'en' ORDER BY option_key ASC");
        $optStmt->execute([$id]);
        $question['options'] = $optStmt->fetchAll(PDO::FETCH_ASSOC);

        $examStmt = $db->prepare("SELECT exam_id FROM question_exams WHERE question_id = ?");
        $examStmt->execute([$id]);
        $question['exam_ids'] = $examStmt->fetchAll(PDO::FETCH_COLUMN);

        ajaxOk($question, 'Question details loaded');
        break;

    // ── SAVE (CREATE OR UPDATE) QUESTION ────────────────────────────────
    case 'save':
        $body = getBody();

        $id            = intval($body['id'] ?? 0);
        $subjectId     = intval($body['subject_id'] ?? 0);
        $chapterId     = !empty($body['chapter_id']) ? intval($body['chapter_id']) : null;
        $topicId       = !empty($body['topic_id']) ? intval($body['topic_id']) : null;
        $questionType  = in_array($body['question_type'] ?? '', ['MCQ', 'TRUE_FALSE', 'DESCRIPTIVE', 'NUMERICAL'], true) ? $body['question_type'] : 'MCQ';
        $difficulty    = in_array($body['difficulty'] ?? '', ['easy', 'medium', 'hard'], true) ? $body['difficulty'] : 'medium';
        $marks         = floatval($body['marks'] ?? 1.00);
        $negativeMarks = floatval($body['negative_marks'] ?? 0.00);
        $questionText  = trim($body['question_text'] ?? '');
        $explanation   = trim($body['explanation'] ?? ($body['solution_text'] ?? ''));
        $imageUrl      = trim($body['image_url'] ?? '');
        $status        = in_array($body['status'] ?? '', ['draft', 'published', 'review', 'changes_requested', 'rejected'], true) ? $body['status'] : 'published';
        $options       = $body['options'] ?? [];
        $correctOption = strtoupper(trim($body['correct_option'] ?? ''));
        $examIds       = array_values(array_unique(array_filter(array_map('intval', (array)($body['exam_ids'] ?? [])))));

        if ($subjectId <= 0) ajaxErr('Subject is required', 422);
        if ($questionText === '') ajaxErr('Question text is required', 422);

        // Validation by Question Type
        if ($questionType === 'MCQ') {
            if (!is_array($options) || count($options) < 2) {
                ajaxErr('At least 2 options are required for MCQ', 422);
            }
            if (!in_array($correctOption, ['A', 'B', 'C', 'D'], true)) {
                ajaxErr('Please select a valid correct option (A, B, C, or D)', 422);
            }
        } elseif ($questionType === 'TRUE_FALSE') {
            if (!in_array($correctOption, ['A', 'B', 'TRUE', 'FALSE'], true)) {
                ajaxErr('Please select True or False as correct answer', 422);
            }
            $options = [
                ['option_key' => 'A', 'option_text' => 'True', 'is_correct' => in_array($correctOption, ['A', 'TRUE'], true) ? 1 : 0],
                ['option_key' => 'B', 'option_text' => 'False', 'is_correct' => in_array($correctOption, ['B', 'FALSE'], true) ? 1 : 0]
            ];
            $correctOption = in_array($correctOption, ['A', 'TRUE'], true) ? 'A' : 'B';
        }

        // Format options array
        $formattedOptions = [];
        $optionTexts = [];
        if ($questionType === 'MCQ') {
            $keys = ['A', 'B', 'C', 'D'];
            foreach ($options as $i => $opt) {
                if ($i >= 4) break;
                $k = $opt['option_key'] ?? $keys[$i];
                $txt = trim((string)($opt['option_text'] ?? ''));
                if ($txt === '') ajaxErr("Option $k text cannot be empty", 422);
                $isCorr = ($k === $correctOption || !empty($opt['is_correct'])) ? 1 : 0;
                $formattedOptions[] = ['option_key' => $k, 'option_text' => $txt, 'is_correct' => $isCorr];
                $optionTexts[] = $txt;
            }
        } elseif ($questionType === 'TRUE_FALSE') {
            $formattedOptions = $options;
            $optionTexts = ['True', 'False'];
        }

        $optionsJson = !empty($formattedOptions) ? json_encode($formattedOptions, JSON_UNESCAPED_UNICODE) : null;
        $contentHash   = QuestionFingerprint::contentHash($questionText, $optionTexts);
        $structureHash = QuestionFingerprint::structureHash($questionText, $optionTexts);

        $db->beginTransaction();
        try {
            if ($id > 0) {
                // Update
                $stmt = $db->prepare("
                    UPDATE questions 
                    SET subject_id = ?, chapter_id = ?, topic_id = ?, question_type = ?,
                        image_url = ?, difficulty = ?, marks = ?, negative_marks = ?,
                        options_json = ?, status = ?, content_hash = ?, structure_hash = ?,
                        updated_at = NOW()
                    WHERE id = ?
                ");
                $stmt->execute([
                    $subjectId, $chapterId, $topicId, $questionType,
                    $imageUrl ?: null, $difficulty, $marks, $negativeMarks,
                    $optionsJson, $status, $contentHash, $structureHash, $id
                ]);

                // Update translation
                $db->prepare("
                    INSERT INTO question_translations (question_id, language, question_text, solution_text)
                    VALUES (?, 'en', ?, ?)
                    ON DUPLICATE KEY UPDATE question_text = VALUES(question_text), solution_text = VALUES(solution_text)
                ")->execute([$id, $questionText, $explanation]);

                // Update options
                $db->prepare("DELETE FROM question_options WHERE question_id = ? AND language = 'en'")->execute([$id]);
                $optStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
                foreach ($formattedOptions as $fo) {
                    $optStmt->execute([$id, $fo['option_key'], $fo['option_text'], $fo['is_correct']]);
                }

                // Update exam links
                $db->prepare("DELETE FROM question_exams WHERE question_id = ?")->execute([$id]);
                if (!empty($examIds)) {
                    $exStmt = $db->prepare("INSERT IGNORE INTO question_exams (question_id, exam_id) VALUES (?, ?)");
                    foreach ($examIds as $eid) $exStmt->execute([$id, $eid]);
                }

                auditLog($db, $adminId, 'UPDATE_QUESTION', $id, "Admin updated question #$id ($status)");
                $questionId = $id;
            } else {
                // Create New
                $stmt = $db->prepare("
                    INSERT INTO questions (subject_id, chapter_id, topic_id, created_by_admin_id, question_type,
                                          image_url, difficulty, marks, negative_marks, options_json, status,
                                          content_hash, structure_hash, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                ");
                $stmt->execute([
                    $subjectId, $chapterId, $topicId, $adminId, $questionType,
                    $imageUrl ?: null, $difficulty, $marks, $negativeMarks, $optionsJson, $status,
                    $contentHash, $structureHash
                ]);
                $questionId = $db->lastInsertId();

                // Translation
                $db->prepare("
                    INSERT INTO question_translations (question_id, language, question_text, solution_text)
                    VALUES (?, 'en', ?, ?)
                ")->execute([$questionId, $questionText, $explanation]);

                // Options
                $optStmt = $db->prepare("INSERT INTO question_options (question_id, option_key, language, option_text, is_correct) VALUES (?, ?, 'en', ?, ?)");
                foreach ($formattedOptions as $fo) {
                    $optStmt->execute([$questionId, $fo['option_key'], $fo['option_text'], $fo['is_correct']]);
                }

                // Exam links
                if (!empty($examIds)) {
                    $exStmt = $db->prepare("INSERT IGNORE INTO question_exams (question_id, exam_id) VALUES (?, ?)");
                    foreach ($examIds as $eid) $exStmt->execute([$questionId, $eid]);
                }

                auditLog($db, $adminId, 'CREATE_QUESTION', $questionId, "Admin created question #$questionId ($status)");
            }

            $db->commit();
            ajaxOk([
                'question_id' => intval($questionId),
                'status'      => $status
            ], $id > 0 ? 'Question updated successfully' : 'Question created and saved successfully');
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('Admin question save failed: ' . $e->getMessage());
            ajaxErr('Failed to save question: ' . $e->getMessage(), 500);
        }
        break;

    // ── TOGGLE PUBLISH / UNPUBLISH ──────────────────────────────────────
    case 'toggle_publish':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('Question ID required', 422);

        $q = $db->prepare("SELECT id, status FROM questions WHERE id = ?");
        $q->execute([$id]);
        $row = $q->fetch(PDO::FETCH_ASSOC);
        if (!$row) ajaxErr('Question not found', 404);

        $newStatus = ($row['status'] === 'published') ? 'draft' : 'published';
        $db->prepare("UPDATE questions SET status = ?, updated_at = NOW() WHERE id = ?")->execute([$newStatus, $id]);
        auditLog($db, $adminId, 'TOGGLE_PUBLISH', $id, "Admin toggled question #$id to $newStatus");

        ajaxOk(['id' => $id, 'status' => $newStatus], $newStatus === 'published' ? 'Question published successfully' : 'Question unpublished (moved to draft)');
        break;

    // ── DELETE QUESTION ─────────────────────────────────────────────────
    case 'delete':
        $id = intval($_GET['id'] ?? 0);
        if (!$id) ajaxErr('Question ID required', 422);

        $stmt = $db->prepare("SELECT id FROM questions WHERE id = ?");
        $stmt->execute([$id]);
        if (!$stmt->fetch()) ajaxErr('Question not found', 404);

        $db->beginTransaction();
        try {
            $db->prepare("DELETE FROM question_exams WHERE question_id = ?")->execute([$id]);
            $db->prepare("DELETE FROM question_options WHERE question_id = ?")->execute([$id]);
            $db->prepare("DELETE FROM question_translations WHERE question_id = ?")->execute([$id]);
            $db->prepare("DELETE FROM questions WHERE id = ?")->execute([$id]);

            auditLog($db, $adminId, 'DELETE_QUESTION', $id, "Admin deleted question #$id");
            $db->commit();
            ajaxOk(['id' => $id], 'Question deleted permanently');
        } catch (Throwable $e) {
            $db->rollBack();
            error_log('Admin delete question error: ' . $e->getMessage());
            ajaxErr('Failed to delete question', 500);
        }
        break;

    // ── SECURE IMAGE UPLOAD ─────────────────────────────────────────────
    case 'upload_image':
        if (empty($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
            ajaxErr('No image file uploaded or upload error occurred', 400);
        }

        $file     = $_FILES['image'];
        $maxBytes = 5 * 1024 * 1024; // 5 MB
        if ($file['size'] > $maxBytes) ajaxErr('Image must be under 5 MB', 422);

        $allowedMimes = [
            'image/jpeg' => 'jpg',
            'image/png'  => 'png',
            'image/webp' => 'webp',
            'image/gif'  => 'gif',
            'image/svg+xml' => 'svg'
        ];

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime  = $finfo->file($file['tmp_name']);
        if (!isset($allowedMimes[$mime])) {
            ajaxErr('Invalid image type. Allowed: JPG, PNG, WEBP, GIF, SVG', 422);
        }

        $ext = $allowedMimes[$mime];
        $filename = 'q_' . time() . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
        $destDir  = __DIR__ . '/../../uploads/questions';
        if (!is_dir($destDir)) mkdir($destDir, 0777, true);
        $destPath = $destDir . '/' . $filename;

        if (!move_uploaded_file($file['tmp_name'], $destPath)) {
            ajaxErr('Could not save uploaded image', 500);
        }

        $publicUrl = '/EXAMVERSE/uploads/questions/' . $filename;
        ajaxOk(['url' => $publicUrl], 'Image uploaded successfully');
        break;

    default:
        ajaxErr("Unsupported action: $action", 404);
}

