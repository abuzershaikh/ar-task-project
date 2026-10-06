const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== Tables in task_platform ===');
  const t = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SHOW TABLES;'");
  console.log(t.stdout);

  const count = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT count(*) FROM service_catalog; DESCRIBE service_catalog;'");
  console.log(count.stdout);
  if (count.stderr) console.error('STDERR:', count.stderr);

  const spDesc = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'DESCRIBE service_pricing; SELECT * FROM service_pricing;'");
  console.log('=== service_pricing ===\n', spDesc.stdout);

  const tasks = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e \'SELECT id, order_id, title, reward_amount, status, metadata FROM tasks WHERE order_id = "d1c70e26-5471-48cc-83f6-d9eeae0d2491";\'');
  console.log('=== Tasks for d1c70e26-5471-48cc-83f6-d9eeae0d2491 ===\n', tasks.stdout);

  ssh.dispose();
}

run().catch(console.error);
