const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand(
    "mysql task_platform -e 'SELECT id, order_id, status, error_message, created_at FROM task_generation_jobs WHERE status != \"COMPLETED\" ORDER BY created_at DESC LIMIT 10;'"
  );
  console.log('=== FAILED / PENDING TASK GENERATION JOBS ===\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
