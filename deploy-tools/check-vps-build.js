const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkBuild() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Building TypeScript on VPS (npm run build)...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log('Build Output:', buildRes.stdout || 'Success');
    if (buildRes.stderr) console.log('Build Info:', buildRes.stderr);

    console.log('\nRestarting PM2 task-engine-api...');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\nChecking health endpoint:');
    const health = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/health');
    console.log('Health:', health.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkBuild();
