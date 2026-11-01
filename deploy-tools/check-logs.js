const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  console.log('--- Checking error logs in task-engine-api and task-engine-worker ---');
  const apiLogs = await ssh.execCommand('pm2 logs task-engine-api --lines 200 --nostream | grep -iE "order|error|warn|failed|google|maps" | tail -n 50');
  console.log('API LOGS:\n', apiLogs.stdout);

  const workerLogs = await ssh.execCommand('pm2 logs task-engine-worker --lines 200 --nostream | grep -iE "order|error|warn|failed|google|maps" | tail -n 50');
  console.log('\nWORKER LOGS:\n', workerLogs.stdout);

  ssh.dispose();
}

run().catch(console.error);
