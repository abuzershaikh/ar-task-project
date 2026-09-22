const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');
const ssh = new NodeSSH();

async function deploySupportChat() {
  try {
    console.log('Connecting to VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected to VPS.');

    const localBase = path.resolve(__dirname, '../support-chat-engine');
    const remoteBase = '/opt/support-chat-engine';

    // 1. Create remote directories
    console.log('Creating remote directories...');
    await ssh.execCommand(`mkdir -p ${remoteBase}/src/config ${remoteBase}/src/controllers ${remoteBase}/src/services ${remoteBase}/src/sockets ${remoteBase}/uploads`);

    // 2. Upload files
    const filesToUpload = [
      'package.json',
      '.env.example',
      'src/server.js',
      'src/config/db.js',
      'src/config/firebase.js',
      'src/services/fcm.service.js',
      'src/services/chat.service.js',
      'src/controllers/chat.controller.js',
      'src/sockets/chat.socket.js',
    ];

    for (const rel of filesToUpload) {
      const localFile = path.join(localBase, rel);
      if (!fs.existsSync(localFile)) {
        console.warn(`File not found locally: ${localFile}`);
        continue;
      }
      const content = fs.readFileSync(localFile, 'utf8');
      const base64 = Buffer.from(content).toString('base64');
      const remoteFile = `${remoteBase}/${rel}`;
      await ssh.execCommand(`echo "${base64}" | base64 -d > "${remoteFile}"`);
      console.log(`Uploaded ${rel}`);
    }

    // Copy .env if not exists
    await ssh.execCommand(`if [ ! -f ${remoteBase}/.env ]; then cp ${remoteBase}/.env.example ${remoteBase}/.env; fi`);

    // 3. Install NPM dependencies
    console.log('Installing dependencies on VPS (npm install)...');
    const installRes = await ssh.execCommand(`cd ${remoteBase} && npm install --production`);
    console.log('NPM output:', installRes.stdout || installRes.stderr || 'Success');

    // 4. Start or restart PM2 service
    console.log('Configuring PM2 process for support-chat-engine...');
    const pm2Check = await ssh.execCommand('pm2 describe support-chat-engine');
    if (pm2Check.stdout.includes('online') || pm2Check.stdout.includes('stopped')) {
      await ssh.execCommand(`cd ${remoteBase} && pm2 restart support-chat-engine`);
      console.log('Restarted support-chat-engine in PM2.');
    } else {
      await ssh.execCommand(`cd ${remoteBase} && pm2 start src/server.js --name support-chat-engine`);
      console.log('Started support-chat-engine in PM2.');
    }
    await ssh.execCommand('pm2 save');

    // 5. Test health
    console.log('\n--- Verifying service health ---');
    await new Promise((r) => setTimeout(r, 2000));
    const health = await ssh.execCommand('curl -s http://127.0.0.1:3005/health');
    console.log('Health response:', health.stdout);

    // 6. Check tables in DB
    const dbCheck = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SHOW TABLES LIKE \'support_%\';"');
    console.log('DB Tables:\n', dbCheck.stdout);

    ssh.dispose();
    console.log('\n✅ Support Chat Engine deployed successfully to VPS!');
  } catch (err) {
    console.error('Deployment error:', err.message);
    ssh.dispose();
  }
}

deploySupportChat();
