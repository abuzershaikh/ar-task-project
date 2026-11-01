const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res = await ssh.execCommand(
    `mysql -u taskapp -ptaskapp_password task_platform -e "
      SELECT id, email, role, created_at FROM users WHERE email IN ('alyamikhailovnakujou555@gmail.com', 'wibaramk@gmail.com');
      SELECT task_id, worker_id, status, assigned_at, expires_at FROM task_assignments WHERE worker_id IN ('alyamikhailovnakujou555@gmail.com', 'wibaramk@gmail.com') ORDER BY assigned_at DESC LIMIT 6;
    "`
  );
  console.log(res.stdout);
  ssh.dispose();
}

run().catch(console.error);
