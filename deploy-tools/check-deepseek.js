const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw'
  });
  console.log('Connected to VPS!');
  const res = await ssh.execCommand('grep -i deepseek /opt/task-engine/.env');
  console.log('DEEPSEEK IN .ENV:', res.stdout);
}

run().catch(console.error);
