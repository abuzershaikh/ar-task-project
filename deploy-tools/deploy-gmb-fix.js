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
      local: path.join(localBase, 'shared/common/utils/task-identity.util.ts'),
      remote: `${remoteBase}/shared/common/utils/task-identity.util.ts`,
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

  await new Promise(r => setTimeout(r, 2500));

  console.log('Testing live endpoint with user URL https://share.google/rhI6QKATqwd8F3YY0 ...');
  const testRes = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders/google-business-info -H "Content-Type: application/json" -d '{"url":"https://share.google/rhI6QKATqwd8F3YY0"}'`);
  console.log('Live response for user link:', testRes.stdout);

  console.log('\nTesting live AI preview comments with the fetched business:');
  const aiTest = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders/ai-preview-comments -H "Content-Type: application/json" -d '{"serviceCode":"GOOGLE_BUSINESS_REVIEW","businessName":"BABA Caterers","appName":"BABA Caterers","topic":"excellent food and catering service","count":3,"language":"English","tone":"natural"}'`);
  console.log('Live AI response:', aiTest.stdout);

  ssh.dispose();
}

main().catch(console.error);
