const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployAdminReviewFix() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- 1. Uploading admin review & order controllers to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');
    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'admin', 'review.controller.ts'),
      '/opt/task-engine/apps/api/controllers/admin/review.controller.ts'
    );
    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'admin', 'order.controller.ts'),
      '/opt/task-engine/apps/api/controllers/admin/order.controller.ts'
    );
    console.log('✓ Uploaded controllers');

    console.log('\n--- 2. Compiling backend on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\n--- 4. Testing GET /api/v1/admin/reviews/pending ---');
    const testReviews = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/admin/reviews/pending');
    console.log('Admin reviews response:\n', testReviews.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

deployAdminReviewFix();
