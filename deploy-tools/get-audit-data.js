const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    console.log('1. Connecting to VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 10000,
    });
    console.log('2. Connected!');

    const remoteCode = `
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/opt/task-engine/.env' });

async function check() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'taskapp',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_platform',
  });

  const [users] = await conn.query("SELECT id, email, full_name, role, is_active FROM users");
  console.log("=== USERS ===");
  console.log(JSON.stringify(users));

  const [workers] = await conn.query("SELECT id, user_id, status, active_tasks_count, last_active_at, fcm_token IS NOT NULL AND fcm_token != '' as has_fcm, substring(fcm_token, 1, 30) as fcm_snip FROM workers");
  console.log("=== WORKERS ===");
  console.log(JSON.stringify(workers));

  const [parts] = await conn.query("SELECT * FROM campaign_worker_participation WHERE entity_key LIKE '%groww%'");
  console.log("=== PARTICIPATION GROWW ===");
  console.log(JSON.stringify(parts));

  const [identities] = await conn.query("SELECT * FROM worker_completed_identities WHERE entity_key LIKE '%groww%'");
  console.log("=== IDENTITIES GROWW ===");
  console.log(JSON.stringify(identities));

  const [assignments] = await conn.query("SELECT ta.id, ta.task_id, ta.worker_id, u.email, ta.status, ta.assigned_at FROM task_assignments ta LEFT JOIN workers w ON ta.worker_id = w.id LEFT JOIN users u ON w.user_id = u.id ORDER BY ta.assigned_at DESC LIMIT 15");
  console.log("=== RECENT 15 ASSIGNMENTS ===");
  console.log(JSON.stringify(assignments));

  await conn.end();
}
check().catch(console.error);
`;

    console.log('3. Writing script to /opt/task-engine/db_check.js...');
    await ssh.execCommand("cat << 'EOF' > /opt/task-engine/db_check.js\n" + remoteCode + "\nEOF");

    console.log('4. Running db_check.js...');
    const res = await ssh.execCommand('node /opt/task-engine/db_check.js', { cwd: '/opt/task-engine' });
    console.log(res.stdout);
    if (res.stderr) console.error('STDERR:', res.stderr);

    console.log('5. Fetching OrderActivated and push logs from PM2...');
    const pm2Logs = await ssh.execCommand('pm2 logs task-engine-api --lines 80 --nostream');
    const filtered = pm2Logs.stdout.split('\n').filter(l => l.includes('OrderActivated') || l.includes('FCM') || l.includes('Matching') || l.includes('push') || l.includes('Groww') || l.includes('08bebc9c') || l.includes('dispatch') || l.includes('exclude')).join('\n');
    console.log('=== PM2 MATCHING / FCM LOGS ===\n', filtered || 'No direct matching lines in last 80 lines');

  } catch (err) {
    console.error('ERROR:', err);
  } finally {
    ssh.dispose();
  }
}

run();
