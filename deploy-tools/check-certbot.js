const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const cb = await ssh.execCommand('which certbot || echo "no certbot"');
  console.log('Certbot:', cb.stdout);
  const os = await ssh.execCommand('cat /etc/os-release | grep PRETTY_NAME');
  console.log('OS:', os.stdout);
  process.exit(0);
}
check().catch(e => { console.error(e); process.exit(1); });
