const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('=== Checking task-engine-api PM2 logs for YouTube ===');
  const res = await ssh.execCommand('pm2 logs task-engine-api --lines 100 --nostream');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
