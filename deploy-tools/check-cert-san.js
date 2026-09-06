const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res = await ssh.execCommand('openssl x509 -text -noout -in /etc/letsencrypt/live/reviewsgateway.in/fullchain.pem | grep -A 2 "Subject Alternative Name"');
  console.log('CERT SANs:\n', res.stdout);
  ssh.dispose();
  process.exit(0);
}

check();
