<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class FriendsController {
    /**
     * Matches the caller's address book against registered users.
     * The client sends SHA-256 hashes of normalised 10-digit numbers; raw
     * numbers never reach the server and are never returned.
     */
    public static function syncContacts() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        $hashes = isset($input['phone_hashes']) ? (array)$input['phone_hashes'] : [];

        // Keep only well-formed hashes and cap the batch size.
        $hashes = array_values(array_unique(array_filter(array_map(function ($h) {
            $h = strtolower(trim((string)$h));
            return preg_match('/^[a-f0-9]{64}$/', $h) ? $h : null;
        }, $hashes))));

        if (empty($hashes)) {
            Response::json(['matched_count' => 0, 'matched_friends' => []], 'No contacts provided');
        }
        if (count($hashes) > 2000) {
            $hashes = array_slice($hashes, 0, 2000);
        }

        $db = Database::getConnection();

        // Matched set-wise in SQL against a stored hash column, rather than
        // loading every user into PHP and hashing them per request.
        $ph = implode(',', array_fill(0, count($hashes), '?'));
        $stmt = $db->prepare("
            SELECT id, full_name, state_id
            FROM users
            WHERE status = 'active' AND id <> ? AND mobile_hash IN ($ph)
        ");
        $stmt->execute(array_merge([$userId], $hashes));
        $matched = $stmt->fetchAll();

        if (!empty($matched)) {
            $ins = $db->prepare("
                INSERT INTO user_contacts (user_id, contact_phone_hash, matched_user_id)
                VALUES (:uid, :hash, :mid)
                ON DUPLICATE KEY UPDATE matched_user_id = VALUES(matched_user_id)
            ");
            $hashStmt = $db->prepare("SELECT mobile_hash FROM users WHERE id = ?");
            foreach ($matched as $u) {
                $hashStmt->execute([$u['id']]);
                $ins->execute([
                    'uid'  => $userId,
                    'hash' => $hashStmt->fetchColumn(),
                    'mid'  => $u['id'],
                ]);
            }
        }

        // Only the display name is returned — never another user's phone number.
        $friends = array_map(function ($u) {
            return ['id' => intval($u['id']), 'full_name' => $u['full_name']];
        }, $matched);

        Response::json([
            'matched_count'   => count($friends),
            'matched_friends' => $friends,
        ], 'Contact discovery completed');
    }

    /**
     * Leaderboard across the caller's matched contacts, computed from real
     * evaluated attempts.
     */
    public static function getFriendsLeaderboard() {
        $auth = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $auth['sub'];

        $db = Database::getConnection();

        // Caller plus every distinct matched contact.
        $stmt = $db->prepare("
            SELECT DISTINCT u.id, u.full_name, s.name as state_name
            FROM user_contacts c
            JOIN users u ON c.matched_user_id = u.id
            LEFT JOIN states s ON u.state_id = s.id
            WHERE c.user_id = :userId AND u.status = 'active'
        ");
        $stmt->execute(['userId' => $userId]);
        $people = $stmt->fetchAll();

        $stmtMe = $db->prepare("SELECT u.id, u.full_name, s.name as state_name FROM users u LEFT JOIN states s ON u.state_id = s.id WHERE u.id = :userId");
        $stmtMe->execute(['userId' => $userId]);
        $me = $stmtMe->fetch();
        if ($me) $people[] = $me;

        // De-duplicate by id in case the caller also appears as a contact.
        $byId = [];
        foreach ($people as $p) $byId[$p['id']] = $p;
        if (empty($byId)) {
            Response::json(['friends_rank' => 1, 'total_friends' => 0, 'leaderboard' => []], 'No friends found yet');
        }

        $ids = array_keys($byId);
        $ph  = implode(',', array_fill(0, count($ids), '?'));

        // Real aggregates: total marks scored, questions answered, accuracy.
        $statsStmt = $db->prepare("
            SELECT att.user_id,
                   COALESCE(SUM(att.score), 0)              AS total_score,
                   COALESCE(SUM(att.correct_count), 0)      AS solved_questions,
                   COALESCE(SUM(att.correct_count), 0)      AS total_correct,
                   COALESCE(SUM(att.correct_count + att.wrong_count), 0) AS total_attempted,
                   COUNT(*)                                 AS tests_taken
            FROM test_attempts att
            WHERE att.status = 'evaluated' AND att.user_id IN ($ph)
            GROUP BY att.user_id
        ");
        $statsStmt->execute($ids);
        $stats = [];
        foreach ($statsStmt->fetchAll() as $row) {
            $stats[$row['user_id']] = $row;
        }

        $leaderboard = [];
        foreach ($byId as $id => $person) {
            $st = $stats[$id] ?? null;
            $attempted = $st ? intval($st['total_attempted']) : 0;
            $correct   = $st ? intval($st['total_correct']) : 0;

            $leaderboard[] = [
                'user_id'          => intval($id),
                'full_name'        => $person['full_name'] . ($id == $userId ? ' (You)' : ''),
                'is_me'            => $id == $userId,
                'state_name'       => $person['state_name'],
                'score'            => $st ? round(floatval($st['total_score']), 2) : 0.0,
                'solved_questions' => $st ? intval($st['solved_questions']) : 0,
                'tests_taken'      => $st ? intval($st['tests_taken']) : 0,
                'accuracy'         => $attempted > 0 ? round(($correct / $attempted) * 100, 1) : 0.0,
                // XP is a presentation figure derived from real marks scored.
                'xp'               => $st ? intval(round(floatval($st['total_score']) * 10)) : 0,
            ];
        }

        usort($leaderboard, function ($a, $b) {
            return [$b['score'], $b['accuracy']] <=> [$a['score'], $a['accuracy']];
        });

        $myRank = 1;
        foreach ($leaderboard as $idx => &$item) {
            $item['rank'] = $idx + 1;
            if ($item['is_me']) $myRank = $item['rank'];
        }
        unset($item);

        Response::json([
            'friends_rank'  => $myRank,
            'total_friends' => count($leaderboard) - 1,
            'leaderboard'   => $leaderboard,
        ], 'Friends leaderboard loaded successfully');
    }
}
