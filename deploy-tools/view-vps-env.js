const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw'
  });
  const res = await ssh.execCommand('cat /opt/task-engine/.env');
  console.log('VPS .ENV CONTENT:\n', res.stdout);
}

run().catch(console.error);
