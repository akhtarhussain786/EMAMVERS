<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth.php';

class ChallengeController {
    public static function getChallenges() {
        $db = Database::getConnection();
        $challenges = $db->query("
            SELECT mc.*, e.title as exam_title, e.slug as exam_slug, t.id as test_id, t.title as test_title,
                   (SELECT COUNT(*) FROM challenge_registrations cr WHERE cr.challenge_id = mc.id) as total_registered
            FROM monthly_challenges mc
            JOIN exams e ON mc.exam_id = e.id
            JOIN tests t ON mc.test_id = t.id
            ORDER BY mc.id DESC
        ")->fetchAll();

        Response::json($challenges, 'Monthly challenges loaded');
    }

    public static function registerForChallenge($challengeId) {
        $authUser = AuthMiddleware::getAuthenticatedUser('student');
        $userId = $authUser['sub'];

        $db = Database::getConnection();
        $stmt = $db->prepare("
            INSERT INTO challenge_registrations (challenge_id, user_id) 
            VALUES (:cid, :uid)
            ON DUPLICATE KEY UPDATE registered_at = CURRENT_TIMESTAMP
        ");
        $stmt->execute(['cid' => $challengeId, 'uid' => $userId]);

        Response::json(['registered' => true], 'Successfully registered for Monthly Challenge');
    }

    public static function getLeaderboard($context = 'central') {
        $db = Database::getConnection();

        $userId = null;
        try {
            $authUser = AuthMiddleware::getAuthenticatedUser('student');
            $userId = $authUser['sub'];
        } catch (Exception $e) {
            $userId = null;
        }

        $stateId = isset($_GET['state_id']) ? intval($_GET['state_id']) : null;
        $testId = isset($_GET['test_id']) ? intval($_GET['test_id']) : null;
        $examId = isset($_GET['exam_id']) ? intval($_GET['exam_id']) : null;
        $context = strtolower(trim($context));

        $whereClauses = ["att.status = 'evaluated'"];
        $params = [];

        if ($testId) {
            $whereClauses[] = "att.test_id = :test_id";
            $params['test_id'] = $testId;
        }

        // Scoped with a subquery rather than a join on exams, so the cohort
        // count and single-candidate rank helpers can reuse these clauses
        // without carrying the board query's joins.
        if ($examId) {
            $whereClauses[] = "att.test_id IN (SELECT t2.id FROM tests t2 WHERE t2.exam_id = :exam_id)";
            $params['exam_id'] = $examId;
        }

        if ($context === 'state' && $stateId) {
            $whereClauses[] = "u.state_id = :state_id";
            $params['state_id'] = $stateId;
        }

        if ($context === 'today') {
            $whereClauses[] = "att.submitted_at >= CURDATE()";
        } elseif ($context === 'weekly') {
            $whereClauses[] = "att.submitted_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
        } elseif ($context === 'monthly') {
            $whereClauses[] = "att.submitted_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
        }

        $whereSql = implode(' AND ', $whereClauses);

        // One row per CANDIDATE, not per attempt: a student with five attempts
        // holds a single position, earned by their best attempt.
        $stmt = $db->prepare("
            SELECT * FROM (
                SELECT att.id as attempt_id, att.user_id, att.score, att.max_score,
                       att.accuracy_percentage, att.total_time_spent_seconds, att.submitted_at,
                       t.title as test_title, e.id as exam_id, e.title as exam_title,
                       u.full_name, u.avatar_url, s.name as state_name, q.name as qualification_name,
                       ROW_NUMBER() OVER (
                           PARTITION BY att.user_id
                           ORDER BY (att.score / NULLIF(att.max_score, 0)) DESC,
                                    att.max_score DESC,
                                    att.accuracy_percentage DESC,
                                    att.total_time_spent_seconds ASC, att.submitted_at ASC, att.id ASC
                       ) AS rn
                FROM test_attempts att
                JOIN users u ON att.user_id = u.id
                LEFT JOIN tests t ON att.test_id = t.id
                LEFT JOIN exams e ON t.exam_id = e.id
                LEFT JOIN states s ON u.state_id = s.id
                LEFT JOIN qualifications q ON u.qualification_id = q.id
                WHERE $whereSql
            ) best
            WHERE best.rn = 1
            ORDER BY (best.score / NULLIF(best.max_score, 0)) DESC,
                     best.max_score DESC,
                     best.accuracy_percentage DESC,
                     best.total_time_spent_seconds ASC, best.submitted_at ASC, best.attempt_id ASC
            LIMIT 100
        ");
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // A time-boxed board with no entries falls back to all-time, so a
        // candidate still sees real records rather than an empty screen.
        $usedFallback = false;
        $fallbackWhere = [];
        $fallbackParams = [];
        if (empty($rows) && in_array($context, ['today', 'weekly', 'monthly'])) {
            $usedFallback = true;
            $fallbackWhere = ["att.status = 'evaluated'"];
            $fallbackParams = [];
            if ($testId) {
                $fallbackWhere[] = "att.test_id = :test_id";
                $fallbackParams['test_id'] = $testId;
            }
            if ($examId) {
                $fallbackWhere[] = "att.test_id IN (SELECT t2.id FROM tests t2 WHERE t2.exam_id = :exam_id)";
                $fallbackParams['exam_id'] = $examId;
            }
            $fallbackSql = implode(' AND ', $fallbackWhere);
            $stmtFallback = $db->prepare("
                SELECT * FROM (
                    SELECT att.id as attempt_id, att.user_id, att.score, att.max_score,
                           att.accuracy_percentage, att.total_time_spent_seconds, att.submitted_at,
                           t.title as test_title, e.id as exam_id, e.title as exam_title,
                           u.full_name, u.avatar_url, s.name as state_name, q.name as qualification_name,
                           ROW_NUMBER() OVER (
                               PARTITION BY att.user_id
                               ORDER BY (att.score / NULLIF(att.max_score, 0)) DESC,
                                        att.max_score DESC,
                                        att.accuracy_percentage DESC,
                                        att.total_time_spent_seconds ASC, att.submitted_at ASC, att.id ASC
                           ) AS rn
                    FROM test_attempts att
                    JOIN users u ON att.user_id = u.id
                    LEFT JOIN tests t ON att.test_id = t.id
                    LEFT JOIN exams e ON t.exam_id = e.id
                    LEFT JOIN states s ON u.state_id = s.id
                    LEFT JOIN qualifications q ON u.qualification_id = q.id
                    WHERE $fallbackSql
                ) best
                WHERE best.rn = 1
                ORDER BY (best.score / NULLIF(best.max_score, 0)) DESC,
                         best.max_score DESC,
                         best.accuracy_percentage DESC,
                         best.total_time_spent_seconds ASC, best.submitted_at ASC, best.attempt_id ASC
                LIMIT 100
            ");
            $stmtFallback->execute($fallbackParams);
            $rows = $stmtFallback->fetchAll(PDO::FETCH_ASSOC);
        }

        $leaderboard = [];
        $myRank = 0;
        $myAccuracy = 0.0;

        foreach ($rows as $idx => $row) {
            $isMe = ($userId && intval($row['user_id']) === intval($userId));
            $rank = $idx + 1;
            $maxForRow = floatval($row['max_score']);
            if ($isMe && $myRank === 0) {
                $myRank = $rank;
                $myAccuracy = floatval($row['accuracy_percentage']);
            }

            $leaderboard[] = [
                'rank'                     => $rank,
                'user_id'                  => intval($row['user_id']),
                'attempt_id'               => intval($row['attempt_id']),
                'full_name'                => $row['full_name'] . ($isMe ? ' (You)' : ''),
                'avatar_url'               => $row['avatar_url'] ?? null,
                'is_me'                    => $isMe,
                'state_name'               => $row['state_name'] ?: 'National',
                'qualification_name'       => $row['qualification_name'] ?: '',
                'score'                    => round(floatval($row['score']), 1),
                'max_score'                => round(floatval($row['max_score']), 1),
                // The board is ordered on this, so the UI can show what the
                // position actually reflects rather than a bare mark total.
                'score_percentage'         => $maxForRow > 0
                                              ? round((floatval($row['score']) / $maxForRow) * 100, 1)
                                              : 0.0,
                'test_title'               => $row['test_title'] ?? '',
                'exam_id'                  => isset($row['exam_id']) ? intval($row['exam_id']) : null,
                'exam_title'               => $row['exam_title'] ?? '',
                'accuracy'                 => round(floatval($row['accuracy_percentage']), 1),
                'total_time_spent_seconds' => intval($row['total_time_spent_seconds']),
            ];
        }

        // The board is capped at 100 rows; the cohort size is not.
        if ($usedFallback) {
            $boardWhere  = $fallbackWhere;
            $boardParams = $fallbackParams;
        } else {
            $boardWhere  = $whereClauses;
            $boardParams = $params;
        }

        $totalRanked = self::countRankedCandidates($db, $boardWhere, $boardParams);

        // A candidate outside the visible top 100 still has a real standing.
        if ($myRank === 0 && $userId) {
            $myRank = self::resolveMyRank($db, $userId, $boardWhere, $boardParams, $myAccuracy);
        }

        $userRanking = [
            'current_rank'           => $myRank,
            'previous_rank'          => 0,
            'best_rank'              => 0,
            'percentile'             => 0.0,
            'total_questions_solved' => 0,
            'correct_answers'        => 0,
            'accuracy'               => $myAccuracy,
            'test_count'             => 0,
            'streak_days'            => 0,
            'xp_points'              => 0,
        ];

        if ($myRank > 0 && $totalRanked > 1) {
            $userRanking['percentile'] = round((($totalRanked - $myRank) / ($totalRanked - 1)) * 100, 1);
        } elseif ($myRank === 1 && $totalRanked === 1) {
            $userRanking['percentile'] = 100.0;
        }

        if ($userId) {
            $statStmt = $db->prepare("
                SELECT COUNT(*) as tests_count,
                       COALESCE(SUM(correct_count), 0) as correct_q,
                       COALESCE(SUM(correct_count + wrong_count), 0) as total_q,
                       COALESCE(SUM(score), 0) as total_score
                FROM test_attempts
                WHERE user_id = ? AND status = 'evaluated'
            ");
            $statStmt->execute([$userId]);
            $ustats = $statStmt->fetch(PDO::FETCH_ASSOC);
            if ($ustats && intval($ustats['tests_count']) > 0) {
                $tests = intval($ustats['tests_count']);
                $correct = intval($ustats['correct_q']);
                $totalQ = intval($ustats['total_q']);
                $acc = $totalQ > 0 ? round(($correct / $totalQ) * 100, 1) : 0.0;
                $userRanking['test_count'] = $tests;
                $userRanking['total_questions_solved'] = $totalQ;
                $userRanking['correct_answers'] = $correct;
                $userRanking['accuracy'] = $acc;
                $userRanking['xp_points'] = intval(round(floatval($ustats['total_score']) * 10));
            }

            // Real rank history: recomputeRanksForTest() stamps each attempt
            // with the candidate rank its owner held in that test.
            $histStmt = $db->prepare("
                SELECT central_rank
                FROM test_attempts
                WHERE user_id = ? AND status = 'evaluated' AND central_rank > 0
                ORDER BY submitted_at DESC, id DESC
            ");
            $histStmt->execute([$userId]);
            $history = array_map('intval', $histStmt->fetchAll(PDO::FETCH_COLUMN));
            if ($history) {
                $userRanking['best_rank'] = min($history);
                // The standing held before the most recent test.
                if (count($history) > 1) {
                    $userRanking['previous_rank'] = $history[1];
                }
            }

            $userRanking['streak_days'] = self::currentStreakDays($db, $userId);
        }

        Response::json([
            'context'        => $context,
            'exam_id'        => $examId,
            'test_id'        => $testId,
            'leaderboard'    => $leaderboard,
            'user_ranking'   => $userRanking,
            'total_ranked'   => $totalRanked,
            'tie_break_rule' => '1. Share of paper scored DESC, 2. Paper size DESC, 3. Accuracy DESC, 4. Time Spent ASC, 5. Submission Time ASC'
        ], 'Leaderboard loaded successfully');
    }

    /** Size of the ranked cohort (candidates, not attempts) for a board. */
    private static function countRankedCandidates($db, $whereClauses, $params) {
        $whereSql = implode(' AND ', $whereClauses);
        $sql = "
            SELECT COUNT(DISTINCT att.user_id)
            FROM test_attempts att
            JOIN users u ON att.user_id = u.id
            WHERE $whereSql
        ";
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        return intval($stmt->fetchColumn());
    }

    /**
     * Rank of one candidate across the whole cohort, for someone who fell
     * outside the 100 rows the board returns. Counts the candidates whose best
     * attempt beats this candidate's best on the same tie-break order.
     */
    private static function resolveMyRank($db, $userId, $whereClauses, $params, &$myAccuracy) {
        $whereSql = implode(' AND ', $whereClauses);

        $mineSql = "
            SELECT att.score, att.max_score, att.accuracy_percentage, att.total_time_spent_seconds, att.submitted_at, att.id
            FROM test_attempts att
            JOIN users u ON att.user_id = u.id
            WHERE $whereSql AND att.user_id = :me_id
            ORDER BY (att.score / NULLIF(att.max_score, 0)) DESC,
                     att.max_score DESC,
                     att.accuracy_percentage DESC,
                     att.total_time_spent_seconds ASC, att.submitted_at ASC, att.id ASC
            LIMIT 1
        ";
        $mineStmt = $db->prepare($mineSql);
        $mineStmt->execute(array_merge($params, ['me_id' => $userId]));
        $mine = $mineStmt->fetch(PDO::FETCH_ASSOC);
        if (!$mine) return 0;

        $myAccuracy = floatval($mine['accuracy_percentage']);

        // Compared as a share of the paper, matching how the board is ordered.
        $aheadSql = "
            SELECT COUNT(*) FROM (
                SELECT att.user_id,
                       MAX(att.score / NULLIF(att.max_score, 0)) AS best_ratio
                FROM test_attempts att
                JOIN users u ON att.user_id = u.id
                WHERE $whereSql AND att.user_id <> :me_id2
                GROUP BY att.user_id
                HAVING best_ratio > :my_ratio
            ) ahead
        ";
        $myMax   = floatval($mine['max_score'] ?? 0);
        $myRatio = $myMax > 0 ? floatval($mine['score']) / $myMax : 0.0;
        $aheadStmt = $db->prepare($aheadSql);
        $aheadStmt->execute(array_merge($params, [
            'me_id2'   => $userId,
            'my_ratio' => $myRatio,
        ]));
        return intval($aheadStmt->fetchColumn()) + 1;
    }

    /**
     * Consecutive days, ending today or yesterday, on which the candidate
     * submitted at least one evaluated attempt. Yesterday still counts so a
     * streak is not reported as broken before the day is over.
     */
    private static function currentStreakDays($db, $userId) {
        $stmt = $db->prepare("
            SELECT DISTINCT DATE(submitted_at) AS d
            FROM test_attempts
            WHERE user_id = ? AND status = 'evaluated' AND submitted_at IS NOT NULL
            ORDER BY d DESC
        ");
        $stmt->execute([$userId]);
        $days = $stmt->fetchAll(PDO::FETCH_COLUMN);
        if (!$days) return 0;

        $today     = new DateTimeImmutable('today');
        $firstDay  = new DateTimeImmutable($days[0]);
        $gap       = (int)$today->diff($firstDay)->days;
        if ($gap > 1) return 0;   // the streak has already lapsed

        $streak   = 1;
        $previous = $firstDay;
        for ($i = 1; $i < count($days); $i++) {
            $day = new DateTimeImmutable($days[$i]);
            if ((int)$previous->diff($day)->days === 1) {
                $streak++;
                $previous = $day;
            } else {
                break;
            }
        }
        return $streak;
    }
}
