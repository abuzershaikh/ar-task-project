const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

(async () => {
  try {
    console.log('Connecting to VPS (65.20.77.112)...');
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    console.log('Connected to VPS!');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    const files = [
      'apps/api/controllers/buyer/review.controller.ts',
      'apps/api/controllers/admin/buyer-management.controller.ts',
      'apps/api/controllers/admin/dashboard.controller.ts',
      'apps/api/controllers/admin/worker-management.controller.ts',
      'shared/services/user-sync.service.ts'
    ];

    for (const f of files) {
      const localPath = path.join(localBase, f);
      const remotePath = `${remoteBase}/${f}`;
      console.log(`Uploading: ${f} -> ${remotePath}`);
      await ssh.putFile(localPath, remotePath);
    }
    console.log('All backend files uploaded.');

    console.log('Running npm run build on VPS...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log('Build stdout:', buildRes.stdout);
    if (buildRes.stderr) console.log('Build stderr:', buildRes.stderr);
    if (buildRes.code !== 0) {
      throw new Error(`Build failed with code ${buildRes.code}`);
    }

    console.log('Restarting PM2...');
    const restart = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', { cwd: remoteBase });
    console.log('PM2 restart:', restart.stdout);

    // Wait for restart
    await new Promise(r => setTimeout(r, 4000));

    const status = await ssh.execCommand('pm2 status');
    console.log('PM2 status:\n', status.stdout);

    // Test auto-approve-status endpoint
    const loginCmd = "curl -s -X POST http://localhost:3000/api/v1/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"snapbizux@gmail.com\",\"password\":\"80978097\"}'";
    const loginRes = await ssh.execCommand(loginCmd);
    const loginData = JSON.parse(loginRes.stdout);
    const token = loginData.data?.accessToken || loginData.data?.token || loginData.token;
    console.log('Token login test:', token ? 'SUCCESS' : 'FAILED');

    if (token) {
      console.log('\n--- Testing auto-approve-status route ---');
      const test = await ssh.execCommand(`curl -s -w "\\nHTTP: %{http_code}" -H "Authorization: Bearer ${token}" "http://localhost:3000/api/v1/buyer/reviews/auto-approve-status?orderId=732cbd88-15bb-4233-bf46-4a32ebc9df0e"`);
      console.log('Auto-approve-status response:\n', test.stdout);

      console.log('\n--- Testing pending reviews route ---');
      const test2 = await ssh.execCommand(`curl -s -w "\\nHTTP: %{http_code}" -H "Authorization: Bearer ${token}" "http://localhost:3000/api/v1/buyer/reviews/pending"`);
      console.log('Pending reviews response:\n', test2.stdout);
    }

    ssh.dispose();
  } catch (err) {
    console.error('Error during deploy:', err);
  }
})();
