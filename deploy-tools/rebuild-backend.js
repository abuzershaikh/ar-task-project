const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function updateAndBuild() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    // Alter wallet_transactions schema
    await ssh.execCommand(`
      mysql -e "
        USE task_platform;
        ALTER TABLE wallet_transactions MODIFY COLUMN balance_after decimal(12,2) NOT NULL DEFAULT 0.00;
      "
    `);

    await ssh.putFile(
      path.join(localBase, 'shared/services/wallet.service.ts'),
      `${remoteBase}/shared/services/wallet.service.ts`
    );

    console.log('Building on VPS...');
    const bRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log('Build Output:', bRes.stdout);
    if (bRes.stderr) console.error('Build Stderr:', bRes.stderr);

    await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log('PM2 restarted successfully!');

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

updateAndBuild();
