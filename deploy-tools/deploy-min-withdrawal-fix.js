const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function main() {
  console.log('Connecting to VPS...');
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });
  console.log('Connected!');

  const localBase = path.resolve(__dirname, '..', 'Task engine');
  const remoteBase = '/opt/task-engine';

  const files = [
    {
      local: path.join(localBase, 'payout-engine/services/payout-config.service.ts'),
      remote: `${remoteBase}/payout-engine/services/payout-config.service.ts`,
    },
    {
      local: path.join(localBase, 'payout-engine/payout.service.ts'),
      remote: `${remoteBase}/payout-engine/payout.service.ts`,
    },
    {
      local: path.join(localBase, 'apps/api/controllers/admin/payout-management.controller.ts'),
      remote: `${remoteBase}/apps/api/controllers/admin/payout-management.controller.ts`,
    },
    {
      local: path.join(localBase, 'apps/api/controllers/admin/system-settings.controller.ts'),
      remote: `${remoteBase}/apps/api/controllers/admin/system-settings.controller.ts`,
    },
    {
      local: path.join(localBase, 'apps/api/controllers/admin/service-catalog.controller.ts'),
      remote: `${remoteBase}/apps/api/controllers/admin/service-catalog.controller.ts`,
    },
    {
      local: path.join(localBase, 'apps/api/controllers/buyer/order.controller.ts'),
      remote: `${remoteBase}/apps/api/controllers/buyer/order.controller.ts`,
    },
    {
      local: path.join(localBase, 'apps/api/controllers/buyer/service-catalog.controller.ts'),
      remote: `${remoteBase}/apps/api/controllers/buyer/service-catalog.controller.ts`,
    },
    {
      local: path.join(localBase, 'apps/api/controllers/buyer/notification.controller.ts'),
      remote: `${remoteBase}/apps/api/controllers/buyer/notification.controller.ts`,
    },
  ];

  for (const f of files) {
    console.log(`Uploading ${f.local} -> ${f.remote}`);
    await ssh.putFile(f.local, f.remote);
  }

  console.log('Building backend on VPS...');
  const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
  console.log('Build output:', buildRes.stdout || buildRes.stderr);

  if (buildRes.code !== 0) {
    console.error('Build failed with code:', buildRes.code);
    ssh.dispose();
    return;
  }

  console.log('Reloading PM2 task-engine-api...');
  await ssh.execCommand('pm2 reload task-engine-api');

  await new Promise(r => setTimeout(r, 3000));

  console.log('\nChecking MySQL system_settings table:');
  const dbRes = await ssh.execCommand("mysql -u taskapp -ptaskapp_password task_platform -e 'SELECT * FROM system_settings WHERE `key` = \"minimum_withdrawal\";'");
  console.log(dbRes.stdout);

  console.log('\nChecking PM2 logs (last 30 lines)...');
  const logRes = await ssh.execCommand('pm2 logs task-engine-api --lines 30 --nostream');
  console.log(logRes.stdout);

  ssh.dispose();
}

main().catch(console.error);
