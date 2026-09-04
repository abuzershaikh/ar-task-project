const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

const config = {
  host: '65.20.77.112',
  username: 'root',
  password: 'G8u$RW{5m46buXgw',
  readyTimeout: 60000,
};

async function getLogs() {
  await ssh.connect(config);
  const res = await ssh.execCommand('pm2 logs task-engine-api --lines 100 --nostream');
  console.log(res.stdout);
  if (res.stderr) console.error(res.stderr);
  process.exit(0);
}

getLogs();
