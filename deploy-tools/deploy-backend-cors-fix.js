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

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    console.log('Uploading updated main.ts...');
    await ssh.putFile(
      path.join(localBase, 'apps/api/main.ts'),
      `${remoteBase}/apps/api/main.ts`
    );

    console.log('Updating .env on VPS to include CORS_ORIGINS=* ...');
    await ssh.execCommand(`
      if ! grep -q "CORS_ORIGINS" /opt/task-engine/.env; then
        echo "CORS_ORIGINS=*" >> /opt/task-engine/.env
      else
        sed -i 's/^CORS_ORIGINS=.*/CORS_ORIGINS=*/g' /opt/task-engine/.env
      fi
    `);

    console.log('Building NestJS backend on VPS...');
    const bRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log(bRes.stdout);
    if (bRes.stderr) console.error('Build Stderr:', bRes.stderr);

    console.log('Restarting PM2 process task-engine-api...');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api');
    console.log(pm2Res.stdout);

    console.log('Backend deployed and restarted successfully!');
  } catch (err) {
    console.error('Error deploying backend:', err);
  } finally {
    ssh.dispose();
  }
}

deploy();
