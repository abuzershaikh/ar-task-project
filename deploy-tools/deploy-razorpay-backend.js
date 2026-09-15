const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployRazorpayBackend() {
  try {
    console.log('Connecting to VPS 65.20.77.112...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected!');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    // 1. Update /opt/task-engine/.env if keys missing
    console.log('Checking .env on VPS...');
    const envRes = await ssh.execCommand('cat /opt/task-engine/.env');
    let envContent = envRes.stdout;

    const rzpConfigs = [
      { key: 'RAZORPAY_KEY_ID', val: 'rzp_live_TI2wdFKYDJdAxY' },
      { key: 'RAZORPAY_KEY_SECRET', val: '0pNQOQBRWxmtdE8mPVLlvYfi' },
      { key: 'RAZORPAY_COMPANY_NAME', val: 'Ishyan Technologies' },
    ];

    let envUpdated = false;
    for (const item of rzpConfigs) {
      if (!envContent.includes(item.key + '=')) {
        envContent += `\n${item.key}=${item.val}`;
        envUpdated = true;
      } else {
        // Replace existing line to ensure latest
        const regex = new RegExp(`^${item.key}=.*$`, 'm');
        envContent = envContent.replace(regex, `${item.key}=${item.val}`);
        envUpdated = true;
      }
    }

    if (envUpdated) {
      console.log('Writing updated .env to VPS...');
      // Write temp and copy
      const escapedEnv = envContent.replace(/'/g, "'\\''");
      await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/.env\n${envContent}\nEOF`);
      console.log('.env updated successfully!');
    } else {
      console.log('.env already contains Razorpay configuration.');
    }

    // 2. Upload wallet.controller.ts
    console.log('Uploading wallet.controller.ts to VPS...');
    await ssh.putFile(
      path.join(localBase, 'apps/api/controllers/buyer/wallet.controller.ts'),
      `${remoteBase}/apps/api/controllers/buyer/wallet.controller.ts`
    );
    console.log('wallet.controller.ts uploaded successfully!');

    // 3. Build NestJS project
    console.log('Building NestJS backend on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log('Build output:', buildRes.stdout);
    if (buildRes.stderr) {
      console.warn('Build stderr:', buildRes.stderr);
    }

    // 4. Restart PM2 services
    console.log('Restarting PM2 processes...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log('PM2 restart output:', restartRes.stdout);

    // 5. Verify status
    const statusRes = await ssh.execCommand('pm2 list');
    console.log('PM2 status:\n', statusRes.stdout);

    console.log('Razorpay backend deployment completed successfully!');
  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
    console.log('SSH connection closed.');
  }
}

deployRazorpayBackend();
