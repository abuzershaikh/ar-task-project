const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');
const ssh = new NodeSSH();

async function deploy() {
  try {
    console.log('Connecting to VPS...');
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    console.log('Connected.');

    const basePath = path.resolve(__dirname, '../Task engine');
    const files = [
      'apps/api/controllers/admin/worker-management.controller.ts',
      'apps/api/controllers/admin/buyer-management.controller.ts',
    ];

    for (const rel of files) {
      const localFile = path.join(basePath, rel);
      const content = fs.readFileSync(localFile, 'utf8');
      const base64Content = Buffer.from(content).toString('base64');
      const remoteFile = `/opt/task-engine/${rel}`;
      await ssh.execCommand(`echo "${base64Content}" | base64 -d > "${remoteFile}"`);
      console.log(`Uploaded ${rel}`);
    }

    console.log('Compiling on VPS (npx nest build)...');
    const buildRes = await ssh.execCommand('cd /opt/task-engine && npx nest build');
    console.log('Build output:', buildRes.stdout || buildRes.stderr || 'Build success');

    console.log('Restarting PM2 backend...');
    await ssh.execCommand('pm2 restart task-engine-api');
    console.log('Backend restarted successfully!');
  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

deploy();
