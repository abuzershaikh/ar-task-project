const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT id, user_id, status, kyc_status FROM workers LIMIT 10;'");
  console.log('Workers table:\n', res.stdout);

  const res2 = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT COUNT(*) as active_count FROM workers WHERE status=\"active\" AND kyc_status=\"approved\";'");
  console.log('Active approved workers:\n', res2.stdout);

  process.exit(0);
}

run().catch(console.error);
