const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deploy() {
  console.log('--- 1. Connecting to VPS (65.20.77.112) ---');
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  console.log('✓ Connected to VPS');

  const basePath = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
  const filesToUpload = [
    {
      local: path.join(basePath, 'shared/services/firebase-admin.service.ts'),
      remote: '/opt/task-engine/shared/services/firebase-admin.service.ts',
    },
    {
      local: path.join(basePath, 'shared/services/order-activated.listener.ts'),
      remote: '/opt/task-engine/shared/services/order-activated.listener.ts',
    },
    {
      local: path.join(basePath, 'shared/database/repositories/notification.repository.ts'),
      remote: '/opt/task-engine/shared/database/repositories/notification.repository.ts',
    },
    {
      local: path.join(basePath, 'apps/api/controllers/buyer/service-catalog.controller.ts'),
      remote: '/opt/task-engine/apps/api/controllers/buyer/service-catalog.controller.ts',
    },
  ];

  console.log('\n--- 2. Uploading Updated Backend Files ---');
  for (const f of filesToUpload) {
    await ssh.putFile(f.local, f.remote);
    console.log(`✓ Uploaded ${path.basename(f.local)} -> ${f.remote}`);
  }

  console.log('\n--- 3. Rebuilding Task Engine on VPS ---');
  const buildRes = await ssh.execCommand('cd /opt/task-engine && npm run build');
  console.log('Build Output:', buildRes.stdout || buildRes.stderr);

  console.log('\n--- 4. Restarting PM2 task-engine ---');
  const pm2Res = await ssh.execCommand('pm2 restart task-engine --update-env');
  console.log('PM2 Output:', pm2Res.stdout);

  console.log('\n--- 5. Checking PM2 Status & Logs ---');
  const statusRes = await ssh.execCommand('pm2 status task-engine');
  console.log(statusRes.stdout);

  ssh.dispose();
  console.log('✅ VPS Backend Deployment Completed Successfully!');
}

deploy().catch((err) => {
  console.error('❌ Deployment Error:', err);
  process.exit(1);
});
