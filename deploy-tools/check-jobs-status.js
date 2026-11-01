const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = `SELECT id, order_id, status, error_message, generated_tasks_count, total_tasks_required, created_at FROM task_generation_jobs ORDER BY created_at DESC LIMIT 15;`;
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('JOBS:\n', res.stdout);
  ssh.dispose();
}

run().catch(console.error);
