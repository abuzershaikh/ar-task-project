const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const cmd = process.argv[2] || 'grep -n "excludedPackageIds" /opt/task-engine/task-engine/queries/task-query.service.ts';
  const res = await ssh.execCommand(cmd);
  console.log('STDOUT:\n', res.stdout);
  console.log('STDERR:\n', res.stderr);
  process.exit(0);
}

run().catch(console.error);
