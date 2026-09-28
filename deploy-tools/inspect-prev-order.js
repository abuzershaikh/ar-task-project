const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== 1. PREVIOUS YOUTUBE ORDERS BY OTHER BUYERS ===');
  const prevOrders = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT o.id, o.buyer_id, u.email as buyer_email, u.full_name as buyer_name, o.title, o.task_type, o.status, o.total_amount, o.total_tasks_required, o.created_at FROM orders o JOIN users u ON o.buyer_id = u.id WHERE o.task_type LIKE '%YOUTUBE%' AND o.id != '732cbd88-15bb-4233-bf46-4a32ebc9df0e' ORDER BY o.created_at DESC LIMIT 10\\G"`);
  console.log(prevOrders.stdout);

  const orderId = '9393971f-6224-477f-8a47-625bf34383c9';

  console.log('=== ORDERS SCHEMA ===');
  const oCols = await ssh.execCommand("mysql -u taskapp -p'taskapp_password' task_platform -e 'DESCRIBE orders;'");
  console.log(oCols.stdout);

  console.log('=== ORDER 9393971f REQUIREMENTS ===');
  const oRow = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, title, requirements FROM orders WHERE id='9393971f-6224-477f-8a47-625bf34383c9'\\G"`);
  console.log(oRow.stdout);

  ssh.dispose();
}

run();
