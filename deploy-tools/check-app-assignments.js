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
    `mysql task_platform -e "SELECT id, order_id, task_type, status, assigned_to, LEFT(requirements, 200) FROM tasks WHERE order_id='0227ab32-945e-468f-98b6-87ac46ff546d';"`
  );
  console.log(res.stdout);

  // Check if there are other orders with com.drivesafe.calls
  const res2 = await ssh.execCommand(
    `mysql task_platform -e "SELECT id, task_type, status, created_at, requirements FROM orders WHERE requirements LIKE '%com.drivesafe.calls%';"`
  );
  console.log('Orders with same app:\n', res2.stdout);

  // Check tasks with same app across all orders
  const res3 = await ssh.execCommand(
    `mysql task_platform -e "SELECT t.id, t.order_id, t.status, t.assigned_to, t.created_at FROM tasks t WHERE t.requirements LIKE '%com.drivesafe.calls%';"`
  );
  console.log('Tasks with same app:\n', res3.stdout);

  ssh.dispose();
}

run().catch(console.error);
