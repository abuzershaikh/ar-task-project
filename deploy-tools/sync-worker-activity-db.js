const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('--- 1. SYNCING workers.last_active_at FROM users.last_login ---');
  const r1 = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "UPDATE workers w JOIN users u ON w.user_id = u.id SET w.last_active_at = u.last_login WHERE u.last_login IS NOT NULL;"`);
  console.log('Result:', r1.stdout, r1.stderr || 'SUCCESS');

  console.log('--- 2. VERIFYING COUNTS ---');
  const r2 = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT 
    COUNT(*) as total_workers,
    SUM(CASE WHEN last_active_at IS NOT NULL THEN 1 ELSE 0 END) as has_last_active,
    SUM(CASE WHEN last_active_at >= NOW() - INTERVAL 48 HOUR THEN 1 ELSE 0 END) as active_within_48h,
    SUM(CASE WHEN last_active_at < NOW() - INTERVAL 48 HOUR OR last_active_at IS NULL THEN 1 ELSE 0 END) as inactive_over_48h
    FROM workers;"`);
  console.log(r2.stdout);

  ssh.dispose();
}

run();
