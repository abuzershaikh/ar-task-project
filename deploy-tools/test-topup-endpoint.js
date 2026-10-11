const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testTopups() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    const data = JSON.parse(loginRes.stdout);
    const token = data.data.accessToken;

    const topupsRes = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/admin/wallet/topups -H "Authorization: Bearer ${token}"`);
    console.log('\nTopups API Response:\n', topupsRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}
testTopups();
