const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployBackend() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to VPS.');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    const file = 'apps/api/controllers/buyer/order.controller.ts';
    console.log(`Uploading ${file}...`);
    await ssh.putFile(
      path.join(localBase, file),
      `${remoteBase}/${file}`
    );

    console.log('Building NestJS backend on VPS...');
    const bRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log('Build Output:\n', bRes.stdout);
    if (bRes.stderr && !bRes.stderr.includes('TS')) {
      console.error('Build Stderr:\n', bRes.stderr);
    }

    console.log('Restarting PM2 task-engine-api...');
    await ssh.execCommand('pm2 restart task-engine-api');
    console.log('PM2 restarted successfully!');

  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deployBackend();
