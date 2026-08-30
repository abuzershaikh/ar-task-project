const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function buildAndCheck() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Building NestJS on VPS...');
    const bRes = await ssh.execCommand('npx nest build', { cwd: '/opt/task-engine' });
    console.log('Build Stdout:', bRes.stdout);
    console.log('Build Stderr:', bRes.stderr);

    const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log(restartRes.stdout);

    await new Promise(r => setTimeout(r, 2000));
    const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 25 --nostream');
    console.log('PM2 Logs:\n', logs.stdout);

    const health = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/health');
    console.log('Health Endpoint:', health.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

buildAndCheck();
