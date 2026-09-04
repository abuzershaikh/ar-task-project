const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

const config = {
  host: '65.20.77.112',
  username: 'root',
  password: 'G8u$RW{5m46buXgw',
  readyTimeout: 60000,
};

async function check() {
  await ssh.connect(config);
  const q = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, task_type, requirements FROM tasks ORDER BY created_at DESC LIMIT 5;"`;
  const r = await ssh.execCommand(q);
  console.log('Recent Tasks:\n', r.stdout);

  const q2 = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, buyer_id, service_code, quantity, requirements FROM orders ORDER BY created_at DESC LIMIT 3;"`;
  const r2 = await ssh.execCommand(q2);
  console.log('Recent Orders:\n', r2.stdout);

  process.exit(0);
}

check();
