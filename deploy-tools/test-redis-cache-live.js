const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== CHECK PM2 LOGS FOR REDIS CACHE INITIALIZATION ===');
    const logs = await ssh.execCommand('grep -i "RedisCacheService" /root/.pm2/logs/task-engine-api-out-0.log | tail -n 5');
    console.log(logs.stdout || logs.stderr || 'No explicit log, checking startup...');

    // Run test script directly inside VPS against 127.0.0.1:3000
    const testScript = `
const http = require('http');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/opt/task-engine/.env' });

async function test() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE,
  });

  const [users] = await conn.query("SELECT id, email FROM users WHERE role = 'WORKER' LIMIT 1");
  await conn.end();

  if (!users || users.length === 0) {
    console.log('No worker found');
    return;
  }
  const worker = users[0];
  console.log('Testing with worker:', worker.email, worker.id);

  // Generate a mock or real JWT or test via internal endpoint
  // Let's check redis keys directly:
  const Redis = require('ioredis');
  const redis = new Redis();
  const keys = await redis.keys('cache:worker:*');
  console.log('Current Redis worker cache keys:', keys);
  await redis.quit();
}
test().catch(console.error);
`;

    const res = await ssh.execCommand(`cd /opt/task-engine && node -e "${testScript.replace(/"/g, '\\"').replace(/\$/g, '\\$')}"`);
    console.log(res.stdout || res.stderr);

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
