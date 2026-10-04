const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const res = await ssh.execCommand('ls -la /opt/task-engine/shared/services/google-maps-metadata.service.ts');
  console.log('File check:', res.stdout || res.stderr);
  
  const grepCheck = await ssh.execCommand('grep -i "google-business-info" /opt/task-engine/apps/api/controllers/buyer/order.controller.ts');
  console.log('Order controller check:', grepCheck.stdout || grepCheck.stderr);

  ssh.dispose();
}

main().catch(console.error);
