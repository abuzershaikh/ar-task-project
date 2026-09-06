const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function testCertbot() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  console.log('Testing certbot dry run for swiftcommerce.in...');
  const res = await ssh.execCommand('certbot certonly --nginx --dry-run -d swiftcommerce.in --non-interactive --agree-tos -m admin@swiftcommerce.in');
  console.log('Certbot Output:\n', res.stdout || res.stderr);
  process.exit(0);
}
testCertbot().catch(e => { console.error(e); process.exit(1); });
