const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  console.log('--- Columns of tasks table ---');
  const cols = await ssh.execCommand('mysql task_platform -e "DESCRIBE tasks;"');
  console.log(cols.stdout);

  console.log('--- Recent 10 tasks ---');
  const recent = await ssh.execCommand('mysql task_platform -e "SELECT id, task_type, status, assigned_to, LEFT(requirements, 150) as reqs, created_at FROM tasks ORDER BY created_at DESC LIMIT 10;"');
  console.log(recent.stdout);

  console.log('--- All distinct task_type in tasks table ---');
  const types = await ssh.execCommand('mysql task_platform -e "SELECT task_type, COUNT(*) FROM tasks GROUP BY task_type;"');
  console.log(types.stdout);

  ssh.dispose();
}

run().catch(console.error);
