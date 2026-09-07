const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Testing Admin Login with snapbizux@gmail.com / 80978097...');
  const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`;
  const loginRes = await ssh.execCommand(loginCmd);

  try {
    const data = JSON.parse(loginRes.stdout);
    const token = data.data?.accessToken || data.data?.token || data.token;
    console.log('Token extracted:', token ? 'YES' : 'NO');
    if (token) {
      console.log('\n--- 1. Testing GET /api/v1/admin/settings with Bearer token ---');
      const adminRes = await ssh.execCommand(`curl -s -w "\nHTTP_STATUS: %{http_code}" -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/settings`);
      console.log(adminRes.stdout);

      console.log('\n--- 2. Testing GET /api/v1/admin/dashboard with Bearer token ---');
      const dashRes = await ssh.execCommand(`curl -s -w "\nHTTP_STATUS: %{http_code}" -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/dashboard`);
      console.log(dashRes.stdout);
    }
  } catch (err) {
    console.error(err);
  }

  ssh.dispose();
}

run();
