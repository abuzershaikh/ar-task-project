const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand('tail -n 80 /root/.pm2/logs/task-engine-api-error.log');
  console.log('=== task-engine-api-error.log ===\n', res.stdout);

  const resWorkerErr = await ssh.execCommand('tail -n 80 /root/.pm2/logs/task-engine-worker-error.log');
  console.log('=== task-engine-worker-error.log ===\n', resWorkerErr.stdout);

  ssh.dispose();
}

run().catch(console.error);
