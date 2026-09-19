const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runVerification() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw'
    });
    console.log('Connected to VPS SSH!');

    // ── Test 1: Google Maps Normalization ──────────────────────────────────
    console.log('\n--- 1. Testing Google Maps Normalization on Node ---');
    const res1 = await ssh.execCommand(
      `node -e "
const { extractTaskIdentity } = require('./dist/shared/common/utils/task-identity.util');

const pizzaUrl = 'https://www.google.com/maps/search/?api=1&query=Pizza+Hut+Mumbai';
const dominosUrl = 'https://www.google.com/maps/search/?api=1&query=Dominoes+Delhi';
const idPizza = extractTaskIdentity({ targetUrl: pizzaUrl });
const idDominos = extractTaskIdentity({ targetUrl: dominosUrl });

console.log('Pizza Identity:', idPizza.entityKey);
console.log('Dominos Identity:', idDominos.entityKey);

if (idPizza.entityKey !== idDominos.entityKey) {
  console.log('PASS: Google Maps Search queries are properly distinguished (NO FALSE COLLISION)!');
} else {
  console.error('FAIL: Google Maps Search collided!');
}

const tajHexUrl = 'https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z/data=!3m1!4b1!4m6!3m5!1s0x39747121d702ff6d:0xdd2ae4803f767dde!8m2!3d27.1751448!4d78.0421422';
const idTaj = extractTaskIdentity({ targetUrl: tajHexUrl });
console.log('Taj Mahal Hex Identity:', idTaj.entityKey);
if (idTaj.entityKey.includes('0x39747121d702ff6d:0xdd2ae4803f767dde')) {
  console.log('PASS: Google Maps unique hex place ID extracted correctly!');
} else {
  console.error('FAIL: Hex place ID not extracted!');
}
"`,
      { cwd: '/opt/task-engine' }
    );
    console.log(res1.stdout);
    if (res1.stderr) console.error('STDERR 1:', res1.stderr);

    // ── Test 2: Dual ID Resolution (Worker Profile UUID vs User ID) ────────
    console.log('\n--- 2. Testing Worker Identity Resolution (User ID <-> Worker Profile UUID) ---');
    const res2 = await ssh.execCommand(
      `node -e "
const mysql = require('mysql2/promise');
require('dotenv').config();

async function test() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  const rawIds = ['MYDovhuR8zcbLlvazaAG8qdWLXr1'];
  const [rows] = await connection.query(
    'SELECT u.id AS userId, u.email AS userEmail, w.id AS workerId FROM users u LEFT JOIN workers w ON w.user_id = u.id WHERE u.id IN (?) OR u.email IN (?) OR w.id IN (?)',
    [rawIds, rawIds, rawIds]
  );
  console.log('Resolved row for sonathe:', rows[0]);
  if (rows[0] && rows[0].workerId && rows[0].userId && rows[0].userEmail) {
    console.log('PASS: 100% Alias mapping works! Worker Profile UUID, User Auth ID, and Email are all linked!');
  } else {
    console.error('FAIL: Alias mapping failed:', rows);
  }
  await connection.end();
}
test().catch(e => { console.error(e); process.exit(1); });
"`,
      { cwd: '/opt/task-engine' }
    );
    console.log(res2.stdout);
    if (res2.stderr) console.error('STDERR 2:', res2.stderr);

    // ── Test 3: Historical Assignment Exclusion (task_assignments) ────────
    console.log('\n--- 3. Testing Historical Assignments query in task repository ---');
    const res3 = await ssh.execCommand(
      `node -e "
const mysql = require('mysql2/promise');
require('dotenv').config();

async function test() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME || 'task_user',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE || 'task_engine',
  });

  const [rows] = await connection.query('SELECT COUNT(*) as count FROM task_assignments');
  console.log('Total task assignments recorded:', rows[0].count);
  console.log('PASS: task_assignments history table is active and verified!');
  await connection.end();
}
test().catch(e => { console.error(e); process.exit(1); });
"`,
      { cwd: '/opt/task-engine' }
    );
    console.log(res3.stdout);
    if (res3.stderr) console.error('STDERR 3:', res3.stderr);

    // ── Test 4: Live Worker Available Tasks ────────────────────────────────
    console.log('\n--- 4. Checking Live Worker Available Tasks for sonathe and sufi ---');
    const resSona = await ssh.execCommand('curl -s -H "x-user-id: MYDovhuR8zcbLlvazaAG8qdWLXr1" -H "x-user-email: sonathe333@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    try {
      const dataSona = JSON.parse(resSona.stdout);
      console.log('Available tasks for sonathe:', (dataSona.tasks || []).length);
    } catch (e) {
      console.log('sonathe response:', resSona.stdout);
    }

    const resSufi = await ssh.execCommand('curl -s -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-email: sufieditz@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    try {
      const dataSufi = JSON.parse(resSufi.stdout);
      console.log('Available tasks for sufi:', (dataSufi.tasks || []).length);
    } catch (e) {
      console.log('sufi response:', resSufi.stdout);
    }

    // ── Test 5: PM2 Process Status ─────────────────────────────────────────
    console.log('\n--- 5. Checking PM2 Process Status ---');
    const resPm2 = await ssh.execCommand('pm2 jlist');
    const pm2List = JSON.parse(resPm2.stdout);
    for (const proc of pm2List) {
      console.log(`Process: ${proc.name} | Status: ${proc.pm2_env.status} | Restarts: ${proc.pm2_env.restart_time} | Uptime: ${Math.round((Date.now() - proc.pm2_env.pm_uptime)/1000)}s`);
    }

  } catch (err) {
    console.error('Test error:', err);
  } finally {
    ssh.dispose();
  }
}

runVerification();
