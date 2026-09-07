const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, title, total_tasks_required, tasks_completed, reward_per_task, total_amount, status FROM orders WHERE buyer_id = 'MYDovhuR8zcbLlvazaAG8qdWLXr1'";
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('Orders for sonathe333@gmail.com:\n', res.stdout);

  ssh.dispose();
}
run();
