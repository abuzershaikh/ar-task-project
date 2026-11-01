const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const desc = await ssh.execCommand('pm2 describe task-engine');
  console.log(desc.stdout);

  ssh.dispose();
}

run().catch(console.error);
