const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  const localFile = path.resolve(__dirname, '../Task engine/shared/engines/reallocation-engine/services/task-release.service.ts');
  const remoteFile = '/opt/task-engine/shared/engines/reallocation-engine/services/task-release.service.ts';

  console.log('Uploading updated task-release.service.ts...');
  await ssh.putFile(localFile, remoteFile);
  console.log('Building NestJS backend on VPS...');
  const build = await ssh.execCommand('cd /opt/task-engine && npm run build');
  console.log('Build output:', build.stdout || build.stderr);

  console.log('Restarting PM2 processes...');
  await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');

  const status = await ssh.execCommand('pm2 status');
  console.log(status.stdout);

  ssh.dispose();
  process.exit(0);
}

run().catch(console.error);
