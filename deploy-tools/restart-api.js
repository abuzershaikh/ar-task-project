const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function restartApi() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const r = await ssh.execCommand('pm2 restart task-engine-api');
  console.log(r.stdout);
  ssh.dispose();
}

restartApi().catch(console.error);
