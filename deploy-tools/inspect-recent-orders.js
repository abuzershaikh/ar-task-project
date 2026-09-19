const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, service_code, task_type, status, total_tasks_required, created_at FROM orders ORDER BY created_at DESC LIMIT 15;";
  const cmd = `mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`;
  const res = await ssh.execCommand(cmd);
  console.log('STDOUT:\n', res.stdout);
  process.exit(0);
}

run().catch(console.error);
