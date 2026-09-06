const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res = await ssh.execCommand('python3 -c "import socket; s=socket.socket(); s.connect((\'whois.registry.in\', 43)); s.sendall(b\'swiftcommerce.in\\r\\n\'); print(s.recv(4096).decode())"');
  console.log('WHOIS REGISTRY:\n', res.stdout);
  process.exit(0);
}
check().catch(e => { console.error(e); process.exit(1); });
