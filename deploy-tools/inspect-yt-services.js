const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== service_catalog sample ===');
  const sc = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT id, code, name, category, is_active FROM service_catalog LIMIT 20;'");
  console.log(sc.stdout);

  console.log('=== service_pricing sample ===');
  const sp = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT * FROM service_pricing LIMIT 20;'");
  console.log(sp.stdout);

  console.log('=== system_settings sample ===');
  const ss = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT * FROM system_settings LIMIT 20;'");
  console.log(ss.stdout);

  ssh.dispose();
}

run().catch(console.error);
