const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT COUNT(*) as total_tasks FROM tasks; SELECT COUNT(*) as total_assignments FROM task_assignments; SELECT COUNT(*) as total_submissions FROM submissions;'");
  console.log('Counts:\n', res.stdout);

  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
