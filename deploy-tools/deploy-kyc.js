const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployKycFix() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const localFile = path.resolve(__dirname, '../Task engine/apps/api/controllers/admin/kyc-management.controller.ts');
    const remoteFile = '/opt/task-engine/apps/api/controllers/admin/kyc-management.controller.ts';

    console.log('Uploading kyc-management.controller.ts to VPS...');
    await ssh.putFile(localFile, remoteFile);
    console.log('Building NestJS backend on VPS...');
    const build = await ssh.execCommand('npx nest build', { cwd: '/opt/task-engine' });
    console.log(build.stdout || 'Build completed.');
    console.log('Restarting task-engine-api and task-engine-worker...');
    await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log('✅ KYC Route Fix Deployed Successfully!');
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

deployKycFix();
