const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const logs = await ssh.execCommand('grep -i "GOOGLE" /root/.pm2/logs/task-engine-api-out* | tail -n 40');
  console.log('=== GREP GOOGLE IN LOGS ===\n', logs.stdout);

  ssh.dispose();
}

run().catch(console.error);
