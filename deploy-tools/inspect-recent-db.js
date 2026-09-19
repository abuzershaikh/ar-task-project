const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('--- Playstore Orders ---');
  const sqlOrders = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, buyer_id, service_code, status, total_quantity, created_at FROM buyer_orders WHERE service_code LIKE '%PLAY%' OR service_code LIKE '%INSTALL%' OR service_code LIKE '%APP%' ORDER BY created_at DESC LIMIT 10;"`;
  const res1 = await ssh.execCommand(sqlOrders);
  console.log(res1.stdout);

  console.log('--- Playstore Tasks ---');
  const sqlTasks = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, task_type, status, assigned_to, created_at FROM tasks WHERE task_type LIKE '%PLAY%' OR task_type LIKE '%INSTALL%' OR task_type LIKE '%APP%' ORDER BY created_at DESC LIMIT 10;"`;
  const res2 = await ssh.execCommand(sqlTasks);
  console.log(res2.stdout);

  process.exit(0);
}

run().catch(console.error);
