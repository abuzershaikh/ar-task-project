const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testServices() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    console.log('Login Raw Output:', loginRes.stdout);
    const data = JSON.parse(loginRes.stdout);
    const token = data.data.accessToken;

    const servicesRes = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/admin/services -H "Authorization: Bearer ${token}"`);
    console.log('\nAdmin Services API Output:\n', servicesRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}
testServices();
