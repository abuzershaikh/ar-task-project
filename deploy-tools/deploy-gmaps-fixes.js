const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deployGmapsFixes() {
  try {
    console.log('🚀 Connecting to VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS!\n');

    const localBase = path.resolve(__dirname, '../Task engine');
    const remoteBase = '/opt/task-engine';

    const filesToUpload = [
      'shared/database/entities/order-unit.entity.ts',
      'shared/common/utils/task-identity.util.ts',
      'shared/services/order-activated.listener.ts',
      'shared/services/google-maps-metadata.service.ts',
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
    console.log('\nAll files uploaded successfully!\n');

    console.log('🔨 Compiling backend (npm run build) on VPS...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log('Build output:\n', buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated') && !buildRes.stderr.includes('ts-node')) {
      console.warn('Build stderr:\n', buildRes.stderr);
    }

    console.log('\n🔄 Restarting PM2 backend services (task-engine-api, task-engine-worker)...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', { cwd: remoteBase });
    console.log(restartRes.stdout);

    console.log('⏳ Waiting 4s for services to stabilize...');
    await new Promise(r => setTimeout(r, 4000));

    console.log('🔍 Checking PM2 status...');
    const pm2Status = await ssh.execCommand('pm2 status');
    console.log(pm2Status.stdout);

    ssh.dispose();
    console.log('🎉 Deployment complete!');
  } catch (error) {
    console.error('Deployment error:', error);
    if (ssh.isConnected()) ssh.dispose();
    process.exit(1);
  }
}

deployGmapsFixes();
