-- Obtainable marks per attempt.
--
-- Raw marks are not comparable between papers: a 5-question practice set and a
-- 100-question mock produce scores on completely different scales, so a global
-- leaderboard ordered by raw score ranked a candidate who answered everything
-- correctly below someone who sat a longer paper. Recording what each attempt
-- was out of lets rankings and scorecards work in percentage terms.
--
-- Randomised attempts carry their own paper in attempt_questions; fixed papers
-- share one question set in test_questions. Both are covered by the backfill.
ALTER TABLE test_attempts
    ADD COLUMN max_score DECIMAL(8,2) NULL DEFAULT NULL AFTER score;

-- Backfill: randomised papers first.
UPDATE test_attempts att
JOIN (
    SELECT attempt_id, SUM(positive_marks) AS total
    FROM attempt_questions
    GROUP BY attempt_id
) aq ON aq.attempt_id = att.id
SET att.max_score = aq.total
WHERE att.max_score IS NULL AND aq.total > 0;

-- Then fixed papers, for attempts with no per-attempt question rows.
UPDATE test_attempts att
JOIN (
    SELECT test_id, SUM(positive_marks) AS total
    FROM test_questions
    GROUP BY test_id
) tq ON tq.test_id = att.test_id
SET att.max_score = tq.total
WHERE att.max_score IS NULL AND tq.total > 0;

CREATE INDEX idx_attempts_eval_rank ON test_attempts (status, submitted_at);
