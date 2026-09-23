const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deploy() {
  try {
    console.log('Connecting to VPS...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected to VPS.');

    // 1. Upload support-chat-engine changes
    console.log('Uploading support-chat-engine updates...');
    const localChat = path.resolve(__dirname, '../support-chat-engine');
    await ssh.putFile(`${localChat}/src/config/db.js`, '/opt/support-chat-engine/src/config/db.js');
    await ssh.putFile(`${localChat}/src/services/chat.service.js`, '/opt/support-chat-engine/src/services/chat.service.js');

    // 2. Upload Task engine updates
    console.log('Uploading Task engine updates...');
    const localTask = path.resolve(__dirname, '../Task engine');
    const remoteTask = '/opt/task-engine';
    await ssh.putFile(
      `${localTask}/shared/database/entities/user.entity.ts`,
      `${remoteTask}/shared/database/entities/user.entity.ts`
    );
    await ssh.putFile(
      `${localTask}/shared/services/user-sync.service.ts`,
      `${remoteTask}/shared/services/user-sync.service.ts`
    );
    await ssh.putFile(
      `${localTask}/apps/api/controllers/admin/worker-management.controller.ts`,
      `${remoteTask}/apps/api/controllers/admin/worker-management.controller.ts`
    );
    await ssh.putFile(
      `${localTask}/apps/api/controllers/admin/buyer-management.controller.ts`,
      `${remoteTask}/apps/api/controllers/admin/buyer-management.controller.ts`
    );
    await ssh.putFile(
      `${localTask}/shared/services/wallet.service.ts`,
      `${remoteTask}/shared/services/wallet.service.ts`
    );

    // 3. Restart support-chat-engine with PM2
    console.log('Restarting support-chat-engine on PM2...');
    const resChat = await ssh.execCommand('pm2 restart support-chat-engine || pm2 start src/server.js --name support-chat-engine', {
      cwd: '/opt/support-chat-engine',
    });
    console.log(resChat.stdout);

    // 4. Rebuild or restart Task engine on VPS
    console.log('Rebuilding Task engine on VPS...');
    const resBuild = await ssh.execCommand('npm run build', { cwd: remoteTask });
    console.log('Build output:', resBuild.stdout.slice(-500));
    if (resBuild.stderr) console.log('Build stderr:', resBuild.stderr.slice(-500));

    console.log('Restarting task engine services on PM2...');
    const resPm2 = await ssh.execCommand('pm2 restart all');
    console.log(resPm2.stdout);

    console.log('PM2 Status:');
    const pm2List = await ssh.execCommand('pm2 list');
    console.log(pm2List.stdout);

    console.log('✅ Deployment of avatar backend completed successfully!');
  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deploy();
