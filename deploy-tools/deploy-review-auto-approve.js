const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deployReviewAutoApprove() {
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
      'review-engine/services/review-auto-approve-monitor.service.ts',
      'review-engine/review-engine.module.ts',
      'apps/api/controllers/admin/system-settings.controller.ts',
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

    console.log('🔨 Compiling backend (npx nest build) on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log(buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build output:', buildRes.stderr);
    }
    console.log('');

    console.log('🔄 Restarting PM2 backend service (task-engine-api)...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout);
    console.log('');

    console.log('⏳ Waiting 4s for PM2 service to initialize...');
    await new Promise(r => setTimeout(r, 4000));

    console.log('🔍 Checking PM2 status...');
    const pm2Status = await ssh.execCommand('pm2 status task-engine-api');
    console.log(pm2Status.stdout);

    // Verify endpoint
    console.log('\n🧪 Testing endpoint on VPS...');
    const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`;
    const loginRes = await ssh.execCommand(loginCmd);
    const data = JSON.parse(loginRes.stdout);
    const token = data.data?.accessToken || data.data?.token || data.token;
    if (token) {
      const testRes = await ssh.execCommand(`curl -s -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/settings/review-auto-approve`);
      console.log('GET /admin/settings/review-auto-approve response:');
      console.log(testRes.stdout);
    }

    ssh.dispose();
    console.log('\n🎉 Backend deployment complete!');
  } catch (error) {
    console.error('Deployment error:', error);
    if (ssh.isConnected()) ssh.dispose();
    process.exit(1);
  }
}

deployReviewAutoApprove();
