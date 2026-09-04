const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

const config = {
  host: '65.20.77.112',
  username: 'root',
  password: 'G8u$RW{5m46buXgw',
  readyTimeout: 60000,
};

async function check() {
  await ssh.connect(config);
  const r = await ssh.execCommand('cat /opt/task-engine/.env | grep -i DEEPSEEK');
  console.log('DEEPSEEK line:', r.stdout);
  const r2 = await ssh.execCommand('head -n 20 /opt/task-engine/.env');
  console.log('Env head:\n', r2.stdout);
  process.exit(0);
}

check();
