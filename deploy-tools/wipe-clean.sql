-- ==========================================================
-- COMPLETE WORKER & BUYER DATA CLEAN SCRIPT FOR MYSQL
-- Database: task_platform
-- Preserves: Admins, Service Catalog, Service Pricing, System Settings
-- ==========================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Wipe Task Submissions, Proofs & Audit Logs
TRUNCATE TABLE task_submissions;
TRUNCATE TABLE audit_logs;
TRUNCATE TABLE files;

-- 2. Wipe Tasks, Units, Jobs & Assignments
TRUNCATE TABLE tasks;
TRUNCATE TABLE task_assignments;
TRUNCATE TABLE task_generation_jobs;
TRUNCATE TABLE order_units;
TRUNCATE TABLE campaign_worker_participation;

-- 3. Wipe Orders (Campaigns)
TRUNCATE TABLE orders;

-- 4. Wipe Worker Data (Scores, KYC, Profiles, Earnings, Withdrawals)
TRUNCATE TABLE worker_scores;
TRUNCATE TABLE workers;
TRUNCATE TABLE kyc_profiles;
TRUNCATE TABLE earnings;
TRUNCATE TABLE withdrawals;
TRUNCATE TABLE ratings;
TRUNCATE TABLE notifications;

-- 5. Wipe Transactions & Payment Records
TRUNCATE TABLE wallet_transactions;
TRUNCATE TABLE payment_transactions;
TRUNCATE TABLE payment_methods;

-- 6. Wipe Non-Admin Wallets & Reset Admin Wallets to 0.00
DELETE FROM wallets WHERE user_id NOT IN (SELECT id FROM users WHERE role IN ('SUPER_ADMIN', 'ADMIN'));
UPDATE wallets SET available_balance = 0.00, reserved_balance = 0.00;

-- 7. Wipe All Worker and Buyer Users (Preserve Super Admins & Admins)
DELETE FROM users WHERE role NOT IN ('SUPER_ADMIN', 'ADMIN');

SET FOREIGN_KEY_CHECKS = 1;
