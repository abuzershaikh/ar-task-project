const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const where = await ssh.execCommand('find / -name "task-query.service.js" 2>/dev/null');
  console.log('Task query service on server:', where.stdout);
  ssh.dispose();
}
run();
