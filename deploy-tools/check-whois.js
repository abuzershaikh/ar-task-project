const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const script = `
python3 -c "
import socket
s = socket.socket()
s.connect(('whois.inregistry.net', 43))
s.sendall(b'reviewsgateway.in\\r\\n')
data = b''
while True:
    chunk = s.recv(4096)
    if not chunk: break
    data += chunk
print(data.decode(errors='ignore'))
"
`;
  const res = await ssh.execCommand(script);
  console.log('WHOIS DATA:\n', res.stdout);
  ssh.dispose();
  process.exit(0);
}

check().catch(e => { console.error(e); process.exit(1); });
