const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand('ls -la /etc/nginx/conf.d/ && cat /etc/nginx/conf.d/*.conf');
  console.log(res.stdout);
  ssh.dispose();
}
run();
