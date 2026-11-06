-- Baseline subscription plans.
--
-- These previously only existed as a side effect of an admin opening
-- admin/pages/subscriptions.php, so a fresh install served the app an empty
-- plans screen with nothing purchasable. Seeding them here makes the paid
-- tiers present from the moment the schema is built. Admins can still edit,
-- deactivate or add plans from the panel.
INSERT INTO subscription_plans (name, duration_days, price, description, is_active)
SELECT * FROM (
    SELECT 'Free Referral / Trial Pass' AS name, 30 AS duration_days, 0.00 AS price,
           'Complimentary 30-day access for new invited aspirants' AS description, 1 AS is_active
    UNION ALL SELECT 'Pro Monthly Pass', 30, 299.00,
           'Unlimited mock tests, AI Exam-Twin, step-by-step solutions & shortcut tricks', 1
    UNION ALL SELECT 'Pro Quarterly Sprint', 90, 699.00,
           'Complete tier access for 3 months with priority test series', 1
    UNION ALL SELECT 'ExamVerse Elite Annual', 365, 1999.00,
           'All-inclusive annual pass for all exams, pyqs, map learning & mentor notes', 1
) AS seed
WHERE NOT EXISTS (SELECT 1 FROM subscription_plans WHERE subscription_plans.name = seed.name);
