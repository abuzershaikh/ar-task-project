const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res1 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES LIKE \'%order%\';"');
  console.log('Tables:', res1.stdout);

  const res2 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, service_code, status, created_at FROM orders ORDER BY created_at DESC LIMIT 15;"');
  console.log('Orders table:', res2.stdout);

  const res3 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, service_code, status, created_at FROM buyer_orders ORDER BY created_at DESC LIMIT 15;"');
  console.log('Buyer orders table:', res3.stdout);

  process.exit(0);
}

run().catch(console.error);
