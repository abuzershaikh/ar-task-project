const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function installCertbot() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  console.log('Installing epel-release and certbot on AlmaLinux 8...');
  const res1 = await ssh.execCommand('dnf install -y epel-release');
  console.log('EPEL:', res1.stdout.slice(-300));
  const res2 = await ssh.execCommand('dnf install -y certbot python3-certbot-nginx');
  console.log('Certbot install:', res2.stdout.slice(-300));
  const cb = await ssh.execCommand('certbot --version');
  console.log('Certbot version:\n', cb.stdout || cb.stderr);
  process.exit(0);
}
installCertbot().catch(e => { console.error(e); process.exit(1); });
