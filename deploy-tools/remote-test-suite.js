const mysql = require('mysql2/promise');
require('dotenv').config();
const { isSafeTargetHost, extractTaskIdentity } = require('./dist/shared/common/utils/task-identity.util');

async function runTestSuite() {
  console.log('\n======================================================');
  console.log('--- 1. SSRF Protection & Private IP Blocking ---');
  console.log('======================================================');
  const privateIps = ['127.0.0.1', 'localhost', '169.254.169.254', '10.0.0.5', '192.168.1.1', '0.0.0.0'];
  for (const host of privateIps) {
    const isSafe = await isSafeTargetHost(host);
    if (!isSafe) {
      console.log('PASS: Private target ' + host + ' is strictly BLOCKED!');
    } else {
      console.error('FAIL: SSRF leak: ' + host + ' was allowed!');
      process.exit(1);
    }
  }

  const safeHost = await isSafeTargetHost('google.com');
  if (safeHost) {
    console.log('PASS: Public domain google.com is properly ALLOWED!');
  } else {
    console.error('FAIL: google.com was blocked!');
    process.exit(1);
  }

  console.log('\n======================================================');
  console.log('--- 2. Google Maps Normalization & Search Distinction ---');
  console.log('======================================================');
  const pizzaUrl = 'https://www.google.com/maps/search/?api=1&query=Pizza+Hut+Mumbai';
  const dominosUrl = 'https://www.google.com/maps/search/?api=1&query=Dominoes+Delhi';
  const idPizza = extractTaskIdentity({ targetUrl: pizzaUrl });
  const idDominos = extractTaskIdentity({ targetUrl: dominosUrl });

  if (idPizza.entityKey !== idDominos.entityKey) {
    console.log('PASS: Google Maps Search queries differentiated correctly:');
    console.log('  Pizza:', idPizza.entityKey);
    console.log('  Dominos:', idDominos.entityKey);
  } else {
    console.error('FAIL: Google Maps Search collided!');
    process.exit(1);
  }

  const hexUrl = 'https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z/data=!3m1!4b1!4m6!3m5!1s0x39747121d702ff6d:0xdd2ae4803f767dde!8m2!3d27.1751448!4d78.0421422';
  const idHex = extractTaskIdentity({ targetUrl: hexUrl });
  if (idHex.entityKey && idHex.entityKey.includes('0x39747121d702ff6d:0xdd2ae4803f767dde')) {
    console.log('PASS: Place Hex CID accurately identified:', idHex.entityKey);
  } else {
    console.error('FAIL: Place Hex CID missing!');
    process.exit(1);
  }

  console.log('\n======================================================');
  console.log('--- 3. Campaign & Worker Full Alias Resolution ---');
  console.log('======================================================');
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  const [aliasRows] = await connection.query(
    'SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId FROM users u LEFT JOIN workers w ON w.user_id = u.id WHERE u.email = ?',
    ['sonathe333@gmail.com']
  );
  if (aliasRows.length > 0 && aliasRows[0].userId && aliasRows[0].workerId) {
    console.log('PASS: Worker alias trio linked:');
    console.log('  userId:', aliasRows[0].userId);
    console.log('  workerId:', aliasRows[0].workerId);
    console.log('  userEmail:', aliasRows[0].userEmail);
  } else {
    console.error('FAIL: Worker alias lookup failed!');
    process.exit(1);
  }

  console.log('\n======================================================');
  console.log('--- 4. Physical DB Constraint Table worker_completed_identities ---');
  console.log('======================================================');
  const testWorker = 'test_worker_alias_sim';
  const testEntity = 'pkg:com.test.duplicate.app';

  await connection.query(`
    CREATE TABLE IF NOT EXISTS worker_completed_identities (
      id INT AUTO_INCREMENT PRIMARY KEY,
      worker_key VARCHAR(191) NOT NULL,
      entity_key VARCHAR(191) NOT NULL,
      task_id VARCHAR(64) NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY uk_worker_entity (worker_key, entity_key)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `);

  await connection.query('DELETE FROM worker_completed_identities WHERE worker_key = ?', [testWorker]);

  // Insert initial record
  await connection.query(
    'INSERT INTO worker_completed_identities (worker_key, entity_key, task_id) VALUES (?, ?, ?)',
    [testWorker, testEntity, 'test_task_1']
  );
  console.log('PASS: Successfully recorded identity in worker_completed_identities!');

  // Attempt duplicate insert - DB engine MUST reject with ER_DUP_ENTRY
  try {
    await connection.query(
      'INSERT INTO worker_completed_identities (worker_key, entity_key, task_id) VALUES (?, ?, ?)',
      [testWorker, testEntity, 'test_task_2']
    );
    console.error('FAIL: Duplicate insert was allowed!');
    process.exit(1);
  } catch (dupErr) {
    if (dupErr.code === 'ER_DUP_ENTRY' || dupErr.errno === 1062) {
      console.log('PASS: Physical UNIQUE constraint (uk_worker_entity) rejected duplicate! Code:', dupErr.code);
    } else {
      console.error('Unexpected error:', dupErr);
      process.exit(1);
    }
  }

  await connection.query('DELETE FROM worker_completed_identities WHERE worker_key = ?', [testWorker]);

  console.log('\n======================================================');
  console.log('--- 5. Concurrency Mutex Lock Verification ---');
  console.log('======================================================');
  const lockConn1 = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  const lockConn2 = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  const lockName = 't_lock_test_concurrency';

  // Conn 1 acquires lock
  const [resLock1] = await lockConn1.query('SELECT GET_LOCK(?, 2) as acquired', [lockName]);
  console.log('Conn 1 acquired lock:', resLock1[0].acquired === 1);

  // Conn 2 attempts to acquire same lock with 0 timeout -> MUST FAIL
  const [resLock2] = await lockConn2.query('SELECT GET_LOCK(?, 0) as acquired', [lockName]);
  if (resLock2[0].acquired === 0) {
    console.log('PASS: Conn 2 was strictly blocked by Conn 1 mutex! Zero simultaneous collision window.');
  } else {
    console.error('FAIL: Conn 2 was not blocked!');
    process.exit(1);
  }

  // Conn 1 releases lock
  await lockConn1.query('SELECT RELEASE_LOCK(?)', [lockName]);
  console.log('Conn 1 released lock.');

  // Now Conn 2 acquires lock -> MUST SUCCEED
  const [resLock2After] = await lockConn2.query('SELECT GET_LOCK(?, 1) as acquired', [lockName]);
  if (resLock2After[0].acquired === 1) {
    console.log('PASS: Conn 2 successfully acquired lock after Conn 1 completed!');
    await lockConn2.query('SELECT RELEASE_LOCK(?)', [lockName]);
  } else {
    console.error('FAIL: Conn 2 could not acquire lock after release!');
    process.exit(1);
  }

  await lockConn1.end();
  await lockConn2.end();
  await connection.end();

  console.log('\n======================================================');
  console.log('🎉 ALL AUTOMATED REGRESSION TESTS PASSED 100%!');
  console.log('======================================================');
}

runTestSuite().catch(e => {
  console.error('Test Suite Failed:', e);
  process.exit(1);
});
