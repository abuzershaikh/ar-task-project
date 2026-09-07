const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function deployFinanceAndWalletFixes() {
  try {
    console.log('🚀 Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS!\n');

    const localBase = path.resolve(__dirname, '../Task engine');
    const remoteBase = '/opt/task-engine';

    const filesToUpload = [
      'shared/database/entities/payment-transaction.entity.ts',
      'shared/services/wallet.service.ts',
      'apps/api/controllers/buyer/wallet.controller.ts',
      'shared/modules/service-catalog/services/service-pricing.service.ts',
      'shared/engines/pricing-engine/price-snapshot.service.ts',
      'apps/api/controllers/buyer/order.controller.ts',
      'shared/database/repositories/order.repository.ts',
      'apps/api/controllers/admin/dashboard.controller.ts',
      'shared/database/repositories/earning.repository.ts',
      'shared/database/repositories/withdrawal.repository.ts',
      'payout-engine/services/withdrawal.service.ts',
      'payout-engine/payout.service.ts',
      'apps/api/controllers/admin/payout-management.controller.ts',
      'apps/api/controllers/worker/earning.controller.ts',
      'earning-engine/earning.service.ts',
    ];

    console.log(`📤 Uploading ${filesToUpload.length} files to VPS...`);
    for (const relPath of filesToUpload) {
      const localFilePath = path.join(localBase, relPath);
      const remoteFilePath = `${remoteBase}/${relPath}`.replace(/\\/g, '/');
      const remoteDir = path.dirname(remoteFilePath).replace(/\\/g, '/');
      await ssh.execCommand(`mkdir -p "${remoteDir}"`);
      await ssh.putFile(localFilePath, remoteFilePath);
      console.log(`   ✅ Uploaded: ${relPath}`);
    }
    console.log('\nAll files uploaded successfully!\n');

    console.log('🔨 Compiling backend (npx nest build) on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log(buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build warnings/errors:', buildRes.stderr);
    }
    console.log('');

    console.log('🔄 Restarting PM2 backend service (task-engine-api)...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout);
    console.log('');

    console.log('⏳ Waiting 4s for PM2 service to initialize...');
    await new Promise(r => setTimeout(r, 4000));

    console.log('✅ Deployment and restart completed successfully!');
    ssh.dispose();
    console.log('✨ All done!');
  } catch (err) {
    console.error('❌ Deployment error:', err);
    ssh.dispose();
    process.exit(1);
  }
}

deployFinanceAndWalletFixes();
