const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log("=== USERS TABLE ===");
  const users = await ssh.execCommand('node -e "require(\\"dotenv\\").config(); const mysql = require(\\"mysql2/promise\\"); (async () => { const c = await mysql.createConnection({host: process.env.DB_HOST||\\"127.0.0.1\\", port: 3306, user: process.env.DB_USERNAME||\\"task_user\\", password: process.env.DB_PASSWORD, database: \\"task_engine\\"}); const [r] = await c.query(\\"SELECT id, email, full_name, role, is_active FROM users\\"); console.log(JSON.stringify(r)); await c.end(); })()"', { cwd: '/opt/task-engine' });
  console.log(users.stdout);
  if (users.stderr) console.error("users stderr:", users.stderr);

  console.log("=== WORKERS TABLE ===");
  const workers = await ssh.execCommand('node -e "require(\\"dotenv\\").config(); const mysql = require(\\"mysql2/promise\\"); (async () => { const c = await mysql.createConnection({host: process.env.DB_HOST||\\"127.0.0.1\\", port: 3306, user: process.env.DB_USERNAME||\\"task_user\\", password: process.env.DB_PASSWORD, database: \\"task_engine\\"}); const [r] = await c.query(\\"SELECT id, user_id, status, active_tasks_count, last_active_at, fcm_token IS NOT NULL as has_fcm, substring(fcm_token, 1, 20) as fcm_prefix FROM workers\\"); console.log(JSON.stringify(r)); await c.end(); })()"', { cwd: '/opt/task-engine' });
  console.log(workers.stdout);
  if (workers.stderr) console.error("workers stderr:", workers.stderr);

  ssh.dispose();
}

run();
