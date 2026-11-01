const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const cols = await ssh.execCommand('mysql task_platform -e "DESCRIBE orders;"');
  console.log('Orders cols:\n', cols.stdout);

  const sample = await ssh.execCommand('mysql task_platform -e "SELECT * FROM orders WHERE task_type IN (\'PLAYSTORE_REVIEW\', \'GOOGLE_BUSINESS_REVIEW\') LIMIT 2\\G"');
  console.log('Orders sample:\n', sample.stdout);

  ssh.dispose();
}

run().catch(console.error);
