const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders/google-business-info -H "Content-Type: application/json" -d '{"url":"https://share.google/rhI6QKATqwd8F3YY0"}'`);
  console.log('Current VPS response:', res.stdout);

  ssh.dispose();
}

main().catch(console.error);
