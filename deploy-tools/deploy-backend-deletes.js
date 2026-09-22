const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deploy() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    console.log('Connected to VPS.');

    const basePath = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    const filesToUpload = [
      {
        local: path.join(basePath, 'shared/database/repositories/user.repository.ts'),
        remote: path.join(remoteBase, 'shared/database/repositories/user.repository.ts').replace(/\\/g, '/')
      },
      {
        local: path.join(basePath, 'shared/database/repositories/worker.repository.ts'),
        remote: path.join(remoteBase, 'shared/database/repositories/worker.repository.ts').replace(/\\/g, '/')
      },
      {
        local: path.join(basePath, 'apps/api/controllers/admin/worker-management.controller.ts'),
        remote: path.join(remoteBase, 'apps/api/controllers/admin/worker-management.controller.ts').replace(/\\/g, '/')
      },
      {
        local: path.join(basePath, 'apps/api/controllers/admin/buyer-management.controller.ts'),
        remote: path.join(remoteBase, 'apps/api/controllers/admin/buyer-management.controller.ts').replace(/\\/g, '/')
      },
    ];

    for (const f of filesToUpload) {
      console.log(`Uploading ${f.local} -> ${f.remote}`);
      await ssh.putFile(f.local, f.remote);
    }

    console.log('Running npm run build on VPS...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log(buildRes.stdout);
    if (buildRes.code !== 0) {
      console.error('Build Error:', buildRes.stderr);
      return;
    }

    console.log('Restarting PM2...');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(pm2Res.stdout);

    console.log('Deployed successfully!');
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

deploy();
