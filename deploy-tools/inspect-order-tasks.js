const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, campaign_id, order_id, task_type, status, assigned_to, created_at FROM tasks WHERE order_id IN ('781a2e7d-5253-493e-a2fc-b5642c08bcf9', 'ee55f372-ec25-4028-ad2c-e46dc1775691', 'd1e2c4c3-7f0a-457e-bae8-b501e79c9940');";
  const cmd = `mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`;
  const res = await ssh.execCommand(cmd);
  console.log('STDOUT:\n', res.stdout);
  console.log('STDERR:\n', res.stderr);
  process.exit(0);
}

run().catch(console.error);
