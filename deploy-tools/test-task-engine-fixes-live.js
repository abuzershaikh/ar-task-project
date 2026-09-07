const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function runLiveTaskEngineTests() {
  try {
    console.log('🚀 Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS!\n');

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
    email: 'buyer_' + buyerSuffix + '@testengine.com',
    password: 'TestPass123!',
    fullName: 'Engine Buyer ' + buyerSuffix,
    role: 'BUYER',
  });
  const buyerToken = buyerRes.data?.data?.accessToken;
  const buyerId = buyerRes.data?.data?.user?.id;
  console.log('Buyer Token:', buyerToken ? '✅ Acquired' : '❌ Failed', 'Buyer ID:', buyerId);

  // Fund buyer wallet via admin topup
  const topupRes = await request('POST', '/admin/wallet/topup', {
    buyerId,
    amount: 1000,
    referenceId: 'INITIAL_FUND_' + buyerSuffix,
    type: 'CREDIT',
  }, adminToken);
  assert(topupRes.status === 200 || topupRes.status === 201, 'Buyer wallet funded with ₹1000');

  // Worker 1
  const w1Suffix = Math.floor(1000 + Math.random() * 9000);
  const w1Res = await request('POST', '/auth/register', {
    email: 'worker_' + w1Suffix + '@testengine.com',
    password: 'TestPass123!',
    fullName: 'Worker One ' + w1Suffix,
    role: 'WORKER',
  });
  const w1Token = w1Res.data?.data?.accessToken;
  const w1UserId = w1Res.data?.data?.user?.id;
  console.log('Worker 1 Token:', w1Token ? '✅ Acquired' : '❌ Failed', 'User ID:', w1UserId);

  // Worker 2
  const w2Suffix = Math.floor(1000 + Math.random() * 9000);
  const w2Res = await request('POST', '/auth/register', {
    email: 'worker_' + w2Suffix + '@testengine.com',
    password: 'TestPass123!',
    fullName: 'Worker Two ' + w2Suffix,
    role: 'WORKER',
  });
  const w2Token = w2Res.data?.data?.accessToken;
  const w2UserId = w2Res.data?.data?.user?.id;
  console.log('Worker 2 Token:', w2Token ? '✅ Acquired' : '❌ Failed', 'User ID:', w2UserId);

  console.log('\\n=== 2. TESTING ORDER CREATION & TASK GENERATION ===');
  const servicesRes = await request('GET', '/buyer/services', null, buyerToken);
  const servicesList = servicesRes.data?.data || servicesRes.data?.services || [];
  const testService = servicesList[0];

  const orderRes = await request('POST', '/buyer/orders', {
    serviceId: testService ? testService.id : 'youtube_comments_custom',
    quantity: 2,
    title: 'Engine Test Order ' + buyerSuffix,
    requirements: {
      url: 'https://instagram.com/p/test-post-' + buyerSuffix,
      location: 'India',
      category: 'Instagram',
      maxConcurrentTasks: 5,
    },
  }, buyerToken);
  const orderId = orderRes.data?.order?.id || orderRes.data?.data?.id;
  assert(orderRes.status === 201 || orderRes.status === 200, 'Order created successfully (ID: ' + orderId + ')');

  // Wait 3s for background task generation
  await new Promise(r => setTimeout(r, 3000));

  console.log('\\n=== 3. TESTING AVAILABLE TASKS FEED ===');
  const availRes = await request('GET', '/worker/tasks/available', null, w1Token);
  const availableTasks = availRes.data?.tasks || availRes.data?.data || [];
  const testTask = availableTasks.find(t => t.orderId === orderId);
  assert(Boolean(testTask), 'Task from active order is present in worker available feed (Task ID: ' + testTask?.id + ')');

  console.log('\\n=== 4. TESTING WORKER TASK ACCEPTANCE & REAL TIMELINE ===');
  const taskId = testTask?.id;
  if (taskId) {
    const acceptRes = await request('POST', '/worker/tasks/' + taskId + '/accept', null, w1Token);
    assert(acceptRes.status === 200 || acceptRes.status === 201, 'Worker 1 accepted task successfully');

    // Check timeline
    const timelineRes = await request('GET', '/worker/tasks/' + taskId + '/timeline', null, w1Token);
    const timeline = timelineRes.data?.timeline || [];
    assert(
      Array.isArray(timeline) && timeline.length >= 2,
      'Task timeline returns real transitions (Entries: ' + timeline.length + ', Statuses: ' + timeline.map(t => t.status).join(' -> ') + ')'
    );

    console.log('\\n=== 5. TESTING WORKER CROSS-ACCESS SECURITY ===');
    // Worker 2 attempts to view Worker 1's assigned task
    const crossRes = await request('GET', '/worker/tasks/' + taskId, null, w2Token);
    assert(crossRes.status === 403, 'Unauthorized Worker 2 is BLOCKED with 403 Forbidden from viewing Worker 1 task');

    console.log('\\n=== 6. TESTING ANTI-BOT EXECUTION DURATION CHECK ===');
    // Worker 1 submits immediately (< 5s since accept)
    const fastSubmitRes = await request('POST', '/worker/tasks/' + taskId + '/submit', {
      data: { proofUrl: 'https://img.test/proof.png' },
      proofs: [{ fileId: 'p1', url: 'https://img.test/proof.png' }],
    }, w1Token);
    console.log('   fastSubmitRes status:', fastSubmitRes.status, 'data:', JSON.stringify(fastSubmitRes.data));
    const submitErrMsg = fastSubmitRes.data?.error?.message || fastSubmitRes.data?.message || '';
    assert(
      fastSubmitRes.status === 400 && submitErrMsg.toLowerCase().includes('suspiciously fast'),
      'Instant bot submission (<5s) correctly rejected by anti-bot check: "' + submitErrMsg + '"'
    );
  }

  console.log('\\n=== 7. TESTING PAUSED ORDER LEAK PREVENTION ===');
  // Buyer pauses order
  const pauseRes = await request('POST', '/buyer/orders/' + orderId + '/pause', null, buyerToken);
  assert(pauseRes.status === 200 || pauseRes.status === 201, 'Order successfully paused by Buyer');

  // Verify paused order tasks do NOT appear in available tasks feed
  const availAfterPauseRes = await request('GET', '/worker/tasks/available', null, w2Token);
  const availTasksAfterPause = availAfterPauseRes.data?.tasks || availAfterPauseRes.data?.data || [];
  const pausedTaskInFeed = availTasksAfterPause.find(t => t.orderId === orderId);
  assert(!pausedTaskInFeed, 'Tasks from PAUSED order are completely hidden from available worker feed');

  // Create another order and pause it immediately to test direct accept rejection
  const order2Res = await request('POST', '/buyer/orders', {
    serviceId: testService ? testService.id : 'youtube_comments_custom',
    quantity: 1,
    title: 'Engine Test Order 2 ' + buyerSuffix,
    requirements: { url: 'https://instagram.com/p/test2-' + buyerSuffix },
  }, buyerToken);
  const orderId2 = order2Res.data?.order?.id || order2Res.data?.data?.id;
  await new Promise(r => setTimeout(r, 3500));

  const avail2Res = await request('GET', '/worker/tasks/available', null, w2Token);
  const taskToPause = (avail2Res.data?.tasks || []).find(t => t.orderId === orderId2);
  
  if (taskToPause) {
    await request('POST', '/buyer/orders/' + orderId2 + '/pause', null, buyerToken);
    const directAcceptRes = await request('POST', '/worker/tasks/' + taskToPause.id + '/accept', null, w2Token);
    const directErrMsg = directAcceptRes.data?.error?.message || directAcceptRes.data?.message || '';
    assert(
      directAcceptRes.status === 400 && directErrMsg.toLowerCase().includes('paused'),
      'Attempt to accept task on PAUSED order is strictly rejected: "' + directErrMsg + '"'
    );

    // Resume order
    const resumeRes = await request('POST', '/buyer/orders/' + orderId2 + '/resume', null, buyerToken);
    assert(resumeRes.status === 200 || resumeRes.status === 201, 'Order successfully resumed by Buyer');
  } else {
    console.warn('   ⚠️ Task for order2 not yet visible in available tasks feed');
  }

  console.log('\\n=== 8. TESTING SYSTEM SETTING BOOLEAN PARSER ===');
  // Update task-expiry setting to autoReassignOnExpiry: false
  const updateSettingRes = await request('POST', '/admin/settings/task-expiry', {
    autoReassignOnExpiry: false,
    workerExecutionTimeoutHours: 3.5,
    unacceptedTaskExpiryHours: 12.0,
  }, adminToken);
  assert(updateSettingRes.status === 200 || updateSettingRes.status === 201, 'Admin updated task-expiry settings with autoReassignOnExpiry: false');

  // Verify GET task-expiry returns exact boolean false (not true!)
  const getSettingRes = await request('GET', '/admin/settings/task-expiry', null, adminToken);
  const returnedSetting = getSettingRes.data?.settings;
  assert(
    returnedSetting && returnedSetting.autoReassignOnExpiry === false && returnedSetting.workerExecutionTimeoutHours === 3.5,
    'GET task-expiry accurately returned boolean false for autoReassignOnExpiry (Value: ' + returnedSetting?.autoReassignOnExpiry + ')'
  );

  console.log('\\n🏁 SUMMARY: ' + passed + ' passed, ' + failed + ' failed.');
  process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
  console.error('Test script fatal error:', err);
  process.exit(1);
});
`;

    const localTmp = path.resolve(__dirname, 'temp_test_runner.js');
    fs.writeFileSync(localTmp, testCode, 'utf8');
    await ssh.putFile(localTmp, '/tmp/run_task_engine_tests.js');
    fs.unlinkSync(localTmp);

    console.log('🧪 Executing automated verification on Mumbai VPS...');
    const execRes = await ssh.execCommand('node /tmp/run_task_engine_tests.js');
    console.log(execRes.stdout);
    if (execRes.stderr) {
      console.warn('STDERR:', execRes.stderr);
    }

    ssh.dispose();
  } catch (error) {
    console.error('Test execution error:', error);
    if (ssh.isConnected()) ssh.dispose();
    process.exit(1);
  }
}

runLiveTaskEngineTests();
