const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function audit() {
  try {
    console.log('Connecting to Mumbai VPS SSH (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS SSH!\n');

    // Create remote audit script
    const remoteScript = `
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/opt/task-engine/.env' });

async function run() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    username: process.env.DB_USERNAME || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  console.log('================================================================');
  console.log('1. LATEST ORDERS (Most recent 5 orders)');
  console.log('================================================================');
  const [orders] = await connection.query(
    'SELECT id, title, service_code, total_tasks_required, review_mode, status, requirements, created_at FROM orders ORDER BY created_at DESC LIMIT 5'
  );
  console.log(JSON.stringify(orders, null, 2));

  if (orders.length === 0) {
    console.log('No orders found!');
    await connection.end();
    return;
  }

  const latestOrder = orders[0];
  const orderId = latestOrder.id;
  console.log('\\n================================================================');
  console.log(\`2. TASKS CREATED FOR LATEST ORDER: \${orderId}\`);
  console.log('================================================================');
  const [tasks] = await connection.query(
    'SELECT id, order_id, task_type, status, assigned_to, reward, created_at, updated_at FROM tasks WHERE order_id = ?',
    [orderId]
  );
  console.log(JSON.stringify(tasks, null, 2));

  console.log('\\n================================================================');
  console.log(\`3. TASK ASSIGNMENTS FOR LATEST ORDER TASKS\`);
  console.log('================================================================');
  const taskIds = tasks.map(t => t.id);
  if (taskIds.length > 0) {
    const [assignments] = await connection.query(
      \`SELECT * FROM task_assignments WHERE task_id IN (\${taskIds.map(() => '?').join(',')}) ORDER BY assigned_at DESC\`,
      taskIds
    );
    console.log(JSON.stringify(assignments, null, 2));
  } else {
    console.log('No tasks found for order.');
  }

  console.log('\\n================================================================');
  console.log('4. ALL REGISTERED WORKERS & THEIR USER / EMAIL ACCOUNTS');
  console.log('================================================================');
  const [workers] = await connection.query(
    \`SELECT w.id as worker_id, w.user_id, w.status as worker_status, w.is_available, w.active_tasks_count,
            w.fcm_token, w.device_info, w.last_active_at, w.rating,
            u.email, u.full_name, u.role, u.is_active as user_is_active
     FROM workers w
     LEFT JOIN users u ON w.user_id = u.id\`
  );
  console.log(JSON.stringify(workers, null, 2));

  console.log('\\n================================================================');
  console.log('5. PARTICIPATION & COMPLETED IDENTITIES HISTORY FOR ALL WORKERS');
  console.log('================================================================');
  const [participation] = await connection.query(
    'SELECT * FROM campaign_worker_participation ORDER BY participated_at DESC LIMIT 20'
  );
  console.log('campaign_worker_participation (recent 20):');
  console.log(JSON.stringify(participation, null, 2));

  try {
    const [identities] = await connection.query(
      'SELECT * FROM worker_completed_identities ORDER BY created_at DESC LIMIT 20'
    );
    console.log('\\nworker_completed_identities (recent 20):');
    console.log(JSON.stringify(identities, null, 2));
  } catch (e) {
    console.log('worker_completed_identities error or table empty:', e.message);
  }

  console.log('\\n================================================================');
  console.log('6. PREVIOUS TASKS COMPLETED / ASSIGNED PER WORKER');
  console.log('================================================================');
  const [prevAssignments] = await connection.query(
    \`SELECT worker_id, status, count(*) as count
     FROM task_assignments
     GROUP BY worker_id, status\`
  );
  console.log(JSON.stringify(prevAssignments, null, 2));

  await connection.end();
}

run().catch(console.error);
`;

    console.log('Writing remote audit script on VPS...');
    await ssh.execCommand("cat << 'EOF' > /tmp/audit-task-engine.js\n" + remoteScript + "\nEOF");

    console.log('Executing DB audit on VPS...\n');
    const dbAuditRes = await ssh.execCommand('node /tmp/audit-task-engine.js', {
      cwd: '/opt/task-engine',
    });
    console.log(dbAuditRes.stdout);
    if (dbAuditRes.stderr) console.error('DB Audit Stderr:', dbAuditRes.stderr);

    console.log('\n================================================================');
    console.log('7. PM2 LOGS FOR MATCHING & ORDER DISPATCH (Recent 150 lines)');
    console.log('================================================================');
    const apiLogs = await ssh.execCommand('pm2 logs task-engine-api --lines 120 --nostream');
    console.log('API LOGS:\n', apiLogs.stdout);

    const workerLogs = await ssh.execCommand('pm2 logs task-engine-worker --lines 120 --nostream');
    console.log('WORKER LOGS:\n', workerLogs.stdout);

  } catch (err) {
    console.error('Audit script failed:', err);
  } finally {
    ssh.dispose();
  }
}

audit();
