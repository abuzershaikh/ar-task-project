const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    console.log('Connecting to VPS...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected! Killing any hanging npm install...');
    await ssh.execCommand('pkill -f "npm install" || true');
    console.log('Running npm run build...');
    const buildRes = await ssh.execCommand('cd /opt/task-engine && npm run build');
    console.log('Build stdout:\n', buildRes.stdout);
    if (buildRes.stderr) console.error('Build stderr:\n', buildRes.stderr);
    
    console.log('Restarting PM2 api...');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api');
    console.log('PM2 restart:\n', pm2Res.stdout);

    const pm2Status = await ssh.execCommand('pm2 status');
    console.log('PM2 status:\n', pm2Status.stdout);
  } catch (err) {
    console.error('Error:', err);
  } finally {
    process.exit(0);
  }
}

run();
