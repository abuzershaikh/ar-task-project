const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();
async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const srvRes = await ssh.execCommand('sed -n "1,20p" /opt/support-chat-engine/src/services/chat.service.js');
  console.log(srvRes.stdout || srvRes.stderr);
  ssh.dispose();
}
check();
