const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function test() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const r1 = await ssh.execCommand('curl -sI -H "Host: reviewsgateway.in" http://127.0.0.1');
  console.log('HTTP reviewsgateway.in:\n', r1.stdout);
  const r2 = await ssh.execCommand('curl -sI -H "Host: www.reviewsgateway.in" http://127.0.0.1');
  console.log('HTTP www.reviewsgateway.in:\n', r2.stdout);
  const r3 = await ssh.execCommand('curl -sI -k -H "Host: reviewsgateway.in" https://127.0.0.1');
  console.log('HTTPS reviewsgateway.in:\n', r3.stdout);
  ssh.dispose();
  process.exit(0);
}

test();
