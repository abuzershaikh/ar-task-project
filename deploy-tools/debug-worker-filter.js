const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const debugScript = `
const { TaskEngineService } = require('/opt/task-engine/dist/task-engine/task-engine.service');

// Let's check MySQL directly for brandnew_worker and snapbizux participation / assignments / submissions / excluded URLs
const mysql = require('/opt/task-engine/node_modules/mysql2/promise');

async function debugWorker(email, userId) {
  const conn = await mysql.createConnection({
    host: '127.0.0.1',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  console.log('=== DEBUGGING WORKER:', email, userId, '===');

  // 1. Check all user IDs
  const [users] = await conn.query('SELECT id, email, role FROM users WHERE email=? OR id=?', [email, userId]);
  console.log('Users found:', users);
  const uids = users.map(u => u.id);
  if (!uids.includes(userId)) uids.push(userId);
  if (!uids.includes(email)) uids.push(email);

  // 2. Check task_assignments
  const [assigns] = await conn.query('SELECT id, task_id, worker_id, status FROM task_assignments WHERE worker_id IN (?)', [uids]);
  console.log('Assignments count:', assigns.length);

  // 3. Check tasks assigned_to
  const [tasks] = await conn.query('SELECT id, task_type, assigned_to, status, requirements FROM tasks WHERE assigned_to IN (?)', [uids]);
  console.log('Tasks assigned_to count:', tasks.length);

  // 4. Check submissions
  const [subs] = await conn.query('SELECT id, task_id, worker_id, status FROM task_submissions WHERE worker_id IN (?)', [uids]);
  console.log('Submissions count:', subs.length);

  // 5. Check participations
  const [parts] = await conn.query('SELECT * FROM campaign_worker_participation WHERE worker_id IN (?)', [uids]);
  console.log('Participations count:', parts.length);

  await conn.end();
}

async function main() {
  await debugWorker('brandnew_worker@gmail.com', 'newworker999');
  await debugWorker('snapbizux@gmail.com', '15QuKnQDcwS5NLacLIQ8V8CElnA2');
}

main().catch(console.error);
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/debug_filter.js\n${debugScript}\nEOF`);
  const res = await ssh.execCommand('node /tmp/debug_filter.js');
  console.log(res.stdout, res.stderr);

  ssh.dispose();
}

run().catch(console.error);
