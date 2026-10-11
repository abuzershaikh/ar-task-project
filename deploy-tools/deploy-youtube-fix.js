const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deployYouTubeFix() {
  try {
    console.log('🚀 Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS!\n');

    const localBase = path.resolve(__dirname, '../Task engine');
    const remoteBase = '/opt/task-engine';

    const filesToUpload = [
      'shared/services/order-activated.listener.ts',
      'apps/api/controllers/buyer/order.controller.ts',
    ];

    console.log(`📤 Uploading ${filesToUpload.length} files to VPS...`);
    for (const relPath of filesToUpload) {
      const localFilePath = path.join(localBase, relPath);
      const remoteFilePath = `${remoteBase}/${relPath}`.replace(/\\/g, '/');
      const remoteDir = path.dirname(remoteFilePath).replace(/\\/g, '/');
      await ssh.execCommand(`mkdir -p "${remoteDir}"`);
      await ssh.putFile(localFilePath, remoteFilePath);
      console.log(`   ✅ Uploaded: ${relPath}`);
    }

    console.log('🔨 Compiling backend (npx nest build) on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log(buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build output:', buildRes.stderr);
    }

    console.log('🔄 Restarting PM2 backend services (task-engine-api, task-engine-worker)...');
    await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', { cwd: remoteBase });

    await new Promise(r => setTimeout(r, 3000));
    const pm2Status = await ssh.execCommand('pm2 status task-engine-api');
    console.log(pm2Status.stdout);

    ssh.dispose();
    console.log('🎉 Task engine YouTube classification fix deployed successfully!');
  } catch (error) {
    console.error('Deployment error:', error);
    if (ssh.isConnected()) ssh.dispose();
    process.exit(1);
  }
}

deployYouTubeFix();
