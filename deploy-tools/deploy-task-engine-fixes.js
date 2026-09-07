const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function deployTaskEngineFixes() {
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
      'matching-engine/filters/category-filter.service.ts',
      'matching-engine/filters/location-filter.service.ts',
      'matching-engine/filters/capacity-filter.service.ts',
      'allocation-engine/services/assignment.service.ts',
      'shared/database/repositories/task.repository.ts',
      'shared/database/repositories/order.repository.ts',
      'matching-engine/matching-engine.service.ts',
      'allocation-engine/services/batch.service.ts',
      'shared/engines/reallocation-engine/services/reassignment.service.ts',
      'shared/engines/reallocation-engine/services/task-release.service.ts',
      'shared/engines/reallocation-engine/services/deadline-monitor.service.ts',
      'execution-engine/execution.service.ts',
      'apps/api/controllers/worker/task.controller.ts',
      'progress-engine/services/campaign-progress.service.ts',
      'apps/worker/processors/allocation-queue.processor.ts',
      'apps/api/controllers/admin/system-settings.controller.ts',
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
    console.log('\nAll 15 files uploaded successfully!\n');

    console.log('🔨 Compiling backend (npx nest build) on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log(buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build output:', buildRes.stderr);
    }
    console.log('');

    console.log('🔄 Restarting PM2 backend service (task-engine-api)...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout);
    console.log('');

    console.log('⏳ Waiting 4s for PM2 service to initialize...');
    await new Promise(r => setTimeout(r, 4000));

    console.log('🔍 Checking PM2 status...');
    const pm2Status = await ssh.execCommand('pm2 status task-engine-api');
    console.log(pm2Status.stdout);

    ssh.dispose();
    console.log('Deployment complete!');
  } catch (error) {
    console.error('Deployment error:', error);
    if (ssh.isConnected()) ssh.dispose();
    process.exit(1);
  }
}

deployTaskEngineFixes();
