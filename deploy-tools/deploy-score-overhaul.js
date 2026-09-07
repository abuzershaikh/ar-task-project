const { NodeSSH } = require('node-ssh');
const path = require('path');

const ssh = new NodeSSH();

async function deployScoreOverhaul() {
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

    // All files modified/created in the scoring system overhaul
    const filesToUpload = [
      // Entity & Migration
      'shared/database/entities/worker.entity.ts',
      'shared/database/migrations/1700000000001-AddWorkerActivityColumns.ts',

      // Repository
      'shared/database/repositories/worker.repository.ts',

      // Scoring Engine
      'scoring-engine/types/worker-score.ts',
      'scoring-engine/calculators/score-calculator.ts',
      'scoring-engine/scoring.service.ts',
      'scoring-engine/listeners/task-release.listener.ts',

      // Eligibility Engine
      'eligibility-engine/eligibility-engine.module.ts',
      'eligibility-engine/eligibility.service.ts',

      // Matching Engine
      'matching-engine/filters/active-filter.service.ts',
      'matching-engine/services/matching-decision.service.ts',

      // Ranking Engine
      'ranking-engine/calculators/ranking-calculator.ts',
      'ranking-engine/types/ranked-worker.ts',

      // Controllers
      'apps/api/controllers/worker/score.controller.ts',
      'apps/api/controllers/worker/heartbeat.controller.ts',

      // App Module
      'apps/api/app.module.ts',
    ];

    console.log(`📤 Uploading ${filesToUpload.length} files to VPS...`);
    for (const relPath of filesToUpload) {
      const localFilePath = path.join(localBase, relPath);
      const remoteFilePath = `${remoteBase}/${relPath}`.replace(/\\/g, '/');

      // Ensure remote dir exists
      const remoteDir = path.dirname(remoteFilePath).replace(/\\/g, '/');
      await ssh.execCommand(`mkdir -p "${remoteDir}"`);

      await ssh.putFile(localFilePath, remoteFilePath);
      console.log(`   ✅ ${relPath}`);
    }
    console.log('\n✅ All files uploaded!\n');

    // Step 1: Run DB migration — add new columns to workers table
    console.log('🗄️  Running DB migration (adding lastActiveAt, performancePoints, taskCooldownUntil columns)...');
    const migrationSQL = `
      ALTER TABLE workers ADD COLUMN IF NOT EXISTS last_active_at timestamp NULL DEFAULT NULL;
      ALTER TABLE workers ADD COLUMN IF NOT EXISTS performance_points int NOT NULL DEFAULT 0;
      ALTER TABLE workers ADD COLUMN IF NOT EXISTS task_cooldown_until timestamp NULL DEFAULT NULL;
      UPDATE workers SET last_active_at = NOW() WHERE status = 'active' AND last_active_at IS NULL;
    `;
    const migRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${migrationSQL}"`);
    if (migRes.stdout) console.log(migRes.stdout);
    if (migRes.stderr && !migRes.stderr.includes('Duplicate column')) {
      console.warn('Migration warnings:', migRes.stderr);
    }
    console.log('✅ DB migration done!\n');

    // Step 2: Build
    console.log('🔨 Building backend (npx nest build)...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    if (buildRes.stdout) console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build output:', buildRes.stderr);
    }
    if (buildRes.code !== 0) {
      console.error('❌ Build failed! Check errors above.');
      ssh.dispose();
      return;
    }
    console.log('✅ Build successful!\n');

    // Step 3: Restart PM2
    console.log('🔄 Restarting PM2 services...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout || 'Restarted');
    
    // Also restart worker if exists
    const restartWorker = await ssh.execCommand('pm2 restart task-engine-worker 2>/dev/null || true', { cwd: remoteBase });
    if (restartWorker.stdout) console.log(restartWorker.stdout);
    console.log('');

    // Wait for restart
    console.log('⏳ Waiting 5s for services to initialize...');
    await new Promise(r => setTimeout(r, 5000));

    // Step 4: Verify DB columns exist
    console.log('🧪 Verifying DB columns...');
    const dbVerify = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT COUNT(*) as total_workers, SUM(CASE WHEN last_active_at IS NOT NULL THEN 1 ELSE 0 END) as active_with_heartbeat, AVG(performance_points) as avg_perf_points FROM workers;"`);
    console.log(dbVerify.stdout);

    // Step 5: Check PM2 status
    console.log('📊 PM2 Status:');
    const pm2Status = await ssh.execCommand('pm2 status');
    console.log(pm2Status.stdout);

    // Step 6: Test heartbeat endpoint
    console.log('🏓 Testing heartbeat endpoint...');
    const healthCheck = await ssh.execCommand('curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health');
    console.log(`Health check: HTTP ${healthCheck.stdout}`);

    // Step 7: Check recent logs for errors
    console.log('\n📋 Recent PM2 logs (last 15 lines):');
    const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 15 --nostream');
    console.log(logs.stdout || logs.stderr);

    ssh.dispose();
    console.log('\n🎉 ✅ Scoring System Overhaul deployed successfully!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('Changes deployed:');
    console.log('  • New score formula (35/25/20/10/10)');
    console.log('  • Activity tracking (lastActiveAt + 48h hard stop)');
    console.log('  • Rejection penalties (+1/-3/-5 + cooldown)');
    console.log('  • Minimum score threshold (40)');
    console.log('  • New worker starter score (60)');
    console.log('  • 5-tier priority system');
    console.log('  • POST /worker/heartbeat endpoint');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  } catch (err) {
    console.error('❌ Deployment error:', err);
    ssh.dispose();
  }
}

deployScoreOverhaul();
