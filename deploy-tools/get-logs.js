const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res = await ssh.execCommand('pm2 logs task-engine-api --lines 100 --nostream');
  console.log(res.stdout || res.stderr);

  ssh.dispose();
}

main().catch(console.error);
