const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('--- reviewsgateway.conf ---');
  const conf = await ssh.execCommand('cat /etc/nginx/conf.d/reviewsgateway.conf');
  console.log(conf.stdout);

  ssh.dispose();
}

run().catch(console.error);
