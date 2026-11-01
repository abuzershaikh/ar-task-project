const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });

  const res = await ssh.execCommand('mysql task_platform -e "SELECT DISTINCT entity_key FROM worker_completed_identities WHERE entity_key LIKE \'pkg:%\' OR entity_key LIKE \'%maps%\' OR entity_key LIKE \'%google%\' LIMIT 25;"');
  console.log('Sample entity_keys in DB:\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
