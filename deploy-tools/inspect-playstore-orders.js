const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const sql = `mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, service_code, status, requirements FROM orders WHERE id IN ('781a2e7d-5253-493e-a2fc-b5642c08bcf9', 'd1e2c4c3-7f0a-457e-bae8-b501e79c9940', 'ee55f372-ec25-4028-ad2c-e46dc1775691');"`;
  const res = await ssh.execCommand(sql);
  console.log(res.stdout);

  process.exit(0);
}

run().catch(console.error);
