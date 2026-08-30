const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployScoreFix() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- 1. Uploading updated score & profile controllers to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');
    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'worker', 'profile.controller.ts'),
      '/opt/task-engine/apps/api/controllers/worker/profile.controller.ts'
    );
    console.log('✓ Uploaded profile.controller.ts');

    await ssh.putFile(
      path.join(localDir, 'apps', 'api', 'controllers', 'worker', 'score.controller.ts'),
      '/opt/task-engine/apps/api/controllers/worker/score.controller.ts'
    );
    console.log('✓ Uploaded score.controller.ts');

    console.log('\n--- 2. Compiling backend on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

deployScoreFix();
