const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });

  const res = await ssh.execCommand('mysql task_platform -e "SHOW INDEX FROM worker_completed_identities;"');
  console.log('Indexes:\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
