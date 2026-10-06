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

    console.log('Connected to VPS.');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    // 1. Upload updated backend files
    const files = [
      'apps/api/controllers/buyer/service-catalog.controller.ts',
      'apps/api/controllers/buyer/order.controller.ts',
    ];

    for (const f of files) {
      console.log(`Uploading ${f}...`);
      await ssh.putFile(
        path.join(localBase, f),
        `${remoteBase}/${f}`
      );
    }

    // 2. Clean up MySQL watch_time_options & watchtime_seconds for non-combo services
    console.log('Cleaning up MySQL watch time for non-combo services...');
    await ssh.execCommand(`
      mysql -u taskapp -ptaskapp_password task_platform -e "
        -- Clear watch time on ALL non-combo services
        UPDATE service_catalog 
        SET watch_time_options = NULL, watchtime_seconds = 0
        WHERE code NOT IN ('YOUTUBE_COMBO', 'YT_COMBO')
          AND name NOT LIKE '%COMBO%';

        -- Ensure YouTube Combo has proper watch time options
        UPDATE service_catalog 
        SET watch_time_options = '{\\\"extraPricePerMinute\\\": 0.50, \\\"baseMinutes\\\": 5}' 
        WHERE code IN ('YOUTUBE_COMBO', 'YT_COMBO')
           OR (code LIKE '%COMBO%' AND (code LIKE '%YT%' OR code LIKE '%YOUTUBE%'));
      "
    `);

    // 3. Rebuild NestJS backend on VPS
    console.log('Building NestJS backend on VPS...');
    const bRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log('Build Output:\n', bRes.stdout);
    if (bRes.stderr && !bRes.stderr.includes('TS')) {
      console.error('Build Stderr:\n', bRes.stderr);
    }

    // 4. Restart PM2 processes
    console.log('Restarting PM2 task-engine-api...');
    await ssh.execCommand('pm2 restart task-engine-api');
    console.log('PM2 restarted successfully!');

    // 5. Verify the updated services
    const verifySc = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT id, code, name, category, watchtime_seconds, watch_time_options FROM service_catalog;'");
    console.log('Verification MySQL rows:\n', verifySc.stdout);

  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deploy();
