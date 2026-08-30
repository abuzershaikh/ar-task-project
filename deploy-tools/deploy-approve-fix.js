const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployApproveFix() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- 1. Uploading state-machine and earning-posting files to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');
    await ssh.putFile(
      path.join(localDir, 'task-engine', 'task-state-machine.ts'),
      '/opt/task-engine/task-engine/task-state-machine.ts'
    );
    await ssh.putFile(
      path.join(localDir, 'earning-engine', 'services', 'earning-posting.service.ts'),
      '/opt/task-engine/earning-engine/services/earning-posting.service.ts'
    );
    console.log('✓ Uploaded files');

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

deployApproveFix();
