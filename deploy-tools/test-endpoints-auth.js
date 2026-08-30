const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testEndpoints() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    const data = JSON.parse(loginRes.stdout);
    const token = data.data.accessToken;

    console.log('Got Access Token:', token.substring(0, 30) + '...');

    const adminServices = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/admin/services -H "Authorization: Bearer ${token}"`);
    console.log('\nAdmin Services API Response:\n', adminServices.stdout);

    const adminDashboard = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/admin/dashboard/stats -H "Authorization: Bearer ${token}"`);
    console.log('\nAdmin Dashboard Stats:\n', adminDashboard.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}
testEndpoints();
