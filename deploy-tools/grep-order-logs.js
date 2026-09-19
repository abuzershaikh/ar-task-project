const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== SEARCHING LOGS FOR ORDER 08bebc9c ===');
  const res = await ssh.execCommand('grep -C 5 "08bebc9c" /root/.pm2/logs/*.log');
  console.log(res.stdout);
  if (res.stderr) console.error(res.stderr);

  console.log('=== SEARCHING LOGS FOR ORDER ACTIVATED AROUND 11:22 ===');
  const res2 = await ssh.execCommand('grep -C 5 -E "OrderActivated|FCM broadcast|auto-match|excluded|candidate" /root/.pm2/logs/task-engine-api-out-2.log');
  console.log(res2.stdout);

  ssh.dispose();
}

run();
