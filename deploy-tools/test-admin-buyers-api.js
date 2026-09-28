const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== TEST SQL QUERY WITH BUYER ROLE OR ORDERS BUYER_ID ===');
  const sql = await ssh.execCommand(`mysql -u taskapp -p'taskapp_password' task_platform -e "SELECT id, email, full_name, role FROM users WHERE role = 'BUYER' OR id IN (SELECT DISTINCT buyer_id FROM orders);"`);
  console.log(sql.stdout);

  ssh.dispose();
}

run();
