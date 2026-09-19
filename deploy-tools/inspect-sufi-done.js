const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const sql = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, order_id, task_type, status, assigned_to, requirements FROM tasks WHERE assigned_to = 'sufieditz@gmail.com' OR assigned_to = 'kQzd3bZD7pgA908xGE6NoGogetB3' ORDER BY updated_at DESC;"`;
  const res = await ssh.execCommand(sql);
  console.log(res.stdout);

  process.exit(0);
}

run().catch(console.error);
