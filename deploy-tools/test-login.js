const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const loginRes = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
  console.log('Login output:', loginRes.stdout);

  ssh.dispose();
}

main().catch(console.error);
