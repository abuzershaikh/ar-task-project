const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) FROM service_catalog; SELECT id, service_code, status, requirements FROM orders ORDER BY created_at DESC LIMIT 5;"`);
  console.log(res.stdout);
  ssh.dispose();
}
main().catch(console.error);
