const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const df = await ssh.execCommand('df -h /');
  console.log('VPS Disk Space:\n', df.stdout);
  process.exit(0);
}

check().catch(e => { console.error(e); process.exit(1); });
