const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deploy() {
  console.log('Connecting to VPS...');
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  console.log('Connected to VPS.');

  const localBase = path.resolve(__dirname, '../Task engine');

  const filesToUpload = [
    {
      local: path.join(localBase, 'task-engine/handlers/task-command.service.ts'),
      remote: '/opt/task-engine/task-engine/handlers/task-command.service.ts',
    },
    {
      local: path.join(localBase, 'shared/database/repositories/task-assignment.repository.ts'),
      remote: '/opt/task-engine/shared/database/repositories/task-assignment.repository.ts',
    },
  ];

  for (const f of filesToUpload) {
    console.log(`Uploading ${f.local} -> ${f.remote}...`);
    await ssh.putFile(f.local, f.remote);
  }
  console.log('Files uploaded successfully.');

  console.log('Building Task Engine on VPS...');
  const buildRes = await ssh.execCommand('cd /opt/task-engine && npm run build');
  console.log('Build output:', buildRes.stdout || buildRes.stderr);

  if (buildRes.code !== 0) {
    throw new Error('Build failed on VPS: ' + buildRes.stderr);
  }

  console.log('Restarting PM2 services on VPS...');
  const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
  console.log(restartRes.stdout || restartRes.stderr);

  console.log('Checking PM2 status...');
  const statusRes = await ssh.execCommand('pm2 list');
  console.log(statusRes.stdout);

  ssh.dispose();
  console.log('Deployment completed successfully!');
}

deploy().catch((err) => {
  console.error('Deployment error:', err);
  process.exit(1);
});
