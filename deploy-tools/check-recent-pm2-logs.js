const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const logs = await ssh.execCommand('pm2 logs task-engine --lines 100 --nostream');
  console.log('=== PM2 LOGS ===\n', logs.stdout);
  console.log('=== PM2 ERR ===\n', logs.stderr);

  ssh.dispose();
}

run().catch(console.error);
