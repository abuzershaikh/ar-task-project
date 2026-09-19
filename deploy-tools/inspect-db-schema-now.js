const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sampleTasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_type, requirements, metadata FROM tasks WHERE status=\'ACTIVE\' LIMIT 3;"');
  console.log('SAMPLE ACTIVE TASKS:\n', sampleTasks.stdout);

  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
