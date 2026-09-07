const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deployUserSyncFix() {
  try {
    console.log('🚀 Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS!\n');

    const localFile = path.resolve(__dirname, '../Task engine/shared/services/user-sync.service.ts');
    const remoteFile = '/opt/task-engine/shared/services/user-sync.service.ts';

    console.log(`📤 Uploading ${localFile} -> ${remoteFile}...`);
    await ssh.putFile(localFile, remoteFile);
    console.log('✅ Uploaded user-sync.service.ts!\n');

    const remoteBase = '/opt/task-engine';

    // Build
    console.log('🔨 Building backend (npx nest build)...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    if (buildRes.stdout) console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build output:', buildRes.stderr);
    }
    if (buildRes.code !== 0) {
      console.error('❌ Build failed!');
      ssh.dispose();
      return;
    }
    console.log('✅ Build successful!\n');

    // Restart PM2
    console.log('🔄 Restarting task-engine-api...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout || 'Restarted');

    console.log('⏳ Waiting 4s for API initialization...');
    await new Promise(r => setTimeout(r, 4000));

    // Health check
    console.log('🏓 Health check:');
    const healthCheck = await ssh.execCommand('curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health');
    console.log(`HTTP Status: ${healthCheck.stdout}`);

    // Recent logs
    console.log('\n📋 Recent PM2 logs:');
    const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 20 --nostream');
    console.log(logs.stdout || logs.stderr);

    ssh.dispose();
    console.log('\n🎉 ✅ UserSyncService fix deployed successfully!');
  } catch (error) {
    console.error('❌ Deployment error:', error);
    try { ssh.dispose(); } catch (e) {}
  }
}

deployUserSyncFix();
