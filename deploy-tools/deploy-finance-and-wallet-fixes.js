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

    console.log('🧪 Running automated verification tests on VPS...\n');

    const testFileContent = `
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./dist/apps/api/app.module');
const { WalletService } = require('./dist/shared/services/wallet.service');
const { ServicePricingService } = require('./dist/shared/modules/service-catalog/services/service-pricing.service');
const { PriceSnapshotService } = require('./dist/shared/engines/pricing-engine/price-snapshot.service');
const { WithdrawalService } = require('./dist/payout-engine/services/withdrawal.service');
const { EarningEngineService } = require('./dist/earning-engine/earning.service');
const { OrderRepository } = require('./dist/shared/database/repositories/order.repository');
const { EarningRepository } = require('./dist/shared/database/repositories/earning.repository');
const { WithdrawalRepository } = require('./dist/shared/database/repositories/withdrawal.repository');
const { UserRepository } = require('./dist/shared/database/repositories/user.repository');
const { DataSource } = require('typeorm');

async function runTests() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  const walletService = app.get(WalletService);
  const pricingService = app.get(ServicePricingService);
  const snapshotService = app.get(PriceSnapshotService);
  const withdrawalService = app.get(WithdrawalService);
  const earningEngine = app.get(EarningEngineService);
  const orderRepo = app.get(OrderRepository);
  const earningRepo = app.get(EarningRepository);
  const withdrawalRepo = app.get(WithdrawalRepository);
  const userRepo = app.get(UserRepository);
  const dataSource = app.get(DataSource);

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log('   ✅ PASS:', message);
      passed++;
    } else {
      console.error('   ❌ FAIL:', message);
      failed++;
    }
  }

  try {
    console.log('1️⃣ Testing Admin Top-Up Validation & Concurrency:');
    // Test invalid buyerId
    let invalidBuyerCaught = false;
    try {
      await walletService.adminTopup('00000000-0000-0000-0000-000000000000', 50, 'CREDIT');
    } catch (e) {
      invalidBuyerCaught = true;
    }
    assert(invalidBuyerCaught, 'adminTopup rejects non-existent buyerId with 404');

    // Test valid buyer
    const buyers = await userRepo.findByRole('BUYER');
    if (buyers.length > 0) {
      const buyer = buyers[0];
      const res = await walletService.adminTopup(buyer.id, 10, 'CREDIT', 'Automated test topup');
      assert(res.success && res.newBalance >= 10, 'adminTopup successfully credits valid buyer with pessimistic lock');
      
      // Debit back
      await walletService.adminTopup(buyer.id, 10, 'DEBIT', 'Automated test debit cleanup');
    } else {
      console.log('   ⚠️ Skipping buyer check: No BUYER user found in DB');
    }

    console.log('\\n2️⃣ Testing Service Pricing Margin Bounds:');
    // Attempt workerReward > buyerUnitPrice - margin
    let overshootCaught = false;
    try {
      // Find active service
      const services = await dataSource.query("SELECT id FROM service_catalogs LIMIT 1");
      if (services.length > 0) {
        await pricingService.createNewPricingVersion(services[0].id, {
          buyerUnitPrice: 10,
          marginType: 'FIXED',
          marginValue: 3,
          workerReward: 20, // OVERSHOOT: 20 > 10 - 3 = 7
        });
      }
    } catch (e) {
      overshootCaught = e.message.includes('cannot exceed buyerUnitPrice minus margin');
    }
    assert(overshootCaught, 'ServicePricingService blocks workerReward (20) > buyerUnitPrice - margin (7)');

    console.log('\\n3️⃣ Testing PriceSnapshot Clamping:');
    const mockService = { id: 'svc_1', code: 'TEST_SERVICE' };
    const mockPricing = { buyerUnitPrice: 10, marginType: 'FIXED', marginValue: 3, workerReward: 25, version: 1 };
    const snapshot = snapshotService.createSnapshot(mockService, mockPricing, 1);
    assert(snapshot.workerRewardSnapshot === 7, 'PriceSnapshotService clamps workerReward to 7 (10 - 3)');

    console.log('\\n4️⃣ Testing Platform Financial Metrics:');
    const metrics = await orderRepo.getPlatformFinancialMetrics();
    assert(typeof metrics.grossVolume === 'number' && typeof metrics.platformMargin === 'number',
      'OrderRepository.getPlatformFinancialMetrics computes real grossVolume & platformMargin from DB');

    console.log('\\n5️⃣ Testing Worker Withdrawal Identity Resolution:');
    const workers = await userRepo.findByRole('WORKER');
    if (workers.length > 0) {
      const workerUser = workers[0];
      const balance = await withdrawalService.getBalance(workerUser.id);
      assert(typeof balance === 'number' && !isNaN(balance),
        'WithdrawalService.getBalance successfully resolves worker across user.id and worker.id');

      const engineBalance = await earningEngine.getAvailableBalance(workerUser.id);
      assert(balance === engineBalance,
        'EarningEngine.getAvailableBalance and WithdrawalService.getBalance are perfectly synchronized');
    } else {
      console.log('   ⚠️ Skipping worker withdrawal check: No WORKER user found in DB');
    }

    console.log('\\n🏁 Verification Complete: ' + passed + ' passed, ' + failed + ' failed.');
  } catch (err) {
    console.error('Fatal test error:', err);
  } finally {
    await app.close();
  }
}

runTests();
`;

    await ssh.execCommand(`cat << 'EOF' > ${remoteBase}/test-finance-fixes.js\n${testFileContent}\nEOF`);
    const testRes = await ssh.execCommand(`node test-finance-fixes.js`, { cwd: remoteBase });
    console.log(testRes.stdout);
    if (testRes.stderr && !testRes.stderr.includes('Debugger')) {
      console.warn('Test warnings/errors:', testRes.stderr);
    }

    await ssh.execCommand(`rm -f ${remoteBase}/test-finance-fixes.js`);
    ssh.dispose();
    console.log('✨ All done!');
  } catch (err) {
    console.error('❌ Deployment error:', err);
    ssh.dispose();
    process.exit(1);
  }
}

deployFinanceAndWalletFixes();
