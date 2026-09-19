const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, campaign_id, order_id, task_type, status, assigned_to, requirements, metadata, created_at FROM tasks WHERE task_type LIKE '%APP%' OR requirements LIKE '%play.google.com%' OR metadata LIKE '%play.google.com%' ORDER BY created_at DESC LIMIT 15;";
  const cmd = `mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`;
  const res = await ssh.execCommand(cmd);
  console.log(res.stdout);
  process.exit(0);
}

run().catch(console.error);
