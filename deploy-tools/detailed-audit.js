const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');
const ssh = new NodeSSH();

const scriptContent = `
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/opt/task-engine/.env' });

async function run() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || process.env.DB_USER || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  console.log('====================================================');
  console.log('1. LATEST ORDERS (Most recent 5)');
  console.log('====================================================');
  const [orders] = await connection.query(
    'SELECT id, title, service_code, total_tasks_required, review_mode, status, requirements, created_at FROM orders ORDER BY created_at DESC LIMIT 5'
  );
  for (const o of orders) {
    const reqs = typeof o.requirements === 'string' ? JSON.parse(o.requirements) : o.requirements;
    console.log({
      id: o.id,
      title: o.title,
      service_code: o.service_code,
      quantity: o.total_tasks_required,
      review_mode: o.review_mode,
      status: o.status,
      created_at: o.created_at,
      targetUrl: reqs?.targetUrl || reqs?.url,
      packageId: reqs?.packageId,
      appName: reqs?.appName,
      autoApprove: reqs?.autoApprove
    });
  }

  if (orders.length > 0) {
    const latestOrder = orders[0];
    console.log('\\n====================================================');
    console.log('2. TASKS CREATED FOR LATEST ORDER: ' + latestOrder.id);
    console.log('====================================================');
    const [tasks] = await connection.query(
      'SELECT id, order_id, task_type, status, assigned_to, reward, created_at, updated_at FROM tasks WHERE order_id = ?',
      [latestOrder.id]
    );
    console.log(tasks);

    const taskIds = tasks.map(t => t.id);
    if (taskIds.length > 0) {
      console.log('\\n====================================================');
      console.log('3. TASK ASSIGNMENTS FOR TASKS:');
      console.log('====================================================');
      const [assignments] = await connection.query(
        \`SELECT id, task_id, worker_id, status, assigned_at, accepted_at, completed_at FROM task_assignments WHERE task_id IN (\${taskIds.map(() => '?').join(',')})\`,
        taskIds
      );
      console.log(assignments);
    }
  }

  console.log('\\n====================================================');
  console.log('4. ALL REGISTERED WORKERS & LINKED USER ACCOUNTS');
  console.log('====================================================');
  const [workers] = await connection.query(
    \`SELECT w.id as worker_id, w.user_id, w.status as worker_status, w.is_available, w.active_tasks_count,
            w.last_active_at, w.rating, u.email, u.full_name, u.role, u.is_active
     FROM workers w
     LEFT JOIN users u ON w.user_id = u.id\`
  );
  console.log(workers);

  console.log('\\n====================================================');
  console.log('5. ALL USERS IN USERS TABLE');
  console.log('====================================================');
  const [users] = await connection.query(
    \`SELECT id, email, full_name, role, is_active, created_at FROM users\`
  );
  console.log(users);

  console.log('\\n====================================================');
  console.log('6. PARTICIPATION & COMPLETED IDENTITIES');
  console.log('====================================================');
  const [parts] = await connection.query(
    'SELECT * FROM campaign_worker_participation ORDER BY participated_at DESC LIMIT 15'
  );
  console.log('campaign_worker_participation:', parts);

  try {
    const [identities] = await connection.query(
      'SELECT * FROM worker_completed_identities ORDER BY created_at DESC LIMIT 15'
    );
    console.log('worker_completed_identities:', identities);
  } catch(e) {
    console.log('identities table error:', e.message);
  }

  console.log('\\n====================================================');
  console.log('7. RECENT IN-APP NOTIFICATIONS');
  console.log('====================================================');
  try {
    const [notifs] = await connection.query(
      'SELECT id, user_id, title, body, data, created_at FROM in_app_notifications ORDER BY created_at DESC LIMIT 15'
    );
    console.log(notifs);
  } catch (e) {
    console.log('notifs table error:', e.message);
  }

  await connection.end();
}

run().catch(e => console.error('AUDIT ERROR:', e));
`;

async function main() {
  const localFile = path.join(__dirname, '.temp_audit.js');
  fs.writeFileSync(localFile, scriptContent, 'utf8');

  try {
    console.log('Connecting to VPS...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Uploading audit script...');
    await ssh.putFile(localFile, '/opt/task-engine/run_audit.js');

    console.log('Running audit on VPS...');
    const result = await ssh.execCommand('node run_audit.js', {
      cwd: '/opt/task-engine',
    });

    console.log('\n--- AUDIT RESULTS ---\n');
    console.log(result.stdout);
    if (result.stderr) console.error('STDERR:', result.stderr);
  } catch (e) {
    console.error(e);
  } finally {
    if (fs.existsSync(localFile)) fs.unlinkSync(localFile);
    ssh.dispose();
  }
}

main();
