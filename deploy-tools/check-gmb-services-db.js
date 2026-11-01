const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const services = await ssh.execCommand(
    "mysql task_platform -e 'SELECT id, code, name, category, is_active FROM service_catalog;'"
  );
  console.log('=== ALL SERVICES IN CATALOG ===\n', services.stdout);

  ssh.dispose();
}

run().catch(console.error);
