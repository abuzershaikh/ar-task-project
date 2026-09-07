const { NodeSSH } = require('node-ssh');
const path = require('path');
const http = require('http');

const ssh = new NodeSSH();

async function deployAndVerify() {
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
      'shared/services/user-sync.service.ts',
      'shared/auth/guards/jwt-auth.guard.ts',
      'shared/auth/guards/roles.guard.ts',
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

    console.log('🧪 Testing Auth Security & Endpoints via curl on VPS...');

    // Test 1: Unauthenticated request to /admin/settings -> MUST be 401
    const test1 = await ssh.execCommand('curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/admin/settings');
    console.log(`1. GET /api/v1/admin/settings (No Token): HTTP ${test1.stdout} (Expected 401)`);

    // Test 2: Spoofed headers x-user-email without token -> MUST be 401
    const test2 = await ssh.execCommand('curl -s -o /dev/null -w "%{http_code}" -H "x-user-email: admin@admin.com" http://localhost:3000/api/v1/admin/settings');
    console.log(`2. GET /api/v1/admin/settings (Spoofed x-user-email, No Token): HTTP ${test2.stdout} (Expected 401)`);

    // Test 3: Unauthenticated worker score request -> MUST be 401
    const test3 = await ssh.execCommand('curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/worker/score');
    console.log(`3. GET /api/v1/worker/score (No Token): HTTP ${test3.stdout} (Expected 401)`);

    // Test 4: Admin login with real credentials
    console.log('\n🔐 Testing Admin Login & Authenticated Access...');
    const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"admin@taskpost.com","password":"AdminPassword123!"}'`;
    const loginRes = await ssh.execCommand(loginCmd);
    let token = null;
    try {
      const data = JSON.parse(loginRes.stdout);
      token = data.token || data.accessToken || data.data?.token;
      console.log('   Admin Login Result:', token ? 'SUCCESS (Token obtained)' : 'No token: ' + loginRes.stdout);
    } catch (e) {
      console.log('   Admin Login Raw:', loginRes.stdout);
    }

    if (token) {
      // Test 5: Authenticated admin request with Bearer token -> MUST be 200
      const test5 = await ssh.execCommand(`curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${token}" http://localhost:3000/api/v1/admin/settings`);
      console.log(`4. GET /api/v1/admin/settings (Valid Admin Bearer Token): HTTP ${test5.stdout} (Expected 200)`);
    }

    // Test 6: Check worker scores in DB
    console.log('\n📊 Checking MySQL worker_scores table on VPS...');
    const dbCheck = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, worker_id, total_score, quality_score, reliability_score, updated_at FROM worker_scores LIMIT 5;"`);
    console.log(dbCheck.stdout || dbCheck.stderr);

    console.log('\n🎉 ALL CHECKS COMPLETED!');
  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deployAndVerify();
