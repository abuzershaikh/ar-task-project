const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res = await ssh.execCommand('ls -la /opt/task-engine');
  console.log(res.stdout);
  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
