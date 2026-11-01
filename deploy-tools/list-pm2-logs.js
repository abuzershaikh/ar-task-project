const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand('ls -lt /root/.pm2/logs/');
  console.log('=== /root/.pm2/logs ===\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
