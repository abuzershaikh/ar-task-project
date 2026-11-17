const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deploy() {
  console.log('Connecting to VPS...');
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  console.log('Connected to VPS.');

  const backupDir = path.resolve(__dirname, 'vps-chat-backup');

  console.log('Uploading chat.service.js...');
  await ssh.putFile(path.join(backupDir, 'chat.service.js'), '/opt/support-chat-engine/src/services/chat.service.js');

  console.log('Uploading fcm.service.js...');
  await ssh.putFile(path.join(backupDir, 'fcm.service.js'), '/opt/support-chat-engine/src/services/fcm.service.js');

  console.log('Restarting support-chat-engine...');
  const restartRes = await ssh.execCommand('pm2 restart support-chat-engine');
  console.log(restartRes.stdout || restartRes.stderr);

  const statusRes = await ssh.execCommand('pm2 status support-chat-engine');
  console.log(statusRes.stdout);

  ssh.dispose();
  console.log('VPS Chat Engine updated and restarted successfully!');
}

deploy().catch(console.error);

