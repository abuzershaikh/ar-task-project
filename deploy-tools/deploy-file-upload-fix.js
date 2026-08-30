const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployFileUploadFix() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- 1. Uploading file.controller.ts to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');
    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'common', 'file.controller.ts'),
      '/opt/task-engine/apps/api/controllers/common/file.controller.ts'
    );
    console.log('✓ Uploaded file.controller.ts');

    console.log('\n--- 2. Compiling backend on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\n--- 4. Testing POST /api/v1/files/upload with curl ---');
    await ssh.execCommand('echo "test image data" > /tmp/test_proof.png');
    const uploadTest = await ssh.execCommand('curl -s -X POST -H "x-user-email: testworker@gmail.com" -H "x-user-role: WORKER" -F "file=@/tmp/test_proof.png;type=application/octet-stream" http://127.0.0.1:3000/api/v1/files/upload');
    console.log('Upload test with application/octet-stream:\n', uploadTest.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

deployFileUploadFix();
