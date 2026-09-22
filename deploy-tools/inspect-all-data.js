const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectDb() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== EXACT ROW COUNTS IN TASK_PLATFORM ===\n');

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
      'payment_transactions',
      'payment_methods',
      'audit_logs',
      'files',
      'service_catalog',
      'service_pricing',
      'system_settings',
      'migrations'
    ];

    for (const t of tables) {
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as count FROM ${t};"`);
      const lines = res.stdout.trim().split('\n');
      const count = lines[1] ? lines[1].trim() : '0';
      console.log(`${t.padEnd(32)}: ${count} rows`);
    }

  } catch (err) {
    console.error('SSH Error:', err);
  } finally {
    ssh.dispose();
  }
}

inspectDb();
