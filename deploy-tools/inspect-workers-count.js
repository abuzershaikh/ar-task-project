const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== 1. COUNT OF USERS BY ROLE IN MYSQL ===');
  const userCounts = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT role, status, COUNT(*) as count FROM users GROUP BY role, status;'");
  console.log(userCounts.stdout);

  console.log('=== 2. TOTAL WORKERS TABLE COUNT ===');
  const workerTableCount = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT COUNT(*) as total_in_workers_table FROM workers;'");
  console.log(workerTableCount.stdout);

  console.log('=== 3. TOTAL USERS WITH ROLE WORKER ===');
  const totalWorkerRole = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT COUNT(*) as total_worker_role FROM users WHERE role=\"WORKER\";'");
  console.log(totalWorkerRole.stdout);

  console.log('=== 4. HOW ARE THEY REGISTERED (PASSWORD / METADATA) ===');
  const regTypes = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT password, COUNT(*) as count FROM users WHERE role=\"WORKER\" GROUP BY password;'");
  console.log(regTypes.stdout);

  console.log('=== 5. HOW MANY HAVE FCM TOKENS (REAL MOBILE DEVICES) ===');
  const fcmCount = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT COUNT(*) as with_fcm FROM users WHERE role=\"WORKER\" AND metadata LIKE \"%fcmToken%\";'");
  console.log(fcmCount.stdout);

  console.log('=== 6. DATE-WISE BREAKDOWN OF WORKER REGISTRATIONS ===');
  const dateBreakdown = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT DATE(created_at) as reg_date, COUNT(*) as new_workers FROM users WHERE role=\"WORKER\" GROUP BY DATE(created_at) ORDER BY reg_date DESC LIMIT 15;'");
  console.log(dateBreakdown.stdout);

  console.log('=== 7. LATEST 10 REGISTERED WORKERS ===');
  const latestWorkers = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'SELECT id, email, full_name, phone, created_at, last_login FROM users WHERE role=\"WORKER\" ORDER BY created_at DESC LIMIT 10;'");
  console.log(latestWorkers.stdout);

  ssh.dispose();
}

run();
