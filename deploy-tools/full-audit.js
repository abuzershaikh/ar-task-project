const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const script = `
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/opt/task-engine/.env' });

async function main() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'taskapp',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_platform',
  });

  console.log("=== 1. ALL REGISTERED USERS ===");
  const [users] = await conn.query("SELECT id, email, full_name, role, is_active, created_at FROM users");
  console.table(users);

  console.log("\\n=== 2. ALL WORKERS LINKED WITH USERS ===");
  const [workers] = await conn.query(\`
    SELECT w.id as worker_id, w.user_id, u.email, u.full_name, w.status as worker_status,
           w.active_tasks_count, w.last_active_at,
           CASE WHEN w.fcm_token IS NOT NULL AND w.fcm_token != '' THEN 'YES' ELSE 'NO' END as has_fcm,
           w.performance_points
    FROM workers w
    LEFT JOIN users u ON w.user_id = u.id
  \`);
  console.table(workers);

  console.log("\\n=== 3. TASKS FOR RECENT GROWW ORDER (08bebc9c-ccce-41cc-b3eb-47e3a40a86ff) ===");
  const [tasks] = await conn.query(
    "SELECT id, order_id, task_type, status, assigned_to, reward_amount, created_at FROM tasks WHERE order_id = '08bebc9c-ccce-41cc-b3eb-47e3a40a86ff'"
  );
  console.table(tasks);

  console.log("\\n=== 4. ASSIGNMENTS FOR THIS ORDER ===");
  const [assignments] = await conn.query(\`
    SELECT ta.id, ta.task_id, ta.worker_id, u.email as worker_email, ta.status, ta.assigned_at, ta.accepted_at
    FROM task_assignments ta
    LEFT JOIN workers w ON ta.worker_id = w.id
    LEFT JOIN users u ON w.user_id = u.id
    WHERE ta.task_id IN (\${tasks.map(t => "'" + t.id + "'").join(',')})
  \`);
  console.table(assignments);

  console.log("\\n=== 5. PARTICIPATION & COMPLETED IDENTITIES FOR GROWW ===");
  const [parts] = await conn.query("SELECT * FROM campaign_worker_participation WHERE entity_key LIKE '%groww%'");
  console.table(parts);

  const [identities] = await conn.query("SELECT * FROM worker_completed_identities WHERE entity_key LIKE '%groww%'");
  console.table(identities);

  console.log("\\n=== 6. ALL HISTORICAL ASSIGNMENTS PER WORKER FOR ANY GROWW OR APP INSTALL/REVIEW ===");
  const [allGrowwTasks] = await conn.query(\`
    SELECT ta.id, ta.task_id, ta.worker_id, u.email, ta.status, ta.assigned_at, t.task_type, t.requirements
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    LEFT JOIN workers w ON ta.worker_id = w.id
    LEFT JOIN users u ON w.user_id = u.id
    WHERE t.requirements LIKE '%com.nextbillion.groww%'
  \`);
  console.table(allGrowwTasks.map(r => ({
    assignment_id: r.id,
    worker_email: r.email,
    worker_id: r.worker_id,
    task_type: r.task_type,
    status: r.status,
    assigned_at: r.assigned_at
  })));

  await conn.end();
}
main().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /opt/task-engine/run_full_audit.js\n" + script + "\nEOF");
  const auditRes = await ssh.execCommand("node /opt/task-engine/run_full_audit.js", { cwd: '/opt/task-engine' });
  console.log(auditRes.stdout);
  if (auditRes.stderr) console.error(auditRes.stderr);

  ssh.dispose();
}

run();
