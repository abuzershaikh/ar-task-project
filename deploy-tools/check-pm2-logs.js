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
  const res = await ssh.execCommand('pm2 status');
  console.log(res.stdout);
  process.exit(0);
}

getLogs();
