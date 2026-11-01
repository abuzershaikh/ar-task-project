const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand(
    "mysql task_platform -e \"SELECT id, order_id, task_type, status, assigned_to FROM tasks WHERE order_id='023a20b1-412a-4353-8a28-e9cd2f5b10c2';\""
  );
  console.log(res.stdout);

  ssh.dispose();
}

run().catch(console.error);
