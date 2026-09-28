const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deploy() {
  try {
    console.log('Connecting to VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected!');

    const baseLocal = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const baseRemote = '/opt/task-engine';

    const filesToUpload = [
      {
        local: path.join(baseLocal, 'shared/services/redis-cache.service.ts'),
        remote: `${baseRemote}/shared/services/redis-cache.service.ts`,
      },
      {
        local: path.join(baseLocal, 'shared/services/services.module.ts'),
        remote: `${baseRemote}/shared/services/services.module.ts`,
      },
      {
        local: path.join(baseLocal, 'apps/api/controllers/worker/task.controller.ts'),
        remote: `${baseRemote}/apps/api/controllers/worker/task.controller.ts`,
      },
      {
        local: path.join(baseLocal, 'apps/api/controllers/worker/earning.controller.ts'),
        remote: `${baseRemote}/apps/api/controllers/worker/earning.controller.ts`,
      },
      {
        local: path.join(baseLocal, 'earning-engine/services/earning-posting.service.ts'),
        remote: `${baseRemote}/earning-engine/services/earning-posting.service.ts`,
      },
    ];

    for (const f of filesToUpload) {
      console.log(`Uploading ${f.remote}...`);
      await ssh.putFile(f.local, f.remote);
    }
    console.log('All files uploaded successfully.');

    console.log('\nRunning npm run build on VPS...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: baseRemote });
    console.log(buildRes.stdout || buildRes.stderr);

    if (buildRes.code !== 0) {
      console.error('❌ Build failed with exit code:', buildRes.code);
      return;
    }

    console.log('\nRestarting PM2 task-engine-api and task-engine-worker...');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log(pm2Res.stdout);

    console.log('Deployment complete!');
  } catch (err) {
    console.error('Deployment error:', err.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

deploy();
