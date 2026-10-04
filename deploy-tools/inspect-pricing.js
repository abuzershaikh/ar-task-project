const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT p.service_id, sc.code, sc.name, p.buyer_unit_price, p.worker_reward, p.margin_type, p.margin_value, p.is_active FROM service_pricing p JOIN service_catalog sc ON p.service_id = sc.id;"`);
  console.log(res.stdout);
  ssh.dispose();
}

main().catch(console.error);
