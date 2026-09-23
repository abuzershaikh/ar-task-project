const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand(
    "mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT COUNT(*) as total, COUNT(avatar_url) as with_avatar FROM users; SELECT fullName, email, avatar_url FROM users WHERE avatar_url IS NOT NULL LIMIT 5;'"
  );
  console.log(res.stdout);
}

check().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
