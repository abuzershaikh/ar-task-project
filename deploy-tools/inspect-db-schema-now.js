const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const r1 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW CREATE TABLE campaign_worker_participation\\G"');
  console.log('--- campaign_worker_participation ---');
  console.log(r1.stdout);
  const r2 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW CREATE TABLE task_assignments\\G"');
  console.log('--- task_assignments ---');
  console.log(r2.stdout);
  const r3 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW CREATE TABLE tasks\\G"');
  console.log('--- tasks ---');
  console.log(r3.stdout);
  process.exit(0);
}

run().catch(console.error);
