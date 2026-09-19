const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const sql = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, task_type, status, assigned_to FROM tasks WHERE order_id = 'ee55f372-ec25-4028-ad2c-e46dc1775691';"`;
  const res = await ssh.execCommand(sql);
  console.log('Tasks for ee55f372:\n', res.stdout);

  process.exit(0);
}

run().catch(console.error);
