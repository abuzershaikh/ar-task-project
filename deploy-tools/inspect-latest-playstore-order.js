const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== TASK QUERY SERVICE lines 130-200 ===');
  const code = await ssh.execCommand('sed -n "130,200p" /opt/task-engine/dist/task-engine/queries/task-query.service.js');
  console.log(code.stdout);

  ssh.dispose();
}

run().catch(console.error);
