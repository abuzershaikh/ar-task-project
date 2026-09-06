const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  console.log('--- ls /var/www ---');
  const lsRes = await ssh.execCommand('ls -la /var/www');
  console.log(lsRes.stdout);

  console.log('--- Nginx search for reviewsgateway ---');
  const grepRes = await ssh.execCommand('grep -rn "reviewsgateway" /etc/nginx/');
  console.log(grepRes.stdout);

  ssh.dispose();
}
run();
