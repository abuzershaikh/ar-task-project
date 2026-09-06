const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const dig = await ssh.execCommand('dig swiftcommerce.in +trace');
  console.log('DIG TRACE:\n', dig.stdout);
  process.exit(0);
}
check().catch(e => { console.error(e); process.exit(1); });
