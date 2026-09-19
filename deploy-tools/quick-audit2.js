const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const cmd = `cat << 'EOF' > /opt/task-engine/test_audit2.js
const mysql = require('mysql2/promise');
require('dotenv').config();

async function check() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  console.log("=== WORKERS TABLE COLUMNS ===");
  const [cols] = await conn.query("DESCRIBE workers");
  console.log(cols.map(c => c.Field).join(', '));

  console.log("=== ALL USERS ===");
  const [users] = await conn.query("SELECT id, email, full_name, role, is_active, created_at FROM users");
  console.log(JSON.stringify(users, null, 2));

  console.log("=== ALL WORKERS ===");
  const [workers] = await conn.query("SELECT * FROM workers");
  console.log(JSON.stringify(workers, null, 2));

  console.log("=== NOTIFICATIONS LOG ===");
  try {
    const [notifs] = await conn.query("SELECT * FROM in_app_notifications ORDER BY created_at DESC LIMIT 10");
    console.log(JSON.stringify(notifs, null, 2));
  } catch(e) {
    console.log("in_app_notifications error:", e.message);
  }

  console.log("=== RECENT ORDER ACTIVATED LOGS IN PM2 ===");
  await conn.end();
}
check().catch(console.error);
EOF
node /opt/task-engine/test_audit2.js
`;

  const res = await ssh.execCommand(cmd, { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error("STDERR:", res.stderr);

  console.log("=== PM2 API & WORKER LOGS FOR ORDER ACTIVATED ===");
  const grepLogs = await ssh.execCommand("grep -i -E '08bebc9c|OrderActivated|matching|groww|push|fcm|exclude|dispatch' /root/.pm2/logs/task-engine-api-out-2.log /root/.pm2/logs/task-engine-worker-out-3.log | tail -n 60");
  console.log(grepLogs.stdout);

  ssh.dispose();
}

run();
