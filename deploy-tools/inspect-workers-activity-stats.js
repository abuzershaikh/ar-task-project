const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== 1. USERS STATUS BREAKDOWN ===');
  const userStatus = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT role, status, count(*) FROM users GROUP BY role, status;"`);
  console.log(userStatus.stdout);

  console.log('=== 2. WORKERS TABLE STATUS BREAKDOWN ===');
  const workerStatus = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT status, kyc_status, count(*) FROM workers GROUP BY status, kyc_status;"`);
  console.log(workerStatus.stdout);

  console.log('=== 3. WORKER LAST ACTIVE AT BREAKDOWN ===');
  const activeBreakdown = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN last_active_at IS NOT NULL AND last_active_at >= NOW() - INTERVAL 24 HOUR THEN 1 ELSE 0 END) as active_24h,
    SUM(CASE WHEN last_active_at IS NOT NULL AND last_active_at >= NOW() - INTERVAL 48 HOUR AND last_active_at < NOW() - INTERVAL 24 HOUR THEN 1 ELSE 0 END) as warning_48h,
    SUM(CASE WHEN last_active_at IS NULL OR last_active_at < NOW() - INTERVAL 48 HOUR THEN 1 ELSE 0 END) as inactive_48h,
    SUM(CASE WHEN last_active_at IS NULL THEN 1 ELSE 0 END) as never_active
    FROM workers;"`);
  console.log(activeBreakdown.stdout);

  console.log('=== 4. USERS LAST LOGIN BREAKDOWN ===');
  const loginBreakdown = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN last_login IS NOT NULL AND last_login >= NOW() - INTERVAL 24 HOUR THEN 1 ELSE 0 END) as login_24h,
    SUM(CASE WHEN last_login IS NOT NULL AND last_login >= NOW() - INTERVAL 48 HOUR THEN 1 ELSE 0 END) as login_48h,
    SUM(CASE WHEN last_login IS NULL OR last_login < NOW() - INTERVAL 48 HOUR THEN 1 ELSE 0 END) as login_inactive_48h,
    SUM(CASE WHEN last_login IS NULL THEN 1 ELSE 0 END) as never_logged_in
    FROM users WHERE role='WORKER';"`);
  console.log(loginBreakdown.stdout);

  console.log('=== 5. SAMPLE WORKERS (FIRST 5) ===');
  const sample = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT w.id, w.user_id, w.status as w_status, u.status as u_status, w.last_active_at, u.last_login, w.total_tasks_completed FROM workers w JOIN users u ON w.user_id = u.id LIMIT 5;"`);
  console.log(sample.stdout);

  console.log('=== 6. BUYERS BREAKDOWN ===');
  const buyers = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, email, status, last_login, created_at FROM users WHERE role='BUYER';"`);
  console.log(buyers.stdout);

  ssh.dispose();
}

run();
