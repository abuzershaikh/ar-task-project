const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const sql = "SELECT id, email, role, full_name, last_login FROM users ORDER BY last_login DESC LIMIT 10";
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql}"`);
  console.log('Users ordered by last_login:\n', res.stdout);

  ssh.dispose();
}
run();
