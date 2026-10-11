const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Logging in as admin on VPS...');
  const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`;
  const loginRes = await ssh.execCommand(loginCmd);
  const data = JSON.parse(loginRes.stdout);
  const token = data.data?.accessToken || data.data?.token || data.token;
  console.log('Admin token:', token ? 'Got Token' : 'Failed');

  if (token) {
    const res = await ssh.execCommand(`curl -s -w "\nHTTP_STATUS: %{http_code}" -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/settings/review-auto-approve`);
    console.log('Result from GET /admin/settings/review-auto-approve:');
    console.log(res.stdout);
  }

  ssh.dispose();
}

run().catch(console.error);
