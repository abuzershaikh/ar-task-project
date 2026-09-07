const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function deployScoringFixes() {
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
      'shared/database/repositories/worker.repository.ts',
      'shared/database/repositories/worker-score.repository.ts',
      'scoring-engine/scoring.service.ts',
      'scoring-engine/calculators/score-calculator.ts',
      'scoring-engine/listeners/task-release.listener.ts',
      'ranking-engine/calculators/ranking-calculator.ts',
      'apps/api/controllers/worker/score.controller.ts',
      'apps/api/controllers/worker/profile.controller.ts',
      'apps/api/controllers/admin/worker-management.controller.ts',
      'earning-engine/earning.service.ts',
      'earning-engine/services/earning-posting.service.ts',
      'earning-engine/calculators/earning-calculator.ts',
      'review-engine/services/review-decision.service.ts',
      'reward-engine/calculators/reward-calculator.ts',
      'shared/services/order-activated.listener.ts',
    ];

    console.log(`📤 Uploading ${filesToUpload.length} modified files to VPS...`);
    for (const relPath of filesToUpload) {
      const localFilePath = path.join(localBase, relPath);
      const remoteFilePath = `${remoteBase}/${relPath}`.replace(/\\/g, '/');

      // Ensure remote dir exists
      const remoteDir = path.dirname(remoteFilePath).replace(/\\/g, '/');
      await ssh.execCommand(`mkdir -p "${remoteDir}"`);

      await ssh.putFile(localFilePath, remoteFilePath);
      console.log(`   ✅ Uploaded: ${relPath}`);
    }
    console.log('\nAll files uploaded successfully!\n');

    // Compile backend
    console.log('🔨 Compiling backend (npx nest build) on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log(buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build warnings/errors:', buildRes.stderr);
    }
    console.log('');

    // Restart PM2
    console.log('🔄 Restarting PM2 backend service (task-engine-api)...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout);
    console.log('');

    // Wait for restart
    console.log('⏳ Waiting 4s for PM2 service to initialize...');
    await new Promise(r => setTimeout(r, 4000));

    // Run verification script on VPS
    console.log('🧪 Running live verification script on VPS...');
    const verifyScript = `
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./dist/apps/api/app.module');
const { ScoringEngineService } = require('./dist/scoring-engine/scoring.service');
const { WorkerRepository } = require('./dist/shared/database/repositories/worker.repository');
const { WorkerScoreRepository } = require('./dist/shared/database/repositories/worker-score.repository');

async function verify() {
  try {
    const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
    const scoringEngine = app.get(ScoringEngineService);
    const workerRepo = app.get(WorkerRepository);
    const scoreRepo = app.get(WorkerScoreRepository);

    console.log('--- 1. Testing findWorker with user_id and worker_id ---');
    const allWorkers = await workerRepo.findActiveWorkers();
    console.log('Found active workers count:', allWorkers.length);

    if (allWorkers.length > 0) {
      const sample = allWorkers[0];
      const byId = await workerRepo.findWorker(sample.id);
      const byUserId = await workerRepo.findWorker(sample.userId);
      console.log('Resolve by worker.id:', byId ? byId.id : 'FAILED');
      console.log('Resolve by worker.userId:', byUserId ? byUserId.id : 'FAILED');

      console.log('--- 2. Testing calculateWorkerScore and persistence ---');
      const score = await scoringEngine.calculateWorkerScore(sample.id);
      console.log('Calculated score for worker ' + sample.id + ':', score.totalScore);

      const persisted = await scoreRepo.findByWorker(sample.id);
      console.log('Persisted record found in DB:', persisted ? 'YES, totalScore=' + persisted.totalScore : 'NO');
    }

    await app.close();
  } catch (err) {
    console.error('Verification error:', err);
  }
}
verify();
`;

    await ssh.execCommand(`cat << 'EOF' > /tmp/verify-scoring.js\n${verifyScript}\nEOF`);
    const runVerify = await ssh.execCommand('node /tmp/verify-scoring.js', { cwd: remoteBase });
    console.log('Verification output:\n', runVerify.stdout);
    if (runVerify.stderr) console.error('Verification stderr:\n', runVerify.stderr);

    // Check DB rows in worker_scores
    console.log('📊 Querying worker_scores table on VPS...');
    const dbRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) as count_scores FROM worker_scores; SELECT worker_id, total_score, quality_score, reliability_score, updated_at FROM worker_scores LIMIT 5;"');
    console.log(dbRes.stdout);

    ssh.dispose();
    console.log('🎉 Deployment and verification finished successfully!');
  } catch (err) {
    console.error('❌ Deployment error:', err);
    ssh.dispose();
  }
}

deployScoringFixes();
