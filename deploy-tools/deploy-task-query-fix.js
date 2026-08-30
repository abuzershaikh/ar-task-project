const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployTaskQueryFix() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- 1. Uploading task-query.service.ts to VPS ---');
    const localDir = path.resolve(__dirname, '..', 'Task engine');
    await ssh.putFile(
      path.join(localDir, 'task-engine', 'queries', 'task-query.service.ts'),
      '/opt/task-engine/task-engine/queries/task-query.service.ts'
    );
    console.log('✓ Uploaded task-query.service.ts');

    console.log('\n--- 2. Compiling backend on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    console.log('\n--- 3. Restarting PM2 ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\n--- 4. Testing GET /api/v1/worker/tasks/available for Worker ---');
    const testRes = await ssh.execCommand('curl -s -H "x-user-id: MYDovhuR8zcbLlvazaAG8qdWLXr1" -H "x-user-email: testworker@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('Available tasks for worker:');
    console.log(testRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

deployTaskQueryFix();
