const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployBillingFix() {
  try {
    console.log('🚀 Connecting to VPS...');
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    const localFile = path.resolve(__dirname, '../Task engine/apps/api/controllers/buyer/billing.controller.ts');
    const remoteFile = '/opt/task-engine/apps/api/controllers/buyer/billing.controller.ts';

    console.log('📤 Uploading billing.controller.ts...');
    await ssh.putFile(localFile, remoteFile);
    console.log('✅ Uploaded!');

    console.log('🔨 Compiling backend (npx nest build)...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr) console.log('STDERR:', buildRes.stderr);

    console.log('🔄 Restarting task-engine-api...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(restartRes.stdout);

    console.log('🎉 Deploy complete!');
  } catch (err) {
    console.error('Deploy error:', err);
  } finally {
    ssh.dispose();
  }
}

deployBillingFix();
