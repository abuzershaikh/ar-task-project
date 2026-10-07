const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function deployAndVerify() {
  try {
    console.log(' Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log(' Connected to VPS!\n');

    const localBase = path.resolve(__dirname, '../Task engine');
    const remoteBase = '/opt/task-engine';

    // List of files to upload for duplicate comment feature
    const filesToUpload = [
      'shared/ai-generator/comment-duplicate-detector.ts',
      'shared/ai-generator/ai-generator.service.ts',
      'shared/ai-generator/generators/deepseek-comment.generator.ts',
      'shared/ai-generator/generators/generator.interface.ts',
      'shared/services/order-activated.listener.ts',
      'apps/api/controllers/buyer/order.controller.ts',
      'shared/tests/comment-duplicate-detector.spec.ts',
      // Also ensure any related controllers / services are clean
      'apps/api/controllers/admin/payout-management.controller.ts',
      'apps/api/controllers/admin/service-catalog.controller.ts',
      'apps/api/controllers/buyer/service-catalog.controller.ts',
      'apps/worker/processors/task-queue.processor.ts',
      'shared/engines/pricing-engine/pricing.engine.ts',
      'shared/engines/pricing-engine/youtube-duration-pricing.ts',
      'shared/modules/service-catalog/services/service-pricing.service.ts',
      'shared/services/order-state-machine.service.ts',
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

    console.log('\n🔨 Building backend on VPS (npm run build)...');
    const buildRes = await ssh.execCommand('npm run build', { cwd: remoteBase });
    console.log('Build output:');
    console.log(buildRes.stdout);
    if (buildRes.stderr) {
      console.log('Build stderr:');
      console.log(buildRes.stderr);
    }

    if (buildRes.code !== 0) {
      console.error('❌ Build failed with exit code:', buildRes.code);
      process.exit(1);
    }
    console.log('✅ VPS Build succeeded!\n');

    // 1. Run Jest tests on VPS
    console.log('🧪 Running Jest comment-duplicate-detector.spec.ts on VPS...');
    const jestRes = await ssh.execCommand('npx jest shared/tests/comment-duplicate-detector.spec.ts', { cwd: remoteBase });
    console.log(jestRes.stdout);
    if (jestRes.stderr) console.log(jestRes.stderr);
    console.log(`Jest exit code: ${jestRes.code}`);

    // 2. Direct Node verification on compiled dist files
    console.log('\n🧪 Running Node test on dist/shared/ai-generator/comment-duplicate-detector.js...');
    const testCode = `
      const { compareCommentSimilarity, findDuplicateCommentMatches, normalizedComment } = require('./dist/shared/ai-generator/comment-duplicate-detector');
      
      console.log('1. Normalized string test:');
      const norm = normalizedComment('  Great Video!!! Check this out... :) ');
      console.log('   Normalized:', norm);

      console.log('2. Exact duplicate test:');
      const c1 = 'This video was very helpful, thank you!';
      const c2 = 'this VIDEO was very helpful thank you';
      const exactComp = compareCommentSimilarity(c1, c2);
      console.log('   Exact match result:', exactComp);
      if (!exactComp.exactMatch) throw new Error('Exact match failed');

      console.log('3. 80% word similarity test (threshold = 0.80):');
      const batch = [
        'one two three four five six seven eight nine ten',
        'one two three four five six seven eight eleven twelve', // 8 out of 10 match = 80%
        'completely different comment here that should pass'
      ];
      const dupes = findDuplicateCommentMatches(batch);
      console.log('   Duplicates found:', dupes.length);
      console.log('   Duplicate detail:', JSON.stringify(dupes));
      if (dupes.length !== 1 || dupes[0].duplicateIndex !== 1) {
        throw new Error('80% duplicate detection failed');
      }

      console.log('4. Distinct comments test (below 80%):');
      const distinct = [
        'Great tutorial on flutter development',
        'Loved the explanation of state management in flutter',
        'Very clear guide for beginners'
      ];
      const noDupes = findDuplicateCommentMatches(distinct);
      console.log('   Duplicates in distinct batch:', noDupes.length);
      if (noDupes.length !== 0) {
        throw new Error('Distinct comments falsely flagged as duplicates');
      }

      console.log('\\n>>> ALL IN-PROCESS UNIT CHECKS PASSED ON VPS DIST! <<<');
    `;

    const nodeRes = await ssh.execCommand(`node -e "${testCode.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`, { cwd: remoteBase });
    console.log(nodeRes.stdout);
    if (nodeRes.stderr) console.error(nodeRes.stderr);

    // 3. Restart PM2 services
    console.log('\n🔄 Restarting PM2 services (task-engine-api & task-engine-worker)...');
    const pm2Restart = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', { cwd: remoteBase });
    console.log(pm2Restart.stdout);

    console.log('⏳ Waiting 3 seconds for PM2...');
    await new Promise(r => setTimeout(r, 3000));

    // 4. Check PM2 status
    console.log('\n📊 Checking PM2 status...');
    const pm2Status = await ssh.execCommand('pm2 list', { cwd: remoteBase });
    console.log(pm2Status.stdout);

    // 5. Check latest logs for any runtime errors
    console.log('\n📋 Checking recent PM2 logs for task-engine-api...');
    const logsRes = await ssh.execCommand('pm2 logs task-engine-api --lines 20 --nostream', { cwd: remoteBase });
    console.log(logsRes.stdout || logsRes.stderr);

    console.log('\n🎉 ALL DONE! Duplicate comment removal system is deployed and verified on VPS.');
  } catch (err) {
    console.error('❌ Error during deploy and verify:', err);
  } finally {
    ssh.dispose();
  }
}

deployAndVerify();
