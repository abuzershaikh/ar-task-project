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
    "mysql task_platform -e 'SELECT id, title, task_type, status, created_at, SUBSTRING(requirements, 1, 100) FROM orders ORDER BY created_at DESC LIMIT 30;'"
  );
  console.log('=== LATEST 30 ORDERS ===\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
