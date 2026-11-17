const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');

const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const backupDir = path.resolve(__dirname, 'vps-chat-backup');
  if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });

  await ssh.getFile(path.join(backupDir, 'chat.service.js'), '/opt/support-chat-engine/src/services/chat.service.js');
  await ssh.getFile(path.join(backupDir, 'fcm.service.js'), '/opt/support-chat-engine/src/services/fcm.service.js');
  await ssh.getFile(path.join(backupDir, 'chat.controller.js'), '/opt/support-chat-engine/src/controllers/chat.controller.js');

  console.log('Downloaded chat engine files for inspection.');
  ssh.dispose();
}

run().catch(console.error);

