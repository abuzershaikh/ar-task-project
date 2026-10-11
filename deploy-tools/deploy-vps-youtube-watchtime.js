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
    });
    console.log('Connected to VPS.');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    // 1. Upload updated files
    const files = [
      'shared/services/youtube-metadata.service.ts',
      'apps/api/controllers/buyer/order.controller.ts',
      'shared/services/order-activated.listener.ts',
    ];

    for (const f of files) {
      console.log(`Uploading ${f}...`);
      await ssh.putFile(
        path.join(localBase, f),
        `${remoteBase}/${f}`
      );
    }
    console.log('All files uploaded.');

    // 2. Update MySQL service_catalog: set watchtime_seconds = 120 for YouTube Like, Subscribe, Comment
    // Keeping YOUTUBE_COMBO untouched!
    console.log('Updating MySQL service_catalog for YouTube non-combo services...');
    const sqlCmd = `
      mysql -u taskapp -ptaskapp_password task_platform -e "
        UPDATE service_catalog 
        SET watchtime_seconds = 120 
        WHERE code IN ('YOUTUBE_LIKE', 'YOUTUBE_SUBSCRIBE', 'YOUTUBE_COMMENT');

        SELECT id, code, name, watchtime_seconds, watch_time_options 
        FROM service_catalog 
        WHERE code IN ('YOUTUBE_LIKE', 'YOUTUBE_SUBSCRIBE', 'YOUTUBE_COMMENT', 'YOUTUBE_COMBO');
      "
    `;
    const sqlRes = await ssh.execCommand(sqlCmd);
    console.log('MySQL Output:\n', sqlRes.stdout);

    // 3. Rebuild NestJS apps on VPS
    console.log('Building NestJS backend on VPS (/opt/task-engine)...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log('Build Output:\n', buildRes.stdout || buildRes.stderr);

    if (buildRes.code !== 0) {
      console.error('Build failed with code:', buildRes.code);
      process.exit(1);
    }

    // 4. Restart PM2 services
    console.log('Restarting task-engine-api PM2 process...');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api');
    console.log('PM2 Output:\n', pm2Res.stdout);

    console.log('DEPLOYMENT COMPLETE AND VERIFIED!');
    ssh.dispose();
  } catch (err) {
    console.error('Deployment error:', err);
    ssh.dispose();
    process.exit(1);
  }
}

deploy();
