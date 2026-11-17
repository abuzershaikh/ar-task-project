// Uses connection-local TEMPORARY tables cloned from the live schema. Never calls
// a production DELETE endpoint or writes to permanent application tables.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { randomUUID } = require('node:crypto');

async function main() {
  const backend = process.env.BACKEND_ROOT || '/opt/task-engine';
  const build = process.env.BACKEND_BUILD_DIR || path.join(backend, 'dist');
  require(path.join(backend, 'node_modules/dotenv')).config({ path: path.join(backend, '.env'), quiet: true });
  const mysql = require(path.join(backend, 'node_modules/mysql2/promise'));
  const { WorkerDeletionService } = require(path.join(build, 'shared/services/worker-deletion.service'));
  const { assertWorkerAccountNotDeleted } = require(path.join(build, 'shared/services/worker-deletion-guard'));
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost', user: process.env.DB_USERNAME || 'taskapp',
    password: process.env.DB_PASSWORD, database: process.env.DB_DATABASE || 'task_platform',
  });
  const scratch = await fs.mkdtemp(path.join(os.tmpdir(), 'worker-delete-test-'));
  const originalCwd = process.cwd();
  const tables = ['users', 'workers', 'tasks', 'orders', 'order_units', 'files', 'support_messages',
    'support_conversations', 'task_submissions', 'task_assignments', 'campaign_worker_participation',
    'worker_scores', 'kyc_profiles', 'earnings', 'withdrawals', 'payment_methods', 'ratings',
    'worker_completed_identities', 'notifications', 'wallets', 'wallet_transactions', 'audit_logs'];
  const query = async (sql, params) => (await connection.query(sql, params))[0];
  let injectFailure = false;
  const db = {
    query,
    transaction: async (run) => {
      await connection.beginTransaction();
      try {
        const value = await run({ query: (sql, args) => {
          if (injectFailure && sql.startsWith('DELETE FROM kyc_profiles')) throw new Error('injected SQL failure');
          return query(sql, args);
        } });
        await connection.commit();
        return value;
      } catch (error) {
        await connection.rollback();
        throw error;
      }
    },
  };
  try {
    for (const table of tables) {
      const definition = (await query(`SHOW CREATE TABLE ${table}`))[0]['Create Table'];
      await query(definition.replace(/^CREATE TABLE /, 'CREATE TEMPORARY TABLE '));
    }
    await query(`CREATE TEMPORARY TABLE deleted_worker_accounts (identity_hash CHAR(64) PRIMARY KEY, deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB`);
    const columns = new Map();
    const insert = async (table, data) => {
      if (!columns.has(table)) columns.set(table, await query(`SHOW COLUMNS FROM ${table}`));
      const values = { ...data };
      for (const column of columns.get(table)) {
        if (column.Field in values || column.Null === 'YES' || column.Default !== null || column.Extra.includes('auto_increment')) continue;
        const type = column.Type;
        values[column.Field] = column.Field === 'id' ? randomUUID()
          : type.startsWith('enum(') ? type.match(/'([^']+)'/)[1]
          : /int|decimal|double|float|bit/.test(type) ? 0
          : /timestamp|datetime/.test(type) ? '2026-01-01 00:00:00'
          : type.startsWith('date') ? '2000-01-01' : '{}';
      }
      const keys = Object.keys(values);
      await query(`INSERT INTO ${table} (${keys.map((key) => '`' + key + '`').join(',')}) VALUES (${keys.map(() => '?').join(',')})`, Object.values(values));
    };
    const seed = async () => {
      for (const table of tables) await query(`DELETE FROM ${table}`); // Every name is now a TEMPORARY table.
      await query('DELETE FROM deleted_worker_accounts');
      await insert('users', { id: 'delete-user', email: 'delete@example.test', role: 'WORKER' });
      await insert('users', { id: 'keep-user', email: 'keep@example.test', role: 'WORKER' });
      await insert('workers', { id: 'delete-worker', user_id: 'delete-user' });
      await insert('workers', { id: 'keep-worker', user_id: 'keep-user' });
      await insert('orders', { id: 'order-test', buyer_id: 'unrelated-buyer', total_tasks_required: 3, tasks_completed: 3, status: 'COMPLETED' });
      for (const who of ['delete', 'keep']) {
        await insert('order_units', { id: `${who}-unit`, order_id: 'order-test', unit_number: who === 'delete' ? 1 : 2, status: 'COMPLETED' });
        await insert('tasks', { id: `${who}-task`, order_id: 'order-test', campaign_id: 'order-test', order_unit_id: `${who}-unit`,
          assigned_to: `${who}-user`, worker_id: `${who}-worker`, status: 'COMPLETED', attempt_count: 3, metadata: '{"proof":"test"}' });
        for (const table of ['task_submissions', 'task_assignments', 'campaign_worker_participation', 'worker_scores',
          'kyc_profiles', 'earnings', 'withdrawals', 'payment_methods', 'ratings']) {
          const data = { id: `${who}-${table}`, worker_id: `${who}-worker` };
          if (['task_submissions', 'task_assignments', 'earnings', 'ratings'].includes(table)) data.task_id = `${who}-task`;
          await insert(table, data);
        }
        await insert('worker_completed_identities', { worker_key: `${who}-worker`, entity_key: `${who}-identity`, task_id: `${who}-task` });
        await insert('wallets', { id: `${who}-wallet`, user_id: `${who}-user` });
        await insert('wallet_transactions', { id: `${who}-transaction`, wallet_id: `${who}-wallet` });
        await insert('notifications', { id: `${who}-notification`, user_id: `${who}-user` });
        await insert('files', { id: `${who}-file`, uploaded_by: `${who}-user`, file_name: `${who}.txt` });
        await insert('support_conversations', { id: `${who}-conversation`, worker_id: who === 'delete' ? 'delete-firebase' : 'keep-user' });
        await insert('support_messages', { id: `${who}-message`, conversation_id: `${who}-conversation`, worker_id: `${who}-user`,
          media_url: `https://reviewsgateway.in/support-chat/uploads/${who === 'keep' ? 'shared' : who}.txt` });
        await insert('audit_logs', { id: `${who}-audit`, actor_id: `${who}-user`, entity_id: `${who}-worker` });
      }
      await insert('tasks', { id: 'legacy-owned', order_id: 'order-test', campaign_id: 'order-test', assigned_to: null,
        worker_id: 'delete-worker', status: 'COMPLETED', attempt_count: 2 });
      await insert('tasks', { id: 'reassigned', order_id: 'order-test', campaign_id: 'order-test', assigned_to: 'keep-user',
        worker_id: 'delete-worker', status: 'STARTED', attempt_count: 2 });
      await insert('support_messages', { id: 'delete-shared-message', conversation_id: 'delete-conversation', worker_id: 'delete-user',
        media_url: 'https://reviewsgateway.in/support-chat/uploads/shared.txt' });
      await fs.writeFile(path.join(scratch, 'support', 'shared.txt'), 'shared admin attachment');
      for (const who of ['delete', 'keep']) {
        await fs.writeFile(path.join(scratch, 'uploads', `${who}.txt`), 'proof');
        await fs.writeFile(path.join(scratch, 'support', `${who}.txt`), 'chat');
      }
    };
    await fs.mkdir(path.join(scratch, 'uploads'));
    await fs.mkdir(path.join(scratch, 'support'));
    process.chdir(scratch);
    process.env.SUPPORT_CHAT_UPLOAD_DIR = path.join(scratch, 'support');
    const deletedAuth = [];
    const deletedDocs = [];
    const missing = () => Promise.reject({ code: 'auth/user-not-found' });
    const firebase = {
      auth: { getUserByEmail: async () => ({ uid: 'delete-firebase' }), getUser: missing,
        revokeRefreshTokens: async () => {}, deleteUser: async (uid) => deletedAuth.push(uid) },
      firestore: { collection: () => ({ doc: (id) => ({ path: `users/${id}` }), where: () => ({ get: async () => ({ docs: [] }) }) }),
        recursiveDelete: async (doc) => deletedDocs.push(doc.path) },
    };
    const service = new WorkerDeletionService(db, firebase, { invalidateWorker: async () => {} });
    const resolved = { worker: { id: 'delete-worker', userId: 'delete-user' },
      user: { id: 'delete-user', email: 'delete@example.test', role: 'WORKER' }, searchIds: ['delete-worker', 'delete-user', 'delete@example.test'] };
    await seed();
    await service.deleteWorker('delete-worker', resolved);
    for (const table of tables.filter((table) => !['tasks', 'orders', 'order_units'].includes(table))) {
      assert.equal((await query(`SELECT COUNT(*) n FROM ${table}`))[0].n, 1, `${table}: only control worker remains`);
    }
    const tasks = await query('SELECT * FROM tasks ORDER BY id');
    for (const task of tasks.filter((task) => ['delete-task', 'legacy-owned'].includes(task.id))) {
      assert.equal(task.assigned_to, null);
      assert.equal(task.worker_id, null);
      assert.equal(task.attempt_count, 0);
      assert.equal(task.metadata, null);
      assert.equal(task.status, 'ACTIVE');
    }
    assert.equal(tasks.find((task) => task.id === 'keep-task').status, 'COMPLETED');
    assert.equal(tasks.find((task) => task.id === 'reassigned').status, 'STARTED');
    assert.equal(tasks.find((task) => task.id === 'reassigned').worker_id, null);
    assert.equal((await query('SELECT tasks_completed FROM orders'))[0].tasks_completed, 1);
    assert.equal((await query("SELECT status FROM order_units WHERE id='delete-unit'"))[0].status, 'PENDING');
    assert.equal((await query("SELECT status FROM order_units WHERE id='keep-unit'"))[0].status, 'COMPLETED');
    for (const dir of ['uploads', 'support']) {
      await assert.rejects(fs.access(path.join(scratch, dir, 'delete.txt')));
      await fs.access(path.join(scratch, dir, 'keep.txt'));
    }
    await fs.access(path.join(scratch, 'support', 'shared.txt'));
    assert.ok(deletedAuth.includes('delete-firebase'));
    assert.ok(deletedDocs.includes('users/delete-firebase'));
    for (const identity of ['delete-worker', 'delete-user', 'DELETE@example.test', 'delete-firebase']) {
      await assert.rejects(assertWorkerAccountNotDeleted(db, identity), /permanently deleted/);
    }
    await service.deleteWorker('delete-worker', { worker: null, user: null, searchIds: ['delete-worker'] });
    console.log('PASS: complete cleanup across 19 worker stores; other worker preserved; task slots released; files removed; all old identities blocked; repeat deletion succeeds');

    const sandbox = {
      module: { exports: {} }, console,
      require: (name) => {
        if (name === '../config/db') return { pool: { query: async (sql, args) => [await query(sql, args)] } };
        if (name === 'uuid') return { v4: randomUUID };
        if (name === './fcm.service') return { sendWorkerChatNotification: async () => {}, sendBulkWorkerChatNotifications: async () => {} };
        if (name === '../config/firebase') return { auth: () => ({ getUser: missing }) };
        if (name === 'crypto') return require('node:crypto');
        throw new Error(`Unexpected support dependency: ${name}`);
      },
    };
    require('node:vm').runInNewContext(await fs.readFile(process.env.SUPPORT_CHAT_SERVICE_FILE || '/opt/support-chat-engine/src/services/chat.service.js', 'utf8'), sandbox);
    const chat = sandbox.module.exports;
    await assert.rejects(chat.getOrCreateConversation('delete-user'), /permanently deleted/);
    const fresh = await chat.getOrCreateConversation('fresh-worker', { name: 'Fresh Worker', email: 'fresh@example.test' });
    const message = await chat.createMessage({ conversationId: fresh.id, workerId: 'fresh-worker', senderType: 'WORKER', content: 'Synthetic test' });
    assert.equal(message.content, 'Synthetic test');
    await assert.rejects(chat.createMessage({ conversationId: fresh.id, workerId: 'delete-user', senderType: 'WORKER' }), /permanently deleted/);
    console.log('PASS: real support-chat SQL permits normal conversations/messages and rejects deleted identities');

    await seed();
    injectFailure = true;
    await assert.rejects(service.deleteWorker('delete-worker', resolved), /injected SQL failure/);
    for (const table of tables.filter((table) => !['tasks', 'orders', 'order_units'].includes(table))) {
      assert.equal((await query(`SELECT COUNT(*) n FROM ${table}`))[0].n, table === 'support_messages' ? 3 : 2, `${table}: rollback preserves both SQL records`);
    }
    assert.equal((await query("SELECT status FROM tasks WHERE id='delete-task'"))[0].status, 'COMPLETED');
    assert.equal((await query('SELECT tasks_completed FROM orders'))[0].tasks_completed, 3);
    console.log('PASS: injected mid-cleanup failure rolls back every SQL change; deletion intent remains for safe retry');

    if (process.env.REAL_FIREBASE_FIXTURE === '1') {
      const { FirebaseAdminService } = require(path.join(build, 'shared/services/firebase-admin.service'));
      const realFirebase = new FirebaseAdminService();
      realFirebase.onModuleInit();
      const uid = `worker-delete-verification-${randomUUID()}`;
      const email = `${uid}@example.invalid`;
      const profile = realFirebase.firestore.collection('users').doc(uid);
      const child = profile.collection('deletion_verification').doc('synthetic');
      let created = false;
      try {
        await realFirebase.auth.createUser({ uid, email });
        created = true;
        await profile.set({ uid, email, role: 'WORKER', syntheticDeletionVerification: true });
        await child.set({ synthetic: true });
        const realService = new WorkerDeletionService(db, realFirebase, { invalidateWorker: async () => {} });
        await realService.deleteFirebaseAccount([uid, email], email);
        await assert.rejects(realFirebase.auth.getUser(uid), (error) => error.code === 'auth/user-not-found');
        assert.equal((await profile.get()).exists, false);
        assert.equal((await child.get()).exists, false);
        console.log('PASS: real Firebase synthetic account, profile, and nested document deleted; no real worker account touched');
      } finally {
        if (created) {
          await realFirebase.auth.deleteUser(uid).catch((error) => { if (error.code !== 'auth/user-not-found') throw error; });
          await realFirebase.firestore.recursiveDelete(profile);
        }
      }
    }
  } finally {
    process.chdir(originalCwd);
    await connection.end(); // Automatically drops every TEMPORARY table.
    assert.ok(scratch.startsWith(path.join(os.tmpdir(), 'worker-delete-test-')));
    await fs.rm(scratch, { recursive: true, force: true });
  }
}

main().catch((error) => { console.error(error.message, error.sql || ''); process.exitCode = 1; });
