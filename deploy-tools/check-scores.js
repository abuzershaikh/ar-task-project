const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  const q = `SHOW TABLES LIKE '%score%';`;
  const r = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q}"`);
  console.log('Score tables:', r.stdout);

  const q2 = `DESCRIBE workers;`;
  const r2 = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q2}"`);
  console.log('Workers table columns:', r2.stdout);

  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
