const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Connecting and logging in as admin on VPS...');
  const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`;
  const loginRes = await ssh.execCommand(loginCmd);
  const data = JSON.parse(loginRes.stdout);
  const token = data.data?.accessToken || data.data?.token || data.token;
  console.log('Admin token:', token ? 'Got Token' : 'Failed');

  if (token) {
    console.log('\n--- 1. Testing GET /admin/settings/task-expiry ---');
    const getRes = await ssh.execCommand(`curl -s -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/settings/task-expiry`);
    console.log(getRes.stdout);

    console.log('\n--- 2. Testing POST /admin/settings/task-expiry (Update settings) ---');
    const postRes = await ssh.execCommand(`curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -d '{"workerExecutionTimeoutHours":2.0,"unacceptedTaskExpiryHours":24.0,"autoReassignOnExpiry":true}' http://localhost:3000/api/v1/admin/settings/task-expiry`);
    console.log(postRes.stdout);

    console.log('\n--- 3. Testing POST /admin/settings/task-expiry/trigger (Run deadline monitor cycle) ---');
    const triggerRes = await ssh.execCommand(`curl -s -X POST -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/settings/task-expiry/trigger`);
    console.log(triggerRes.stdout);

    console.log('\n--- 4. Checking recent PM2 logs for DeadlineMonitorService ---');
    const logsRes = await ssh.execCommand(`pm2 logs task-engine-api --lines 40 --nostream | grep -i "deadline"`);
    console.log(logsRes.stdout);
  }

  ssh.dispose();
}

run().catch(console.error);
