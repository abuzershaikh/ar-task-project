const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectDb() {
  await ssh.connect({
    host: '95.179.178.6',
    username: 'root',
    password: 'i_G72#y}(6gACDDU'
  });
  
  console.log('--- TESTING ADMIN LOGIN & SERVICES ENDPOINT ---');
  const loginRes = await ssh.execCommand("curl -s -X POST -H 'Content-Type: application/json' -d '{\"email\":\"admin@taskplatform.com\",\"password\":\"AdminPassword123!\"}' http://localhost:3000/api/v1/auth/login");
  console.log('Admin Login:', loginRes.stdout);
  
  let token = '';
  try {
    const data = JSON.parse(loginRes.stdout);
    token = data.token || data.accessToken || '';
  } catch (_) {}

  const res = await ssh.execCommand(`curl -s -w '\nSTATUS:%{http_code}' -H 'Content-Type: application/json' -H 'Authorization: Bearer ${token}' http://localhost:3000/api/v1/admin/services`);
  console.log('Admin Services Response:\n', res.stdout);

  console.log('--- SERVICE PRICING SCHEMA ---');
  const sp = await ssh.execCommand("mysql -u root -p'i_G72#y}(6gACDDU' task_platform -e 'DESCRIBE service_pricing;'");
  console.log(sp.stdout || sp.stderr);

  ssh.dispose();
}

inspectDb();

