const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const mysqlScript = `
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/opt/task-engine/.env' });

async function check() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE,
  });

  console.log('=== OVERALL TASKS BY STATUS ===');
  const [taskCounts] = await conn.query('SELECT status, count(*) as count FROM tasks GROUP BY status');
  console.table(taskCounts);

  console.log('=== LATEST ORDER STATUS ===');
  const [latestOrder] = await conn.query('SELECT id, title, service_code, status, total_tasks_required, created_at FROM orders ORDER BY created_at DESC LIMIT 1');
  console.log(latestOrder);

  if (latestOrder.length > 0) {
    const [orderTasks] = await conn.query('SELECT status, count(*) as count FROM tasks WHERE order_id = ? GROUP BY status', [latestOrder[0].id]);
    console.log('Order Tasks breakdown:');
    console.table(orderTasks);
  }

  console.log('=== RECENT 10 SUBMISSIONS / ACTIVITY ===');
  const [submissions] = await conn.query('SELECT id, task_id, worker_id, status, submitted_at FROM task_submissions ORDER BY submitted_at DESC LIMIT 10');
  console.table(submissions);

  console.log('=== BULL / REDIS QUEUE CHECK ===');
  await conn.end();
}
check().catch(console.error);
`;

    const res = await ssh.execCommand(`cd /opt/task-engine && node -e "${mysqlScript.replace(/"/g, '\\"').replace(/\$/g, '\\$')}"`);
    console.log(res.stdout || res.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
