const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== 1. FIND USER snapbizux@gmail.com ===');
  const userRes = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, email, full_name, role, status FROM users WHERE email='snapbizux@gmail.com';"`);
  console.log(userRes.stdout);

  console.log('=== 2. LATEST ORDERS (ALL & BY snapbizux) ===');
  const orderRes = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, buyer_id, title, task_type, status, total_amount, total_budget, unit_price, total_tasks_required, created_at FROM orders ORDER BY created_at DESC LIMIT 5\\G"`);
  console.log(orderRes.stdout);

  ssh.dispose();
}

run();
