const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const cmd = `cat << 'EOF' > /opt/task-engine/test_audit.js
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

  const orderId = '08bebc9c-ccce-41cc-b3eb-47e3a40a86ff';

  console.log("=== TASKS FOR LATEST ORDER ===");
  const [tasks] = await conn.query("SELECT * FROM tasks WHERE order_id = ?", [orderId]);
  console.log(JSON.stringify(tasks, null, 2));

  const taskIds = tasks.map(t => t.id);
  if (taskIds.length > 0) {
    const [assignments] = await conn.query(\`SELECT * FROM task_assignments WHERE task_id IN (\${taskIds.map(() => '?').join(',')})\`, taskIds);
    console.log("=== ASSIGNMENTS FOR LATEST ORDER ===");
    console.log(JSON.stringify(assignments, null, 2));
  }

  console.log("=== ALL WORKERS & LINKED USERS ===");
  const [workers] = await conn.query(\`
    SELECT w.id as worker_id, w.user_id, w.status as worker_status, w.is_available, w.active_tasks_count,
           w.last_active_at, w.rating, u.id as u_id, u.email, u.full_name, u.role, u.is_active
    FROM workers w
    LEFT JOIN users u ON w.user_id = u.id
  \`);
  console.log(JSON.stringify(workers, null, 2));

  console.log("=== ALL USERS IN USERS TABLE ===");
  const [users] = await conn.query("SELECT id, email, full_name, role, is_active, created_at FROM users");
  console.log(JSON.stringify(users, null, 2));

  console.log("=== WORKER COMPLETED IDENTITIES (for com.nextbillion.groww) ===");
  const [identities] = await conn.query("SELECT * FROM worker_completed_identities WHERE entity_key LIKE '%groww%' OR entity_key LIKE '%nextbillion%'");
  console.log(JSON.stringify(identities, null, 2));

  console.log("=== CAMPAIGN PARTICIPATION (for com.nextbillion.groww) ===");
  const [participation] = await conn.query("SELECT * FROM campaign_worker_participation WHERE entity_key LIKE '%groww%' OR entity_key LIKE '%nextbillion%'");
  console.log(JSON.stringify(participation, null, 2));

  console.log("=== ALL PREVIOUS ASSIGNMENTS FOR ANY GROWW OR SIMILAR TASKS ===");
  const [prevGrowwTasks] = await conn.query("SELECT id, order_id, task_type, status, assigned_to, requirements FROM tasks WHERE requirements LIKE '%groww%'");
  console.log("Groww tasks count:", prevGrowwTasks.length);
  for (const t of prevGrowwTasks) {
    console.log("Task:", t.id, "Order:", t.order_id, "Status:", t.status, "AssignedTo:", t.assigned_to);
  }

  await conn.end();
}
check().catch(e => { console.error(e); process.exit(1); });
EOF
node /opt/task-engine/test_audit.js
`;

  const res = await ssh.execCommand(cmd, { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error("STDERR:", res.stderr);
  ssh.dispose();
}

run();
