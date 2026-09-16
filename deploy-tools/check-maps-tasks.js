const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });
  const res = await ssh.execCommand(`mysql task_platform -e "SELECT id, task_type, status, LEFT(requirements, 120) as reqs FROM tasks WHERE task_type LIKE '%BUSINESS%' OR task_type LIKE '%MAP%';"`);
  console.log('STDOUT:', res.stdout);
  console.log('STDERR:', res.stderr);
  ssh.dispose();
}

check().catch(console.error);
