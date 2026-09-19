const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, email, role, status FROM users WHERE email='sufieditz@gmail.com' OR email='sonathe333@gmail.com';";
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('MySQL Users:\n', res.stdout);

  const sql2 = "SELECT id, user_id, email, phone FROM workers WHERE email='sufieditz@gmail.com' OR email='sonathe333@gmail.com';";
  const res2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql2}"`);
  console.log('MySQL Workers:\n', res2.stdout);

  process.exit(0);
}

run().catch(console.error);
