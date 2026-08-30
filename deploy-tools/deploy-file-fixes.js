const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function deployFileFixes() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- 1. Uploading updated file handling files to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');

    // file.controller.ts
    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'common', 'file.controller.ts'),
      '/opt/task-engine/apps/api/controllers/common/file.controller.ts'
    );
    console.log('✓ Uploaded file.controller.ts');

    // file-storage.service.ts
    await ssh.putFile(
      path.join(localDir, 'shared', 'services', 'file-storage.service.ts'),
      '/opt/task-engine/shared/services/file-storage.service.ts'
    );
    console.log('✓ Uploaded file-storage.service.ts');

    // file.repository.ts
    await ssh.putFile(
      path.join(localDir, 'shared', 'database', 'repositories', 'file.repository.ts'),
      '/opt/task-engine/shared/database/repositories/file.repository.ts'
    );
    console.log('✓ Uploaded file.repository.ts');

    // review.controller.ts
    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'buyer', 'review.controller.ts'),
      '/opt/task-engine/apps/api/controllers/buyer/review.controller.ts'
    );
    console.log('✓ Uploaded review.controller.ts');

    console.log('\n--- 2. Compiling backend on VPS (npm run build) ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 task-engine-api ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\n--- 4. Testing File Upload & Public Image Streaming ---');
    // Create a dummy test image on VPS and upload it via API
    await ssh.execCommand('echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > /tmp/test_proof.png');
    const uploadRes = await ssh.execCommand('curl -s -X POST -H "x-user-email: worker@test.com" -H "x-user-id: w_100" -H "x-user-role: WORKER" -F "file=@/tmp/test_proof.png" http://127.0.0.1:3000/api/v1/files/upload');
    console.log('Upload response:', uploadRes.stdout);

    const uploadJson = JSON.parse(uploadRes.stdout);
    if (uploadJson.url) {
      console.log('\nTesting Public Streaming URL without Auth (Public Access Check):', uploadJson.url);
      const streamRes = await ssh.execCommand(`curl -s -I ${uploadJson.url.replace('http://65.20.77.112:3000', 'http://127.0.0.1:3000')}`);
      console.log('Stream Headers:');
      console.log(streamRes.stdout);
    }

  } catch (err) {
    console.error('Error during deployment & verification:', err);
  } finally {
    ssh.dispose();
  }
}

deployFileFixes();
