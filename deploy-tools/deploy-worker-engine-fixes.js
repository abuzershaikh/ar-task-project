const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function deployWorkerEngineFixes() {
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
      'apps/api/controllers/worker/task.controller.ts',
      'task-engine/task-validation.service.ts',
      'task-engine/task-state-machine.ts',
      'task-engine/handlers/task-command.service.ts',
      'shared/database/repositories/task.repository.ts',
      'shared/auth/auth.service.ts',
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
const { TaskRepository } = require('./dist/shared/database/repositories/task.repository');
const { TaskEngineService } = require('./dist/task-engine/task-engine.service');
const { WorkerRepository } = require('./dist/shared/database/repositories/worker.repository');
const { AuthService } = require('./dist/shared/auth/auth.service');

async function runTests() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
  const taskRepo = app.get(TaskRepository);
  const taskEngine = app.get(TaskEngineService);
  const workerRepo = app.get(WorkerRepository);
  const authService = app.get(AuthService);

  console.log('--- TEST 1: Available tasks feed does NOT contain draft tasks ---');
  const available = await taskRepo.findAvailableForAssignment();
  const hasDraft = available.some(t => t.status === 'draft' || t.status === 'DRAFT');
  console.log('Available tasks count:', available.length);
  console.log('Contains DRAFT tasks:', hasDraft ? 'FAIL (Draft present)' : 'PASS (No draft tasks in available feed)');

  console.log('\\n--- TEST 2: Worker registration status ---');
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const regEmail = 'lifecycle_worker_' + rnd + '@test.com';
  const regRes = await authService.register({
    email: regEmail,
    password: 'Password123!',
    fullName: 'Lifecycle Worker ' + rnd,
    role: 'WORKER'
  });
  const createdWorker = await workerRepo.findWorker(regRes.user.id);
  console.log('Created worker status:', createdWorker ? createdWorker.status : 'None', '(Expected active)');
  console.log('Created worker kycStatus:', createdWorker ? createdWorker.kycStatus : 'None', '(Expected pending)');
  console.log('Registration status check:', (createdWorker && createdWorker.status === 'active') ? 'PASS' : 'FAIL');

  console.log('\\n--- TEST 3: Create test task & verify lifecycle transitions ---');
  const testTask = await taskEngine.createTask({
    orderId: 'test_order_' + rnd,
    campaignId: 'test_camp_' + rnd,
    taskType: 'app_review',
    rewardAmount: 10,
    requirements: {},
    metadata: { test: true }
  });
  console.log('Created test task:', testTask.id, 'Status:', testTask.status);

  // Accept task
  console.log('Testing acceptTask for worker:', regRes.user.id);
  const accepted = await taskEngine.acceptTask({ taskId: testTask.id, workerId: regRes.user.id });
  console.log('Task after accept:', accepted.status, 'assignedTo:', accepted.assignedTo);
  console.log('Accept test:', accepted.status === 'accepted' ? 'PASS' : 'FAIL');

  // Start task
  console.log('Testing startTask...');
  const started = await taskEngine.startTask({ taskId: testTask.id, workerId: regRes.user.id });
  console.log('Task after start:', started.status, '(Expected in_progress)');
  console.log('Start test:', started.status === 'in_progress' ? 'PASS' : 'FAIL');

  // Submit task -> should be UNDER_REVIEW
  console.log('Testing submitTask...');
  const submitted = await taskEngine.submitTask({ taskId: testTask.id, workerId: regRes.user.id, data: { text: 'Done' } });
  console.log('Task after submit:', submitted.status, '(Expected under_review)');
  console.log('Submit test:', submitted.status === 'under_review' ? 'PASS' : 'FAIL');

  // Reject task -> Unit must return to ACTIVE with assignedTo null
  console.log('Testing rejectTask (unit reallocation)...');
  const rejected = await taskEngine.rejectTask({ taskId: testTask.id, reviewedBy: 'admin', notes: 'Proof inadequate' });
  console.log('Task after reject:', rejected.status, 'assignedTo:', rejected.assignedTo);
  if (rejected.status === 'active' && rejected.assignedTo === null) {
    console.log('Reject unit reallocation: PASS (Unit returned to ACTIVE with assignedTo null)');
  } else {
    console.log('Reject unit reallocation: FAIL');
  }

  // Cleanup test task
  await taskRepo.delete(testTask.id);
  console.log('\\n🎉 ALL VERIFICATION CHECKS COMPLETE!');
  await app.close();
}

runTests().catch(err => {
  console.error('Test execution error:', err);
  process.exit(1);
});
`;

    // Upload and run test file
    const localTestPath = path.join(__dirname, 'test-vps-lifecycle.js');
    fs.writeFileSync(localTestPath, testFileContent);
    await ssh.putFile(localTestPath, `${remoteBase}/test-vps-lifecycle.js`);
    fs.unlinkSync(localTestPath);

    const testOutput = await ssh.execCommand('node test-vps-lifecycle.js', { cwd: remoteBase });
    console.log(testOutput.stdout || testOutput.stderr);

    // Also remove test file on VPS
    await ssh.execCommand('rm -f test-vps-lifecycle.js', { cwd: remoteBase });

  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deployWorkerEngineFixes();
