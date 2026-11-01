const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, title, service_code, status, requirements FROM orders WHERE id IN ('0dcda49b-c349-4e3c-a0bb-bdc407a74928', '4a57a267-decf-414e-8d5d-f9ceff51c171', '023a20b1-412a-4353-8a28-e9cd2f5b10c2');";
  const cmd = `mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`;
  const res = await ssh.execCommand(cmd);
  console.log('ORDERS:\n', res.stdout);

  const sqlTasks = "SELECT id, order_id, task_type, status, assigned_to, requirements FROM tasks WHERE order_id IN ('0dcda49b-c349-4e3c-a0bb-bdc407a74928', '4a57a267-decf-414e-8d5d-f9ceff51c171', '023a20b1-412a-4353-8a28-e9cd2f5b10c2') LIMIT 10;";
  const cmdTasks = `mysql -u taskapp -ptaskapp_password task_platform -e "${sqlTasks}"`;
  const resTasks = await ssh.execCommand(cmdTasks);
  console.log('TASKS:\n', resTasks.stdout);

  process.exit(0);
}

run().catch(console.error);
