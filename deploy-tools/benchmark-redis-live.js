const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const testScript = `
const { JwtService } = require('@nestjs/jwt');
const http = require('http');
const mysql = require('mysql2/promise');
const Redis = require('ioredis');
require('dotenv').config({ path: '/opt/task-engine/.env' });

function request(path, token) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const req = http.request({
      hostname: '127.0.0.1',
      port: 3000,
      path,
      method: 'GET',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
      },
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const duration = Date.now() - start;
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data), duration });
        } catch (_) {
          resolve({ status: res.statusCode, raw: data, duration });
        }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

async function test() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE,
  });

  const [users] = await conn.query("SELECT * FROM users WHERE role = 'WORKER' LIMIT 1");
  await conn.end();

  const user = users[0];
  console.log('Worker found:', user.email, 'ID:', user.id);

  const jwtService = new JwtService({ secret: process.env.JWT_SECRET || 'your_secret_key' });
  const token = jwtService.sign(
    { sub: user.id, id: user.id, email: user.email, role: user.role }
  );

  console.log('\\n--- TEST 1: WALLET CACHE (15s TTL) ---');
  const w1 = await request('/api/v1/worker/earnings/wallet', token);
  console.log('Call 1 (DB fetch): ' + w1.duration + 'ms | Status: ' + w1.status + ' | _fromCache: ' + (w1.data ? w1.data._fromCache : false));

  const w2 = await request('/api/v1/worker/earnings/wallet', token);
  console.log('Call 2 (Redis Cache): ' + w2.duration + 'ms | Status: ' + w2.status + ' | _fromCache: ' + (w2.data ? w2.data._fromCache : false));

  const w3 = await request('/api/v1/worker/earnings/wallet', token);
  console.log('Call 3 (Redis Cache): ' + w3.duration + 'ms | Status: ' + w3.status + ' | _fromCache: ' + (w3.data ? w3.data._fromCache : false));

  console.log('\\n--- TEST 2: AVAILABLE TASKS CACHE (5s TTL) ---');
  const t1 = await request('/api/v1/worker/tasks/available', token);
  console.log('Call 1 (DB fetch): ' + t1.duration + 'ms | Status: ' + t1.status + ' | Tasks count: ' + (t1.data && t1.data.tasks ? t1.data.tasks.length : 0) + ' | _fromCache: ' + (t1.data ? t1.data._fromCache : false));

  const t2 = await request('/api/v1/worker/tasks/available', token);
  console.log('Call 2 (Redis Cache): ' + t2.duration + 'ms | Status: ' + t2.status + ' | Tasks count: ' + (t2.data && t2.data.tasks ? t2.data.tasks.length : 0) + ' | _fromCache: ' + (t2.data ? t2.data._fromCache : false));

  console.log('\\n--- REDIS KEYS IN RAM ---');
  const redis = new Redis();
  const keys = await redis.keys('cache:worker:*');
  for (const k of keys) {
    const ttl = await redis.ttl(k);
    console.log('Key: ' + k + ' | TTL remaining: ' + ttl + 's');
  }
  await redis.quit();
}
test().catch(console.error);
`;

    // Write file to /opt/task-engine/ and execute
    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/test-cache-bench.js\n${testScript}\nEOF`);
    const res = await ssh.execCommand('cd /opt/task-engine && node test-cache-bench.js');
    console.log(res.stdout || res.stderr);
    await ssh.execCommand('rm -f /opt/task-engine/test-cache-bench.js');

  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

run();
