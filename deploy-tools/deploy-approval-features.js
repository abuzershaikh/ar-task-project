const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

const LOCAL_BASE = path.resolve(__dirname, '..', 'Task engine');

const FILES_TO_UPLOAD = [
  {
    local: path.join(LOCAL_BASE, 'review-engine/services/review-assignment.service.ts'),
    remote: '/opt/task-engine/review-engine/services/review-assignment.service.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/database/repositories/order.repository.ts'),
    remote: '/opt/task-engine/shared/database/repositories/order.repository.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'apps/api/controllers/buyer/review.controller.ts'),
    remote: '/opt/task-engine/apps/api/controllers/buyer/review.controller.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'shared/database/migrations/1700000000001-AddWorkerActivityColumns.ts'),
    remote: '/opt/task-engine/shared/database/migrations/1700000000001-AddWorkerActivityColumns.ts',
  },
  {
    local: path.join(LOCAL_BASE, 'apps/api/controllers/buyer/order.controller.ts'),
    remote: '/opt/task-engine/apps/api/controllers/buyer/order.controller.ts',
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

    console.log('\nUploading modified backend files to VPS...');
    for (const f of FILES_TO_UPLOAD) {
      console.log(`Uploading: ${path.basename(f.local)} -> ${f.remote}`);
      await ssh.putFile(f.local, f.remote);
    }
    console.log('✅ All files uploaded successfully!');

    console.log('\nBuilding NestJS backend on VPS...');
    const buildRes = await ssh.execCommand('npm run build', {
      cwd: '/opt/task-engine',
    });
    console.log('Build output:');
    console.log(buildRes.stdout);
    if (buildRes.stderr) {
      console.log('Build stderr:', buildRes.stderr);
    }
    if (buildRes.code !== 0) {
      throw new Error(`Build failed with exit code ${buildRes.code}`);
    }
    console.log('✅ NestJS build completed successfully!');

    console.log('\nRestarting PM2 services...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', {
      cwd: '/opt/task-engine',
    });
    console.log(restartRes.stdout);

    console.log('\nWaiting 4 seconds for services to initialize...');
    await new Promise((r) => setTimeout(r, 4000));

    console.log('\nChecking PM2 status...');
    const statusRes = await ssh.execCommand('pm2 status', {
      cwd: '/opt/task-engine',
    });
    console.log(statusRes.stdout);

    console.log('\nChecking API logs for any errors...');
    const logsRes = await ssh.execCommand('pm2 logs task-engine-api --lines 30 --nostream', {
      cwd: '/opt/task-engine',
    });
    console.log(logsRes.stdout);

    console.log('\n✅ Deployment complete!');
  } catch (err) {
    console.error('❌ Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

run();
