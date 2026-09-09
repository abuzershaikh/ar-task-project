const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkDetails() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    const tables = [
      'audit_logs',
      'campaign_worker_participation',
      'earnings',
      'files',
      'kyc_profiles',
      'notifications',
      'orders',
      'order_units',
      'payment_methods',
      'payment_transactions',
      'ratings',
      'service_catalog',
      'service_pricing',
      'system_settings',
      'tasks',
      'task_assignments',
      'task_generation_jobs',
      'task_submissions',
      'users',
      'wallets',
      'wallet_transactions',
      'withdrawals',
      'workers',
      'worker_scores'
    ];

    console.log('--- TABLE ROW COUNTS ---');
    for (const t of tables) {
      const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as count FROM ${t};"`);
      console.log(`${t.padEnd(30)}: ${res.stdout.split('\n')[1] || res.stdout.trim()}`);
    }

    console.log('\n--- ADMIN WALLETS ---');
    const adminWallets = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT w.id, w.user_id, u.email, u.role, w.available_balance 
      FROM wallets w 
      JOIN users u ON w.user_id = u.id;
    "`);
    console.log(adminWallets.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkDetails();
