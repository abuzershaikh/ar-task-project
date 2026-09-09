const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e \"SELECT id, order_id, task_type, requirements, metadata FROM tasks ORDER BY created_at DESC LIMIT 3\\G\"");
  console.log('STDOUT:', res.stdout);
  console.log('STDERR:', res.stderr);
  ssh.dispose();
}
main().catch(console.error);
