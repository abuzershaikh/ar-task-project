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

  console.log('--- Nginx conf files ---');
  const confRes = await ssh.execCommand('cat /etc/nginx/conf.d/*.conf');
  console.log(confRes.stdout);

  console.log('--- ls /var/www/task-platform ---');
  const tpRes = await ssh.execCommand('ls -la /var/www/task-platform');
  console.log(tpRes.stdout);

  ssh.dispose();
}
run();
