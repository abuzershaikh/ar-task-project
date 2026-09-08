const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 10000,
  });

  const res1 = await ssh.execCommand('pm2 restart task-engine-worker');
  console.log('Restart:', res1.stdout, res1.stderr);

  const res2 = await ssh.execCommand('pm2 logs task-engine-worker --lines 30 --nostream');
  console.log('Worker logs:\n', res2.stdout, res2.stderr);

  const res3 = await ssh.execCommand('pm2 status');
  console.log('PM2 status:\n', res3.stdout);

  ssh.dispose();
}

run();
