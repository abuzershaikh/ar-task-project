const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function main() {
  console.log('Connecting to VPS...');
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  console.log('Connected!');

  const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
  const remoteBase = '/opt/task-engine';

  const files = [
    {
      local: path.join(localBase, 'shared/services/google-maps-metadata.service.ts'),
      remote: `${remoteBase}/shared/services/google-maps-metadata.service.ts`,
    },
    {
      local: path.join(localBase, 'shared/services/services.module.ts'),
      remote: `${remoteBase}/shared/services/services.module.ts`,
    },
    {
      local: path.join(localBase, 'apps/api/controllers/buyer/order.controller.ts'),
      remote: `${remoteBase}/apps/api/controllers/buyer/order.controller.ts`,
    },
  ];

  for (const f of files) {
    console.log(`Uploading ${f.local} -> ${f.remote}`);
    await ssh.putFile(f.local, f.remote);
  }

  console.log('Building backend on VPS...');
  const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
  console.log('Build stdout:', buildRes.stdout);
  if (buildRes.stderr) console.error('Build stderr:', buildRes.stderr);

  if (buildRes.code !== 0) {
    console.error('Build failed with code:', buildRes.code);
    ssh.dispose();
    return;
  }

  console.log('Restarting PM2 api process...');
  const pm2Res = await ssh.execCommand('pm2 reload task-engine-api || pm2 restart task-engine-api || pm2 restart all');
  console.log('PM2 restart:', pm2Res.stdout);

  // Wait 3 seconds for boot
  await new Promise(r => setTimeout(r, 3000));

  console.log('Testing google-business-info endpoint on VPS...');
  const testRes = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders/google-business-info -H "Content-Type: application/json" -d '{"url":"https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z"}'`);
  console.log('Endpoint response:', testRes.stdout);

  ssh.dispose();
}

main().catch(console.error);
