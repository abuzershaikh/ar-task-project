const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand(
    "mysql task_platform -e 'SELECT id, code, name, category, ai_generator_enabled, service_type FROM service_catalog WHERE code LIKE \"%GOOGLE%\" OR code LIKE \"%MAP%\";'"
  );
  console.log(res.stdout);

  ssh.dispose();
}

run().catch(console.error);
