const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

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
      'task-engine/handlers/task-command.service.ts',
      'task-engine/task-validation.service.ts',
      'execution-engine/execution.service.ts',
      'apps/api/controllers/worker/task.controller.ts',
      'shared/database/repositories/task.repository.ts',
      'task-engine/queries/task-query.service.ts',
    ];

    console.log(`📤 Uploading ${filesToUpload.length} updated files to VPS...`);
    for (const relPath of filesToUpload) {
      const localFilePath = path.join(localBase, relPath);
      const remoteFilePath = `${remoteBase}/${relPath}`.replace(/\\/g, '/');
      const remoteDir = path.dirname(remoteFilePath).replace(/\\/g, '/');
      await ssh.execCommand(`mkdir -p "${remoteDir}"`);
      await ssh.putFile(localFilePath, remoteFilePath);
      console.log(`   ✅ Uploaded: ${relPath}`);
    }
    console.log('\nAll updated files uploaded successfully!\n');

    console.log('🔨 Compiling backend (npx nest build) on VPS...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log(buildRes.stdout || 'Build completed');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build warnings/output:', buildRes.stderr);
    }

    console.log('\n🔄 Restarting PM2 backend services (task-engine-api & task-engine-worker)...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', { cwd: remoteBase });
    console.log(restartRes.stdout);

    console.log('⏳ Waiting 4s for PM2 service to initialize...');
    await new Promise(r => setTimeout(r, 4000));

    // Automated end-to-end verification script on VPS
    const testCode = `
const http = require('http');

function request(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const postData = data ? JSON.stringify(data) : '';
    const options = {
      hostname: '127.0.0.1',
      port: 3000,
      path: '/api/v1' + path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': 'Bearer ' + token } : {}),
        ...(data ? { 'Content-Length': Buffer.byteLength(postData) } : {}),
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (_) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });

    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}

async function main() {
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

  console.log('=== 1. ACQUIRING TOKENS FOR ADMIN, BUYER & TWO WORKERS ===');
  const adminRes = await request('POST', '/auth/login', {
    email: 'admin@taskpost.com',
    password: 'Admin@123456',
  });
  const adminToken = adminRes.data?.data?.accessToken;
  console.log('Admin Token:', adminToken ? '✅ Acquired' : '❌ Failed');

  const buyerSuffix = Math.floor(1000 + Math.random() * 9000);
  const buyerRes = await request('POST', '/auth/register', {
    email: 'buyer_' + buyerSuffix + '@auditfix.com',
    password: 'TestPass123!',
    fullName: 'Audit Buyer ' + buyerSuffix,
    role: 'BUYER',
  });
  const buyerToken = buyerRes.data?.data?.accessToken;
  const buyerId = buyerRes.data?.data?.user?.id;
  console.log('Buyer Token:', buyerToken ? '✅ Acquired' : '❌ Failed');

  await request('POST', '/admin/wallet/topup', {
    buyerId,
    amount: 1000,
    referenceId: 'TOPUP_' + buyerSuffix,
    type: 'CREDIT',
  }, adminToken);

  const w1Suffix = Math.floor(1000 + Math.random() * 9000);
  const w1Res = await request('POST', '/auth/register', {
    email: 'worker_' + w1Suffix + '@auditfix.com',
    password: 'TestPass123!',
    fullName: 'Worker One ' + w1Suffix,
    role: 'WORKER',
  });
  const w1Token = w1Res.data?.data?.accessToken;
  console.log('Worker 1 Token:', w1Token ? '✅ Acquired' : '❌ Failed');

  const w2Suffix = Math.floor(1000 + Math.random() * 9000);
  const w2Res = await request('POST', '/auth/register', {
    email: 'worker_' + w2Suffix + '@auditfix.com',
    password: 'TestPass123!',
    fullName: 'Worker Two ' + w2Suffix,
    role: 'WORKER',
  });
  const w2Token = w2Res.data?.data?.accessToken;
  console.log('Worker 2 Token:', w2Token ? '✅ Acquired' : '❌ Failed');

  console.log('\\n=== 2. CREATING ORDER & WAITING FOR TASK GENERATION ===');
  const servicesRes = await request('GET', '/buyer/services', null, buyerToken);
  const servicesList = servicesRes.data?.data || servicesRes.data?.services || [];
  const testService = servicesList[0];

  const orderRes = await request('POST', '/buyer/orders', {
    serviceId: testService ? testService.id : 'youtube_comments_custom',
    quantity: 2,
    title: 'Audit Fix Order ' + buyerSuffix,
    requirements: { url: 'https://instagram.com/p/auditfix-' + buyerSuffix },
  }, buyerToken);
  const orderId = orderRes.data?.order?.id || orderRes.data?.data?.id;
  assert(Boolean(orderId), 'Order created successfully (ID: ' + orderId + ')');

  await new Promise(r => setTimeout(r, 3500));

  console.log('\\n=== 3. AVAILABLE TASKS FEED ===');
  const availRes = await request('GET', '/worker/tasks/available', null, w1Token);
  const availableTasks = availRes.data?.tasks || [];
  const testTask = availableTasks.find(t => t.orderId === orderId);
  assert(Boolean(testTask), 'Task from active order found in available feed (ID: ' + testTask?.id + ')');

  const taskId = testTask?.id;
  if (taskId) {
    console.log('\\n=== 4. ACCEPTING TASK (Worker 1) ===');
    const acceptRes = await request('POST', '/worker/tasks/' + taskId + '/accept', null, w1Token);
    assert(acceptRes.status === 200 || acceptRes.status === 201, 'Task accepted successfully');

    console.log('\\n=== 5. CHECKING TASK TIMELINE (FIX VERIFICATION) ===');
    const timelineRes = await request('GET', '/worker/tasks/' + taskId + '/timeline', null, w1Token);
    const timeline = timelineRes.data?.timeline || [];
    assert(
      timelineRes.status === 200 && Array.isArray(timeline) && timeline.length >= 2,
      'Timeline returns 200 OK with real transitions (Entries: ' + timeline.length + ', Statuses: ' + timeline.map(t => t.status).join(' -> ') + ')'
    );

    console.log('\\n=== 6. STARTING TASK (FIX VERIFICATION) ===');
    const startRes = await request('POST', '/worker/tasks/' + taskId + '/start', null, w1Token);
    assert(startRes.status === 200 || startRes.status === 201, 'Worker 1 started task successfully (Status: ' + startRes.status + ')');

    console.log('\\n=== 7. ANTI-BOT CHECK ON FAST SUBMIT ===');
    const fastSubmitRes = await request('POST', '/worker/tasks/' + taskId + '/submit', {
      data: { proofUrl: 'https://img.test/proof.png' },
      proofs: [{ fileId: 'p1', url: 'https://img.test/proof.png' }],
    }, w1Token);
    const submitErrMsg = fastSubmitRes.data?.error?.message || fastSubmitRes.data?.message || '';
    assert(
      fastSubmitRes.status === 400 && submitErrMsg.toLowerCase().includes('suspiciously fast'),
      'Instant bot submission rejected by anti-bot check: "' + submitErrMsg + '"'
    );

    console.log('\\n=== 8. SUBMITTING TASK AFTER LEGITIMATE DURATION (FIX VERIFICATION) ===');
    console.log('   Waiting 6 seconds for anti-bot duration to elapse...');
    await new Promise(r => setTimeout(r, 6000));

    const legitSubmitRes = await request('POST', '/worker/tasks/' + taskId + '/submit', {
      data: { commentText: 'Great work! #auditfix', proofUrl: 'https://img.test/legit-proof.png' },
      proofs: [{ fileId: 'p1', url: 'https://img.test/legit-proof.png' }],
    }, w1Token);
    assert(
      legitSubmitRes.status === 200 || legitSubmitRes.status === 201,
      'Worker 1 submitted task successfully (Status: ' + legitSubmitRes.status + ')'
    );

    console.log('\\n=== 9. VERIFYING SUBMITTED TASKS & TIMELINE ===');
    const submittedListRes = await request('GET', '/worker/tasks?status=submitted', null, w1Token);
    const submittedTasks = submittedListRes.data?.tasks || [];
    const isSubmittedFound = submittedTasks.some(t => t.id === taskId);
    assert(isSubmittedFound, 'Task is present in worker submitted tasks list');

    const timelineAfterSubmitRes = await request('GET', '/worker/tasks/' + taskId + '/timeline', null, w1Token);
    const updatedTimeline = timelineAfterSubmitRes.data?.timeline || [];
    assert(
      updatedTimeline.some(t => t.status === 'SUBMITTED' || t.status === 'UNDER_REVIEW'),
      'Timeline accurately reflects SUBMITTED transition (Statuses: ' + updatedTimeline.map(t => t.status).join(' -> ') + ')'
    );

    console.log('\\n=== 10. CROSS-WORKER ACCESS CONTROL ===');
    const crossRes = await request('GET', '/worker/tasks/' + taskId, null, w2Token);
    assert(crossRes.status === 403, 'Unauthorized Worker 2 correctly blocked with 403 Forbidden');
  }

  console.log('\\n🏁 FINAL RESULT: ' + passed + ' passed, ' + failed + ' failed.');
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
`;

    const localTmp = path.resolve(__dirname, 'temp_verify_runner.js');
    fs.writeFileSync(localTmp, testCode, 'utf8');
    await ssh.putFile(localTmp, '/tmp/run_audit_fix_verification.js');
    fs.unlinkSync(localTmp);

    console.log('🧪 Running live verification test suite on VPS...');
    const testExec = await ssh.execCommand('node /tmp/run_audit_fix_verification.js');
    console.log(testExec.stdout);
    if (testExec.stderr) {
      console.warn('STDERR:', testExec.stderr);
    }

    ssh.dispose();
    if (testExec.code !== 0) {
      process.exit(1);
    }
  } catch (error) {
    console.error('Execution error:', error);
    if (ssh.isConnected()) ssh.dispose();
    process.exit(1);
  }
}

deployAndVerify();
