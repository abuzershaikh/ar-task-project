const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res = await ssh.execCommand('grep -i -E "FCM DIRECT MULTICAST|NOTIFICATION FILTER|FCM SUPPRESSED|FCM BROADCAST" /root/.pm2/logs/*.log | tail -n 25');
  console.log('=== FCM DISPATCH LOGS ===\n', res.stdout);

  ssh.dispose();
}

run();
