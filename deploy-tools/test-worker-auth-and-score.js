const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Testing Worker Auth & Role enforcement...');

  // 1. Get or create worker login token
  // Let's check worker_user@taskpost.com in DB
  const checkWorker = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT id, email, password FROM users WHERE email=\"worker_user@taskpost.com\";'");
  console.log('Worker DB check:\n', checkWorker.stdout);

  // Set known password for worker_user@taskpost.com so we can test login
  const setPassScript = `
const bcrypt = require('/opt/task-engine/node_modules/bcrypt');
const mysql = require('/opt/task-engine/node_modules/mysql2/promise');
async function run() {
  const hash = await bcrypt.hash('WorkerPass123!', 10);
  const conn = await mysql.createConnection({
    socketPath: '/var/run/mysqld/mysqld.sock',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });
  await conn.execute('UPDATE users SET password = ? WHERE email = "worker_user@taskpost.com"', [hash]);
  console.log('Worker password set to WorkerPass123!');
  await conn.end();
}
run();
`;
  await ssh.execCommand(`node -e "${setPassScript.replace(/\n/g, ' ')}"`);

  // Login as worker
  const wLogin = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"worker_user@taskpost.com","password":"WorkerPass123!"}'`);
  const wData = JSON.parse(wLogin.stdout);
  const workerToken = wData.data?.accessToken;
  console.log('Worker token obtained:', workerToken ? 'YES' : 'NO');

  if (workerToken) {
    // 2. Worker accessing Worker Score
    console.log('\n--- 1. Worker accessing /worker/score ---');
    const scoreRes = await ssh.execCommand(`curl -s -w "\nHTTP_STATUS: %{http_code}" -H "Authorization: Bearer ${workerToken}" http://localhost:3000/api/v1/worker/score`);
    console.log(scoreRes.stdout);

    // 3. Worker accessing Worker Profile
    console.log('\n--- 2. Worker accessing /worker/profile ---');
    const profRes = await ssh.execCommand(`curl -s -w "\nHTTP_STATUS: %{http_code}" -H "Authorization: Bearer ${workerToken}" http://localhost:3000/api/v1/worker/profile`);
    console.log(profRes.stdout);

    // 4. Worker attempting to access Admin Settings -> MUST BE 403 FORBIDDEN!
    console.log('\n--- 3. Worker attempting to access /admin/settings (Must be 403 Forbidden) ---');
    const forbiddenRes = await ssh.execCommand(`curl -s -w "\nHTTP_STATUS: %{http_code}" -H "Authorization: Bearer ${workerToken}" http://localhost:3000/api/v1/admin/settings`);
    console.log(forbiddenRes.stdout);
  }

  ssh.dispose();
}

run();
