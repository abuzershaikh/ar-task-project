const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const descSc = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "DESCRIBE service_catalog;"');
  console.log('DESCRIBE service_catalog:\n', descSc.stdout);
  const ytRows = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, watch_time_options, elements FROM service_catalog WHERE code LIKE \'%YT%\' OR code LIKE \'%YOUTUBE%\';"');
  console.log('YT service_catalog:\n', ytRows.stdout);
  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
