const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectAllOrders() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== All Orders in DB ===');
    const orders = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT o.id, o.buyer_id, u.email as buyer_email, o.service_code, o.status, o.total_amount, o.created_at FROM orders o LEFT JOIN users u ON o.buyer_id = u.id;"');
    console.log(orders.stdout);

    console.log('\n=== All Tasks in DB ===');
    const tasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT t.id, t.order_id, t.task_type, t.reward_amount, t.status, t.assigned_to, t.created_at FROM tasks t;"');
    console.log(tasks.stdout);

    console.log('\n=== Registered Buyers in Users table ===');
    const users = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, role, full_name, created_at FROM users;"');
    console.log(users.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspectAllOrders();
