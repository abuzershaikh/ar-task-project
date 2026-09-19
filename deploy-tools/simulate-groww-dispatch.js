const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const code = `
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/opt/task-engine/.env' });
const { extractTaskIdentity } = require('./dist/shared/common/utils/task-identity.util');

async function test() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'taskapp',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_platform',
  });

  const packageId = 'com.nextbillion.groww';
  const targetUrl = 'https://play.google.com/store/apps/details?id=com.nextbillion.groww';
  const identity = extractTaskIdentity({ packageId, targetUrl });
  console.log("Task identity:", identity);

  // 1. Check all tasks in DB with this packageId
  const [allTasks] = await conn.query("SELECT id, order_id, task_type, status, assigned_to, requirements, metadata FROM tasks");
  const matchingTasks = [];
  const workerIds = new Set();

  for (const t of allTasks) {
    let reqs = {};
    try { reqs = typeof t.requirements === 'string' ? JSON.parse(t.requirements) : t.requirements || {}; } catch(e) {}
    let meta = {};
    try { meta = typeof t.metadata === 'string' ? JSON.parse(t.metadata) : t.metadata || {}; } catch(e) {}

    const tid = extractTaskIdentity({ requirements: reqs, metadata: meta, targetUrl: reqs.targetUrl, packageId: reqs.packageId || meta.packageId });
    if (tid.packageId === identity.packageId || (identity.normalizedUrl && tid.normalizedUrl === identity.normalizedUrl)) {
      matchingTasks.push({ id: t.id, order_id: t.order_id, assigned_to: t.assigned_to, status: t.status });
      if (t.assigned_to) workerIds.add(t.assigned_to.toString().trim());
    }
  }

  console.log("\\nMatching Tasks count across entire database:", matchingTasks.length);
  console.log("Matching Tasks list:", matchingTasks);
  console.log("Workers directly on task.assigned_to:", Array.from(workerIds));

  // 2. Check task_assignments for these matching task IDs
  const matchingTaskIds = matchingTasks.map(t => t.id);
  if (matchingTaskIds.length > 0) {
    const [assignments] = await conn.query(
      \`SELECT id, task_id, worker_id, status FROM task_assignments WHERE task_id IN (\${matchingTaskIds.map(() => '?').join(',')})\`,
      matchingTaskIds
    );
    console.log("\\nAssignments in task_assignments for matching tasks:", assignments);
    for (const a of assignments) {
      if (a.worker_id) workerIds.add(a.worker_id.toString().trim());
    }
  }

  console.log("\\nAll Raw Worker IDs identified as having done this app:", Array.from(workerIds));

  // 3. Resolve aliases
  const rawIds = Array.from(workerIds);
  const resolvedIds = new Set(rawIds.map(x => x.toLowerCase().trim()));
  if (rawIds.length > 0) {
    const [rows] = await conn.query(
      \`SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId
       FROM users u
       LEFT JOIN workers w ON w.user_id = u.id
       WHERE u.id IN (?) OR u.email IN (?) OR w.id IN (?)\`,
      [rawIds, rawIds, rawIds]
    );
    console.log("\\nResolved aliases from DB:", rows);
    for (const r of rows) {
      if (r.userId) resolvedIds.add(r.userId.toLowerCase().trim());
      if (r.userEmail) resolvedIds.add(r.userEmail.toLowerCase().trim());
      if (r.workerId) resolvedIds.add(r.workerId.toLowerCase().trim());
    }
  }

  console.log("\\nFINAL EXCLUDED WORKER SET (Any ID/Email in this set is BLOCKED from notification and feed):");
  console.log(Array.from(resolvedIds));

  // 4. Now check all workers in users table and see their eligibility
  const [allWorkers] = await conn.query("SELECT id, email, full_name, role, metadata FROM users WHERE role = 'WORKER'");
  console.log("\\n=== ELIGIBILITY VERDICT FOR ALL REGISTERED WORKERS ===");
  for (const w of allWorkers) {
    const wId = (w.id || '').toLowerCase().trim();
    const wEmail = (w.email || '').toLowerCase().trim();
    const isExcluded = resolvedIds.has(wId) || resolvedIds.has(wEmail);
    const meta = typeof w.metadata === 'string' ? JSON.parse(w.metadata) : (w.metadata || {});
    const token = meta.fcmToken || meta.deviceToken;
    const hasToken = token && typeof token === 'string' && token.length > 20;

    let reason = '';
    if (isExcluded) {
      reason = '❌ EXCLUDED: Worker (or alias/email) has ALREADY completed or held a task for this package (' + packageId + ')';
    } else if (!hasToken) {
      reason = '⚠️ NOT EXCLUDED, BUT NO FCM PUSH TOKEN: Worker has no valid device token registered';
    } else {
      reason = '✅ ELIGIBLE & WILL RECEIVE PUSH: Valid token found (' + token.slice(0, 25) + '...)';
    }

    console.log(\`Worker: \${w.email} (ID: \${w.id})\`);
    console.log(\`  Verdict: \${reason}\`);
  }

  await conn.end();
}

test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /opt/task-engine/sim_dispatch.js\n" + code + "\nEOF");
  const res = await ssh.execCommand('node /opt/task-engine/sim_dispatch.js', { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);

  ssh.dispose();
}

run();
