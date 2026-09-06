const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function openHttps() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  console.log('Opening port 443 (HTTPS) in firewall...');
  const r1 = await ssh.execCommand('firewall-cmd --permanent --add-service=https || firewall-cmd --permanent --add-port=443/tcp');
  console.log(r1.stdout);
  const r2 = await ssh.execCommand('firewall-cmd --reload');
  console.log(r2.stdout);
  const list = await ssh.execCommand('firewall-cmd --list-all');
  console.log('Updated firewall:\n', list.stdout);
  process.exit(0);
}
openHttps().catch(e => { console.error(e); process.exit(1); });
