const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deployWorkerWipeFix() {
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
      'apps/api/controllers/admin/worker-management.controller.ts',
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
    if (buildRes.code !== 0) {
      console.error('❌ Build failed on VPS:', buildRes.stderr);
      return;
    }

    console.log('🔄 Restarting PM2 processes (task-engine-api, task-engine-worker)...');
    const restartApi = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartApi.stdout);
    const restartWorker = await ssh.execCommand('pm2 restart task-engine-worker', { cwd: remoteBase });
    console.log(restartWorker.stdout);

    console.log('🎉 VPS Backend successfully updated and restarted!');
  } catch (err) {
    console.error('Deploy error:', err);
  } finally {
    ssh.dispose();
  }
}

deployWorkerWipeFix();

