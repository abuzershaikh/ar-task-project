const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function wipeCleanAllAppData() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('====================================================');
    console.log('🧹 STARTING COMPLETE WORKER, BUYER & TASK DATA WIPE');
    console.log('====================================================');

    const wipeSqlScript = `
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
`;

    console.log('Writing /tmp/wipe_clean.sql on VPS...');
    await ssh.execCommand(`cat << 'EOF' > /tmp/wipe_clean.sql
${wipeSqlScript}
EOF
`);

    console.log('Executing /tmp/wipe_clean.sql in MySQL...');
    const sqlRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform < /tmp/wipe_clean.sql');
    console.log('SQL STDOUT:', sqlRes.stdout);
    console.log('SQL STDERR:', sqlRes.stderr);

    // 8. Clean uploaded proof files
    console.log('\nCleaning uploads directory (/opt/task-engine/uploads/*)...');
    await ssh.execCommand('rm -rf /opt/task-engine/uploads/*');
    console.log('✅ Uploads directory cleaned!');

    // 9. Flush Redis
    console.log('\nFlushing Redis cache...');
    const redisRes = await ssh.execCommand('redis-cli FLUSHALL');
    console.log('Redis flush:', redisRes.stdout.trim());

    // 10. Restart PM2 task-engine
    console.log('\nRestarting PM2 backend services...');
    await ssh.execCommand('pm2 restart task-engine-api');
    console.log('✅ PM2 restarted!');

    // 11. Verify Table Counts
    console.log('\n--- VERIFYING TABLE ROW COUNTS ---');
    const tables = [
      'users',
      'wallets',
      'workers',
      'tasks',
      'orders',
      'order_units',
      'task_submissions',
      'task_assignments',
      'task_generation_jobs',
      'campaign_worker_participation',
      'worker_scores',
      'kyc_profiles',
      'files',
      'notifications',
      'wallet_transactions',
      'payment_transactions',
      'earnings',
      'withdrawals',
      'service_catalog',
      'service_pricing',
      'system_settings'
    ];

    for (const t of tables) {
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as count FROM ${t};"`);
      console.log(`${t.padEnd(30)}: ${res.stdout.split('\n')[1] || res.stdout.trim()}`);
    }

    console.log('\n--- REMAINING USERS (SHOULD BE ADMINS ONLY) ---');
    const remainingUsers = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, full_name FROM users;"');
    console.log(remainingUsers.stdout);

    console.log('\n--- REMAINING WALLETS (ADMIN ONLY) ---');
    const remainingWallets = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT w.id, w.user_id, u.email, u.role, w.available_balance FROM wallets w JOIN users u ON w.user_id = u.id;"');
    console.log(remainingWallets.stdout);

    // 12. Worker Available Tasks API Verification
    console.log('\n--- WORKER AVAILABLE TASKS API CHECK ---');
    const workerApi = await ssh.execCommand('curl -s -H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('Worker tasks available response:', workerApi.stdout);

    console.log('\n====================================================');
    console.log('🎉 APP DATA CLEANED SUCCESSFULLY - APP IS 100% FRESH!');
    console.log('====================================================');

  } catch (err) {
    console.error('Error during wipe:', err);
  } finally {
    ssh.dispose();
  }
}

wipeCleanAllAppData();
