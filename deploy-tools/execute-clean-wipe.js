const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runCleanWipe() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== CONNECTED TO VPS FOR DATABASE CLEANUP ===\n');

    // 1. Take a safe backup first
    console.log('--- 1. Creating Database Backup on VPS ---');
    await ssh.execCommand('mysqldump -u taskapp -ptaskapp_password task_platform > /root/task_platform_backup_before_wipe.sql');
    console.log('✅ Backup saved to /root/task_platform_backup_before_wipe.sql');

    // 2. Upload / Write wipe.sql on the server
    console.log('\n--- 2. Writing /root/wipe.sql on VPS ---');
    const wipeSql = `
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
TRUNCATE TABLE worker_completed_identities;

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

    await ssh.execCommand(`cat << 'EOF' > /root/wipe.sql\n${wipeSql}\nEOF`);
    console.log('✅ /root/wipe.sql created on VPS.');

    // 3. Execute the wipe script via MySQL redirect
    console.log('\n--- 3. Executing MySQL wipe.sql ---');
    const execRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform < /root/wipe.sql');
    if (execRes.stderr && !execRes.stderr.includes('Using a password')) {
      console.error('MySQL Error:', execRes.stderr);
    } else {
      console.log('✅ MySQL wipe executed successfully!');
    }

    // 4. Clean uploads folder
    console.log('\n--- 4. Cleaning Uploads Directory on VPS ---');
    await ssh.execCommand('rm -rf /opt/task-engine/uploads/* /root/ar-task-project/uploads/* 2>/dev/null; mkdir -p /opt/task-engine/uploads');
    console.log('✅ Uploads directory cleaned and reset.');

    // 5. Restart PM2 processes
    console.log('\n--- 5. Restarting Task Engine Services (PM2) ---');
    await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log('✅ task-engine-api and task-engine-worker restarted.');

    // 6. Verification: Check remaining tables and rows
    console.log('\n--- 6. Post-Cleanup Verification Report ---');
    const tables = [
      'users',
      'workers',
      'worker_scores',
      'worker_completed_identities',
      'kyc_profiles',
      'earnings',
      'withdrawals',
      'ratings',
      'notifications',
      'orders',
      'order_units',
      'campaign_worker_participation',
      'tasks',
      'task_assignments',
      'task_generation_jobs',
      'task_submissions',
      'wallets',
      'wallet_transactions',
      'files',
      'service_catalog',
      'service_pricing',
      'system_settings'
    ];

    for (const t of tables) {
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as count FROM ${t};"`);
      const lines = res.stdout.trim().split('\n');
      const count = lines[1] ? lines[1].trim() : '0';
      console.log(`${t.padEnd(32)}: ${count} rows`);
    }

    console.log('\n--- Remaining Super Admin Accounts ---');
    const adminUsers = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, full_name, role, status FROM users;"');
    console.log(adminUsers.stdout);

  } catch (err) {
    console.error('Execution Error:', err);
  } finally {
    ssh.dispose();
  }
}

runCleanWipe();
