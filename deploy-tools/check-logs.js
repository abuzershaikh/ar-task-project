const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 50 --nostream');
  console.log('=== task-engine-api logs ===');
  console.log(logs.stdout);
  console.log(logs.stderr);

  const workerLogs = await ssh.execCommand('pm2 logs task-engine-worker --lines 30 --nostream');
  console.log('=== task-engine-worker logs ===');
  console.log(workerLogs.stdout);
  console.log(workerLogs.stderr);

  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
