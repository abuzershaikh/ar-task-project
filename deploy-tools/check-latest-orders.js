const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const orders = await ssh.execCommand(
    'mysql task_platform -e "SELECT id, title, task_type, status, LEFT(requirements, 200) as reqs, created_at FROM orders ORDER BY created_at DESC LIMIT 10;"'
  );
  console.log('=== LATEST 10 ORDERS ===\n', orders.stdout);

  const tasks = await ssh.execCommand(
    'mysql task_platform -e "SELECT id, order_id, task_type, status, LEFT(requirements, 200) as reqs, created_at FROM tasks ORDER BY created_at DESC LIMIT 10;"'
  );
  console.log('=== LATEST 10 TASKS ===\n', tasks.stdout);

  ssh.dispose();
}

run().catch(console.error);
