const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deploy() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- 1. Uploading files to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');
    
    await ssh.putFile(
      path.join(localDir, 'shared', 'services', 'wallet.service.ts'),
      '/opt/task-engine/shared/services/wallet.service.ts'
    );
    console.log('✓ Uploaded wallet.service.ts');

    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'admin', 'wallet.controller.ts'),
      '/opt/task-engine/apps/api/controllers/admin/wallet.controller.ts'
    );
    console.log('✓ Uploaded wallet.controller.ts');

    console.log('\n--- 2. Building backend on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\n--- 4. Testing GET /api/v1/admin/wallet/topups ---');
    const testRes = await ssh.execCommand('curl -s -H "x-user-id: 9774f206-32c5-4e44-b2de-f4b59cfe81fb" -H "x-user-email: snapbizux@gmail.com" -H "x-user-role: SUPER_ADMIN" http://127.0.0.1:3000/api/v1/admin/wallet/topups');
    console.log('API Response:\n', testRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

deploy();
