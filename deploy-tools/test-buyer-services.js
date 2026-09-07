const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const r1 = await ssh.execCommand('curl -sI http://127.0.0.1:3000/api/v1/buyer/services');
  console.log('1. Direct 3000 /buyer/services:', r1.stdout.split('\n')[0]);

  const r2 = await ssh.execCommand('curl -skI -H "Host: reviewsgateway.in" https://127.0.0.1/api/v1/buyer/services');
  console.log('2. Nginx reviewsgateway.in:', r2.stdout.split('\n')[0]);

  const r3 = await ssh.execCommand('curl -skI -H "Host: www.reviewsgateway.in" https://127.0.0.1/api/v1/buyer/services');
  console.log('3. Nginx www.reviewsgateway.in:', r3.stdout.split('\n')[0]);

  const r4 = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/buyer/services');
  console.log('4. Body length:', r4.stdout.length, 'Preview:', r4.stdout.substring(0, 150));

  ssh.dispose();
}
run().catch(console.error);
