const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deploy() {
  try {
    console.log('Connecting to VPS...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 60000,
    });
    console.log('Connected.');

    const localFile = path.resolve(__dirname, '../Task engine/apps/api/controllers/worker/earning.controller.ts');
    const remoteFile = '/opt/task-engine/apps/api/controllers/worker/earning.controller.ts';

    console.log(`Uploading ${localFile} -> ${remoteFile}...`);
    await ssh.putFile(localFile, remoteFile);
    console.log('Upload completed.');

    console.log('Building Task Engine on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', {
      cwd: '/opt/task-engine',
    });
    console.log('Build output:', buildRes.stdout);
    if (buildRes.stderr) {
      console.log('Build stderr:', buildRes.stderr);
    }

    if (buildRes.code !== 0) {
      throw new Error(`Build failed with exit code ${buildRes.code}`);
    }

    console.log('Restarting PM2 processes...');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log('PM2 restart:', pm2Res.stdout);

    console.log('Waiting 3 seconds for server warm-up...');
    await new Promise(r => setTimeout(r, 3000));

    console.log('Checking PM2 status...');
    const statusRes = await ssh.execCommand('pm2 status');
    console.log(statusRes.stdout);

  } catch (err) {
    console.error('Deployment error:', err);
    process.exit(1);
  } finally {
    ssh.dispose();
  }
}

deploy();
