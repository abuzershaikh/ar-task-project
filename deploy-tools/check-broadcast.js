const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== BUYER OF ORDER 08bebc9c ===');
  const o = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT o.id, o.buyer_id, u.email as buyer_email, u.full_name FROM orders o LEFT JOIN users u ON o.buyer_id = u.id WHERE o.id = \'08bebc9c-ccce-41cc-b3eb-47e3a40a86ff\';"');
  console.log(o.stdout);

  console.log('=== FCM TOKENS FOR REAL WORKERS ===');
  const tokens = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT w.id as worker_id, w.user_id, u.email, w.status, w.fcm_token IS NOT NULL AND w.fcm_token != \'\' as has_fcm, substring(w.fcm_token, 1, 30) as fcm_snip, w.last_active_at FROM workers w LEFT JOIN users u ON w.user_id = u.id WHERE u.email IN (\'sufieditz@gmail.com\', \'saifshah7865@gmail.com\', \'dmarketer25@gmail.com\', \'zestdroidz@gmail.com\', \'sonathe333@gmail.com\', \'growwyourwealthofficial@gmail.com\');"');
  console.log(tokens.stdout);

  console.log('=== RECENT PM2 LOGS FOR ORDER ACTIVATED LISTENER (Groww) ===');
  const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 200 --nostream');
  const lines = logs.stdout.split('\n').filter(l => l.includes('OrderActivated') || l.includes('Groww') || l.includes('groww') || l.includes('FCM') || l.includes('broadcast') || l.includes('eligible') || l.includes('push') || l.includes('exclude') || l.includes('dispatch')).join('\n');
  console.log(lines);

  ssh.dispose();
}

run();
