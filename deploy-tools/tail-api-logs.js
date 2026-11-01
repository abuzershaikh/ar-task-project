const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const out = await ssh.execCommand('tail -n 60 /root/.pm2/logs/task-engine-api-out-0.log');
  console.log('=== task-engine-api-out-0.log ===\n', out.stdout);

  const err = await ssh.execCommand('tail -n 60 /root/.pm2/logs/task-engine-api-error-0.log');
  console.log('=== task-engine-api-error-0.log ===\n', err.stdout);

  ssh.dispose();
}

run().catch(console.error);
