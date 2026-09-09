const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, ai_generator_enabled FROM service_catalog;"`);
  console.log(res.stdout);
  ssh.dispose();
}
main().catch(console.error);
