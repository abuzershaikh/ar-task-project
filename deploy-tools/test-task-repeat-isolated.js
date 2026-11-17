// Exercises token ownership using connection-local temporary tables only.
const assert = require('node:assert/strict');
const path = require('node:path');
const { randomUUID, createHash } = require('node:crypto');

async function main() {
  const backend = process.env.BACKEND_ROOT || '/opt/task-engine';
  const build = process.env.BACKEND_BUILD_DIR || path.join(backend, 'dist');
  require(path.join(backend, 'node_modules/dotenv')).config({ path: path.join(backend, '.env'), quiet: true });
  const mysql = require(path.join(backend, 'node_modules/mysql2/promise'));
  const { UserRepository } = require(path.join(build, 'shared/database/repositories/user.repository'));
  const { workerDeletionKey } = require(path.join(build, 'shared/services/worker-deletion-guard'));
  const { eligibleTaskPushTokens } = require(path.join(build, 'shared/common/utils/task-push-tokens.util'));
  const connection = await mysql.createConnection({ host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USERNAME || 'taskapp', password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_platform' });
  const query = async (sql, args) => (await connection.query(sql, args))[0];
  let failUpdate = false;
  const runner = { isTransactionActive: false,
    connect: async () => {}, release: async () => {},
    query: async (sql, args) => {
      if (failUpdate && sql.startsWith('UPDATE users SET metadata = JSON_SET')) throw new Error('injected update failure');
      return query(sql, args);
    },
    startTransaction: async () => { await connection.beginTransaction(); runner.isTransactionActive = true; },
    commitTransaction: async () => { await connection.commit(); runner.isTransactionActive = false; },
    rollbackTransaction: async () => { await connection.rollback(); runner.isTransactionActive = false; },
  };
  try {
    for (const table of ['users', 'deleted_worker_accounts']) {
      const definition = (await query(`SHOW CREATE TABLE ${table}`))[0]['Create Table'];
      await query(definition.replace(/^CREATE TABLE /, 'CREATE TEMPORARY TABLE '));
    }
    const token = `synthetic-task-push-${randomUUID()}`;
    for (const [id, metadata] of [['old', { fcmToken: token, deviceToken: token, keep: 'preserved' }],
      ['new', { keep: 'new-metadata' }], ['control', { fcmToken: token + '-control', keep: 'control' }]]) {
      await query(`INSERT INTO users (id,email,password,full_name,role,status,metadata) VALUES (?,?,? ,?,'WORKER','ACTIVE',?)`,
        [id, `${id}@example.invalid`, 'synthetic', 'Synthetic fixture', JSON.stringify(metadata)]);
    }
    const repository = new UserRepository({ manager: { connection: { createQueryRunner: () => runner } } });
    await repository.claimWorkerDeviceToken('new', token);
    await repository.claimWorkerDeviceToken('new', token);
    const read = async () => (await query('SELECT id,metadata FROM users')).map((row) => ({ ...row,
      metadata: typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata }));
    let rows = await read();
    assert.equal(rows.filter((row) => row.metadata.fcmToken === token || row.metadata.deviceToken === token).length, 1);
    assert.equal(rows.find((row) => row.id === 'old').metadata.keep, 'preserved');
    assert.equal(rows.find((row) => row.id === 'new').metadata.fcmToken, token);
    assert.equal(rows.find((row) => row.id === 'control').metadata.fcmToken, token + '-control');
    assert.deepEqual(eligibleTaskPushTokens(rows, new Set(['new'])), [token + '-control']);

    failUpdate = true;
    await assert.rejects(repository.claimWorkerDeviceToken('old', token), /injected update failure/);
    rows = await read();
    assert.equal(rows.find((row) => row.id === 'new').metadata.fcmToken, token);
    failUpdate = false;
    await query('INSERT INTO deleted_worker_accounts (identity_hash) VALUES (?)', [workerDeletionKey('old')]);
    await assert.rejects(repository.claimWorkerDeviceToken('old', token), /permanently deleted/);
    const lock = `push_owner_${createHash('sha256').update(token).digest('hex').slice(0, 48)}`;
    assert.equal((await query('SELECT IS_USED_LOCK(?) owner', [lock]))[0].owner, null);
    console.log('PASS: one token owner; other metadata preserved; transfer retry is idempotent; failed transfer rolls back; deleted worker rejected; lock released');
  } finally {
    await connection.end(); // Drops only these connection-local fixture tables.
  }
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
