const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const files = await ssh.execCommand('ls -lt /root/.pm2/logs/ | head -n 15');
  console.log('=== PM2 LOG FILES ===\n', files.stdout);

  const curLog = await ssh.execCommand('grep -i -E "FCM|OrderActivated|NOTIFICATION FILTER" /root/.pm2/logs/task-engine-api-out-2.log | tail -n 20');
  console.log('=== CURRENT ACTIVE API LOGS ===\n', curLog.stdout);

  ssh.dispose();
}

run();
