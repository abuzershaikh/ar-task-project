const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand('ls -la /var/www/buyer-web && head -n 30 /var/www/buyer-web/index.html');
  console.log('--- /var/www/buyer-web ---');
  console.log(res.stdout);

  const curlRes = await ssh.execCommand('curl -s https://reviewsgateway.in/ | head -n 30');
  console.log('--- curl https://reviewsgateway.in/ ---');
  console.log(curlRes.stdout);

  ssh.dispose();
}
run();
