const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

const LOCAL_BASE = path.resolve(__dirname, '..', 'Task engine');

const FILES_TO_UPLOAD = [
  {
    local: path.join(LOCAL_BASE, 'shared/common/utils/task-identity.util.ts'),
    remote: '/opt/task-engine/shared/common/utils/task-identity.util.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/database/entities/worker-completed-identity.entity.ts'),
    remote: '/opt/task-engine/shared/database/entities/worker-completed-identity.entity.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/database/database.module.ts'),
    remote: '/opt/task-engine/shared/database/database.module.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'data-source.ts'),
    remote: '/opt/task-engine/data-source.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/database/migrations/1700000000003-CreateWorkerCompletedIdentities.ts'),
    remote: '/opt/task-engine/shared/database/migrations/1700000000003-CreateWorkerCompletedIdentities.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/database/repositories/task.repository.ts'),
    remote: '/opt/task-engine/shared/database/repositories/task.repository.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/database/repositories/campaign-worker-participation.repository.ts'),
    remote: '/opt/task-engine/shared/database/repositories/campaign-worker-participation.repository.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'task-engine/handlers/task-command.service.ts'),
    remote: '/opt/task-engine/task-engine/handlers/task-command.service.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'matching-engine/filters/duplicate-filter.service.ts'),
    remote: '/opt/task-engine/matching-engine/filters/duplicate-filter.service.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/services/order-activated.listener.ts'),
    remote: '/opt/task-engine/shared/services/order-activated.listener.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'apps/api/controllers/buyer/order.controller.ts'),
    remote: '/opt/task-engine/apps/api/controllers/buyer/order.controller.ts',
  },
  {
    local: path.join(__dirname, 'remote-test-suite.js'),
    remote: '/opt/task-engine/run-verification-suite.js',
  },
];

async function run() {
  try {
    console.log('Connecting to Mumbai VPS SSH (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS SSH!');

    // ── 2. Upload Files ─────────────────────────────────────────────────────
    console.log('\n--- 2. Uploading all updated source files to VPS ---');
    for (const item of FILES_TO_UPLOAD) {
      console.log(`Uploading ${path.basename(item.local)} -> ${item.remote}`);
      await ssh.putFile(item.local, item.remote);
    }
    console.log('✅ All 12 files uploaded successfully!');

    // ── 3. Build Project on VPS ─────────────────────────────────────────────
    console.log('\n--- 3. Running npm run build on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.code !== 0) {
      console.error('Build FAILED:', buildRes.stderr);
      process.exit(1);
    }
    console.log('✅ NestJS build completed with 0 errors!');

    // ── 4. Restart PM2 Services ─────────────────────────────────────────────
    console.log('\n--- 4. Restarting PM2 Services ---');
    const pm2Restart = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker');
    console.log(pm2Restart.stdout);

    // Wait 3s for services to stabilize
    await new Promise((r) => setTimeout(r, 3000));

    // ── 5. Run Comprehensive Test Suite on VPS ─────────────────────────────
    console.log('\n--- 5. Running Comprehensive Regression Test Suite ---');
    const testRes = await ssh.execCommand('node run-verification-suite.js', { cwd: '/opt/task-engine' });
    console.log(testRes.stdout);
    if (testRes.stderr) console.error('Test STDERR:', testRes.stderr);
    if (testRes.code !== 0) {
      console.error('❌ Some tests failed with code:', testRes.code);
      process.exit(1);
    }

    // ── 6. Check PM2 Status ────────────────────────────────────────────────
    console.log('\n--- 6. PM2 Cluster Status ---');
    const pm2ListRes = await ssh.execCommand('pm2 jlist');
    const pm2List = JSON.parse(pm2ListRes.stdout);
    for (const proc of pm2List) {
      console.log(`Process: ${proc.name.padEnd(20)} | Status: ${proc.pm2_env.status.padEnd(8)} | Restarts: ${proc.pm2_env.restart_time} | Uptime: ${Math.round((Date.now() - proc.pm2_env.pm_uptime)/1000)}s`);
    }

    console.log('\n🎉 ALL FIXES DEPLOYED AND REGRESSION TESTS 100% SUCCESSFUL!');
  } catch (err) {
    console.error('Deployment & Verification error:', err);
    process.exit(1);
  } finally {
    ssh.dispose();
  }
}

run();
