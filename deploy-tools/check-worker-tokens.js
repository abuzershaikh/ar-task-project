const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT id, email, metadata FROM users WHERE role=\"WORKER\" LIMIT 10;'");
  console.log('Users sample metadata:\n', res.stdout);

  const tokenCount = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT COUNT(*) FROM users WHERE role=\"WORKER\" AND metadata LIKE \"%fcmToken%\";'");
  console.log('Users with FCM token in metadata:\n', tokenCount.stdout);

  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
