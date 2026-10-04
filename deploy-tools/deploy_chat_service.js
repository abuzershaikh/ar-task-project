const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected to VPS!');

    const baseLocal = 'e:/pc2/android  project/Task  project/ar-task-project/support-chat-engine';
    const baseRemote = '/opt/support-chat-engine';

    await ssh.putFile(`${baseLocal}/src/services/chat.service.js`, `${baseRemote}/src/services/chat.service.js`);
    await ssh.putFile(`${baseLocal}/src/controllers/chat.controller.js`, `${baseRemote}/src/controllers/chat.controller.js`);
    console.log('Uploaded chat.service.js and chat.controller.js to VPS.');

    const restart = await ssh.execCommand('pm2 restart support-chat-engine');
    console.log('PM2 restart:', restart.stdout);

    await new Promise(r => setTimeout(r, 2000));

    const test = await ssh.execCommand("curl -s http://localhost:3005/api/support/conversations?limit=3");
    console.log('Chat API test:\n', test.stdout.substring(0, 300));

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();
