const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deployUniqueReviews() {
  try {
    console.log('🚀 Connecting to VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 30000,
    });
    console.log('✅ Connected to VPS!\n');

    const localBase = path.resolve(__dirname, '../Task engine');
    const remoteBase = '/opt/task-engine';

    const filesToUpload = [
      'shared/common/utils/task-identity.util.ts',
      'task-engine/queries/task-query.service.ts',
      'task-engine/handlers/task-command.service.ts',
      'shared/database/repositories/task.repository.ts',
      'matching-engine/filters/duplicate-filter.service.ts',
      'shared/services/order-activated.listener.ts',
      'apps/api/controllers/worker/notification.controller.ts',
    ];

    console.log(`📤 Uploading ${filesToUpload.length} files to VPS...`);
    for (const relPath of filesToUpload) {
      const localFilePath = path.join(localBase, relPath);
      const remoteFilePath = `${remoteBase}/${relPath}`.replace(/\\/g, '/');
      const remoteDir = path.dirname(remoteFilePath).replace(/\\/g, '/');
      await ssh.execCommand(`mkdir -p "${remoteDir}"`);
      await ssh.putFile(localFilePath, remoteFilePath);
      console.log(`   ✅ Uploaded: ${relPath}`);
    }
    console.log('\nAll files uploaded successfully!\n');

    // Ensure worker_completed_identities table exists with proper schema
    console.log('🔍 Ensuring worker_completed_identities table exists in MariaDB...');
    const createTableSql = `
      CREATE TABLE IF NOT EXISTS worker_completed_identities (
        id INT AUTO_INCREMENT PRIMARY KEY,
        worker_key VARCHAR(191) NOT NULL,
        entity_key VARCHAR(255) NOT NULL,
        task_id VARCHAR(64) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uk_worker_entity (worker_key, entity_key),
        INDEX idx_worker_key (worker_key),
        INDEX idx_entity_key (entity_key)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `.trim().replace(/\n/g, ' ');

    const tableRes = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "${createTableSql}"`);
    console.log('Table check result:', tableRes.stdout || 'OK');
    if (tableRes.stderr) console.warn('Table check stderr:', tableRes.stderr);

    console.log('🔨 Compiling backend (npm run build) on VPS...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log('Build output:\n', buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated') && !buildRes.stderr.includes('ts-node')) {
      console.warn('Build stderr:\n', buildRes.stderr);
    }

    // Now run historical backfill script on the server
    console.log('\n🔄 Running historical tasks backfill script on VPS...');
    const backfillScript = `
const mysql = require('mysql2/promise');
const path = require('path');
const { extractTaskIdentity } = require('./dist/shared/common/utils/task-identity.util.js');

async function backfill() {
  const pool = await mysql.createPool({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform',
    waitForConnections: true,
    connectionLimit: 10,
  });

  console.log('Fetching all historical non-cancelled tasks with assigned_to...');
  const [tasks] = await pool.query(\`
    SELECT id, assigned_to, requirements, metadata, status, created_at
    FROM tasks
    WHERE status NOT IN ('cancelled', 'CANCELLED')
      AND assigned_to IS NOT NULL
      AND assigned_to != ''
  \`);
  console.log('Found ' + tasks.length + ' assigned/completed tasks.');

  // Also fetch all task_assignments
  const [assignments] = await pool.query(\`
    SELECT task_id, worker_id
    FROM task_assignments
    WHERE worker_id IS NOT NULL AND worker_id != ''
  \`);
  const assignmentsByTask = new Map();
  for (const a of assignments) {
    if (!assignmentsByTask.has(a.task_id)) assignmentsByTask.set(a.task_id, new Set());
    assignmentsByTask.get(a.task_id).add(a.worker_id.toString().trim());
  }

  // Fetch users & workers to map aliases
  const [userRows] = await pool.query(\`
    SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId
    FROM users u
    LEFT JOIN workers w ON w.user_id = u.id
  \`);
  const aliasMap = new Map();
  function addAliasGroup(keys) {
    const set = new Set();
    for (const k of keys) {
      if (k) set.add(k.toString().trim().toLowerCase());
    }
    for (const k of set) {
      if (!aliasMap.has(k)) aliasMap.set(k, set);
      else {
        const existing = aliasMap.get(k);
        for (const item of set) existing.add(item);
      }
    }
  }
  for (const r of userRows) {
    addAliasGroup([r.userId, r.userEmail, r.workerId]);
  }

  let insertedCount = 0;
  for (const t of tasks) {
    let reqs = t.requirements;
    if (typeof reqs === 'string') {
      try { reqs = JSON.parse(reqs); } catch (_) { reqs = {}; }
    }
    let meta = t.metadata;
    if (typeof meta === 'string') {
      try { meta = JSON.parse(meta); } catch (_) { meta = {}; }
    }

    const identity = extractTaskIdentity({
      id: t.id,
      requirements: reqs,
      metadata: meta,
      targetUrl: (reqs && reqs.targetUrl) || (meta && meta.targetUrl),
      packageId: (reqs && reqs.packageId) || (meta && meta.packageId),
    });

    const keys = (identity.entityKeys && identity.entityKeys.length > 0)
      ? identity.entityKeys
      : (identity.entityKey ? [identity.entityKey] : []);

    if (identity.businessNameKey && !keys.includes(identity.businessNameKey)) {
      keys.push(identity.businessNameKey);
    }

    if (keys.length === 0) continue;

    const workers = new Set();
    if (t.assigned_to) workers.add(t.assigned_to.toString().trim());
    if (assignmentsByTask.has(t.id)) {
      for (const w of assignmentsByTask.get(t.id)) workers.add(w);
    }

    const allAliases = new Set();
    for (const w of workers) {
      const cleanW = w.toLowerCase().trim();
      allAliases.add(cleanW);
      if (aliasMap.has(cleanW)) {
        for (const alias of aliasMap.get(cleanW)) allAliases.add(alias);
      }
    }

    for (const wKey of allAliases) {
      for (const eKey of keys) {
        const cleanEKey = eKey.toLowerCase().trim();
        if (!cleanEKey) continue;
        try {
          await pool.query(
            \`INSERT INTO worker_completed_identities (worker_key, entity_key, task_id)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE task_id = VALUES(task_id)\`,
            [wKey, cleanEKey, t.id]
          );
          insertedCount++;
        } catch (_) {}
      }
    }
  }

  const [countRes] = await pool.query('SELECT COUNT(*) AS total FROM worker_completed_identities');
  console.log('Backfill finished. Processed inserts: ' + insertedCount + '. Total unique identity records: ' + countRes[0].total);
  await pool.end();
}

backfill().catch(e => { console.error('Backfill error:', e); process.exit(1); });
    `;

    await ssh.execCommand(`cat << 'EOF' > ${remoteBase}/backfill_identities.js\n${backfillScript}\nEOF`);
    const runBackfillRes = await ssh.execCommand(`node ${remoteBase}/backfill_identities.js`, { cwd: remoteBase });
    console.log('Backfill output:\n', runBackfillRes.stdout);
    if (runBackfillRes.stderr) console.warn('Backfill stderr:\n', runBackfillRes.stderr);

    console.log('\n🔄 Restarting PM2 backend services (task-engine-api, task-engine-worker)...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', { cwd: remoteBase });
    console.log(restartRes.stdout);

    console.log('⏳ Waiting 4s for services to stabilize...');
    await new Promise(r => setTimeout(r, 4000));

    console.log('🔍 Checking PM2 status...');
    const pm2Status = await ssh.execCommand('pm2 status');
    console.log(pm2Status.stdout);

    // Clean up temporary script
    await ssh.execCommand(`rm -f ${remoteBase}/backfill_identities.js`);

    ssh.dispose();
    console.log('🎉 Unique Reviews System deployed, built, and backfilled successfully!');
  } catch (error) {
    console.error('Deployment error:', error);
    if (ssh.isConnected()) ssh.dispose();
    process.exit(1);
  }
}

deployUniqueReviews();
