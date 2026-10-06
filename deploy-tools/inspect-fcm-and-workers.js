const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const orderId = '90360304-d5e2-4407-b6a5-11bf922f761a';

  console.log('=== NOTIFICATIONS CREATED OR DISPATCHED ===');
  const notifs = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, title, message, type, is_read, created_at FROM notifications WHERE created_at >= '2026-10-05 18:15:00' ORDER BY created_at DESC LIMIT 20;"`);
  console.log(notifs.stdout);

  console.log('=== FCM / DISPATCH LOGS IN PM2 ===');
  const fcmLogs = await ssh.execCommand(`grep -i "notification" /root/.pm2/logs/task-engine-api-out-0.log | tail -n 30`);
  console.log(fcmLogs.stdout);

  console.log('=== TOTAL REGISTERED WORKERS ===');
  const wCount = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT role, status, COUNT(*) FROM users GROUP BY role, status;"`);
  console.log(wCount.stdout);

  ssh.dispose();
}

run().catch(console.error);
