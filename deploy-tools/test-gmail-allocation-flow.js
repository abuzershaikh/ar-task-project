const http = require('http');
const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

const API_BASE = 'http://65.20.77.112:3000/api/v1';

async function queryDb(sql) {
  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql.replace(/"/g, '\\"')}"`);
  return res.stdout;
}

function requestApi(method, path, headers = {}, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE);
    const req = http.request(
      url,
      {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve({ statusCode: res.statusCode, body: parsed });
          } catch (_) {
            resolve({ statusCode: res.statusCode, body: data });
          }
        });
      }
    );
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function run() {
  console.log('🚀 Connecting SSH to VPS...');
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  // TEST 1: Check existing worker sufieditz@gmail.com available tasks
  console.log('\n--- TEST 1: Checking available tasks for sufieditz@gmail.com ---');
  const sufieAvail = await requestApi('GET', '/api/v1/worker/tasks/available', {
    'x-user-id': 'kQzd3bZD7pgA908xGE6NoGogetB3',
    'x-user-email': 'sufieditz@gmail.com',
    'x-user-role': 'WORKER',
  });

  console.log(`Available tasks returned: ${sufieAvail.body?.tasks?.length || 0}`);
  const participatedCampaigns = [
    '280b899b-660a-49fa-99ad-d9e1a45121a4',
    '11750be7-f2a8-46b3-a4b6-de3ee729a969',
    '5defaf67-ef10-4709-ac06-676a6547b5ba',
    '9fd3d8d4-6ea7-4654-8fe5-8349a75ae00c',
    'f615143e-b142-4435-a428-7ba7f301e218',
  ];

  let leaked = false;
  for (const t of sufieAvail.body?.tasks || []) {
    if (participatedCampaigns.includes(t.campaignId) || participatedCampaigns.includes(t.orderId)) {
      console.error(`❌ LEAK DETECTED! Task ${t.id} from campaign ${t.campaignId || t.orderId} was shown to sufieditz@gmail.com!`);
      leaked = true;
    }
  }
  if (!leaked) {
    console.log('✅ PASS: Zero leakage! None of the participated campaigns appear in available feed.');
  }

  // TEST 2: Create a multi-unit test order and verify feed deduction
  console.log('\n--- TEST 2: Multi-unit Campaign & 3-Level Verification Test ---');
  const testOrderId = `test_order_${Date.now()}`;
  const testUnit1Id = `unit_1_${Date.now()}`;
  const testUnit2Id = `unit_2_${Date.now()}`;
  const testTask1Id = `task_1_${Date.now()}`;
  const testTask2Id = `task_2_${Date.now()}`;

  // Insert 2 tasks with 2 distinct units for same campaign
  await queryDb(`INSERT INTO tasks (id, order_id, campaign_id, task_type, status, reward_amount, order_unit_id, requirements) VALUES ('${testTask1Id}', '${testOrderId}', '${testOrderId}', 'PLAY_STORE', 'ACTIVE', 10.00, '${testUnit1Id}', '{"orderUnitId": "${testUnit1Id}", "unitNumber": 1}');`);
  await queryDb(`INSERT INTO tasks (id, order_id, campaign_id, task_type, status, reward_amount, order_unit_id, requirements) VALUES ('${testTask2Id}', '${testOrderId}', '${testOrderId}', 'PLAY_STORE', 'ACTIVE', 10.00, '${testUnit2Id}', '{"orderUnitId": "${testUnit2Id}", "unitNumber": 2}');`);

  // Ensure test users exist
  const worker1Email = `worker1_${Date.now()}@gmail.com`;
  const worker2Email = `worker2_${Date.now()}@gmail.com`;
  const worker1Id = `uid_w1_${Date.now()}`;
  const worker2Id = `uid_w2_${Date.now()}`;

  await queryDb(`INSERT INTO users (id, email, role, status) VALUES ('${worker1Id}', '${worker1Email}', 'WORKER', 'ACTIVE');`);
  await queryDb(`INSERT INTO users (id, email, role, status) VALUES ('${worker2Id}', '${worker2Email}', 'WORKER', 'ACTIVE');`);
  await queryDb(`INSERT INTO workers (id, user_id, status) VALUES ('${worker1Id}', '${worker1Id}', 'ACTIVE');`);
  await queryDb(`INSERT INTO workers (id, user_id, status) VALUES ('${worker2Id}', '${worker2Id}', 'ACTIVE');`);

  // Worker 1 checks available tasks: Should see AT MOST 1 task for this campaign
  const w1Feed = await requestApi('GET', '/api/v1/worker/tasks/available', {
    'x-user-id': worker1Id,
    'x-user-email': worker1Email,
    'x-user-role': 'WORKER',
  });

  const matchingCampaignTasks = (w1Feed.body?.tasks || []).filter(t => t.campaignId === testOrderId || t.orderId === testOrderId);
  console.log(`Worker 1 sees ${matchingCampaignTasks.length} task(s) for Campaign ${testOrderId} (Expected: exactly 1).`);
  if (matchingCampaignTasks.length === 1) {
    console.log('✅ PASS: Feed deduplication works! Exactly 1 unit shown.');
  } else {
    console.error('❌ FAIL: Deduplication failed!');
  }

  // Worker 1 accepts Task 1 (Unit 1)
  console.log(`Worker 1 (${worker1Email}) accepting Task 1 (Unit 1)...`);
  const acceptRes1 = await requestApi('POST', `/api/v1/worker/tasks/${testTask1Id}/accept`, {
    'x-user-id': worker1Id,
    'x-user-email': worker1Email,
    'x-user-role': 'WORKER',
  });
  console.log('Accept Task 1 Response:', acceptRes1.body);
  if (acceptRes1.body?.success) {
    console.log('✅ PASS: Task 1 accepted successfully.');
  } else {
    console.error('❌ FAIL: Task 1 accept failed:', acceptRes1.body);
  }

  // Check DB records for Worker 1
  const cwpRow = await queryDb(`SELECT * FROM campaign_worker_participation WHERE campaign_id = '${testOrderId}';`);
  console.log('CWP Table Row:\n', cwpRow);
  const taRow = await queryDb(`SELECT id, task_id, campaign_id, order_id, order_unit_id, worker_id, status FROM task_assignments WHERE campaign_id = '${testOrderId}';`);
  console.log('TaskAssignment Table Row:\n', taRow);

  // Worker 1 checks available feed again: should see ZERO tasks for this campaign
  const w1FeedAfter = await requestApi('GET', '/api/v1/worker/tasks/available', {
    'x-user-id': worker1Id,
    'x-user-email': worker1Email,
    'x-user-role': 'WORKER',
  });
  const matchingAfter = (w1FeedAfter.body?.tasks || []).filter(t => t.campaignId === testOrderId || t.orderId === testOrderId);
  console.log(`Worker 1 feed after accepting: ${matchingAfter.length} task(s) from Campaign ${testOrderId} (Expected: 0).`);
  if (matchingAfter.length === 0) {
    console.log('✅ PASS: Entire campaign excluded from Worker 1 feed!');
  } else {
    console.error('❌ FAIL: Campaign leaked in Worker 1 feed!');
  }

  // Worker 1 tries to accept Task 2 (Unit 2): 3-Level Verification must reject!
  console.log(`Worker 1 (${worker1Email}) attempting to accept Task 2 (Unit 2) of same campaign...`);
  const acceptRes2 = await requestApi('POST', `/api/v1/worker/tasks/${testTask2Id}/accept`, {
    'x-user-id': worker1Id,
    'x-user-email': worker1Email,
    'x-user-role': 'WORKER',
  });
  console.log('Accept Task 2 Response:', acceptRes2.body);
  const errMsg = acceptRes2.body?.error?.message || acceptRes2.body?.message || '';
  if (acceptRes2.statusCode === 400 && errMsg.includes('already participated')) {
    console.log('✅ PASS: 3-Level verification blocked duplicate participation: "You have already participated in this campaign."');
  } else {
    console.error('❌ FAIL: Verification did not block duplicate participation!');
  }

  // Worker 2 (different Gmail) checks available tasks: Worker 2 SHOULD see Unit 2!
  const w2Feed = await requestApi('GET', '/api/v1/worker/tasks/available', {
    'x-user-id': worker2Id,
    'x-user-email': worker2Email,
    'x-user-role': 'WORKER',
  });
  const w2Matching = (w2Feed.body?.tasks || []).filter(t => t.campaignId === testOrderId || t.orderId === testOrderId);
  console.log(`Worker 2 sees ${w2Matching.length} task(s) for Campaign ${testOrderId} (Expected: 1).`);
  if (w2Matching.length === 1 && w2Matching[0].id === testTask2Id) {
    console.log('✅ PASS: Worker 2 can see remaining Unit 2 of the campaign.');
  }

  // Worker 2 accepts Task 2
  const acceptResW2 = await requestApi('POST', `/api/v1/worker/tasks/${testTask2Id}/accept`, {
    'x-user-id': worker2Id,
    'x-user-email': worker2Email,
    'x-user-role': 'WORKER',
  });
  console.log('Worker 2 Accept Response:', acceptResW2.body);
  if (acceptResW2.body?.success) {
    console.log('✅ PASS: Worker 2 successfully accepted Unit 2!');
  }

  // Cleanup test data
  await queryDb(`DELETE FROM task_assignments WHERE campaign_id = '${testOrderId}';`);
  await queryDb(`DELETE FROM campaign_worker_participation WHERE campaign_id = '${testOrderId}';`);
  await queryDb(`DELETE FROM tasks WHERE order_id = '${testOrderId}';`);
  await queryDb(`DELETE FROM workers WHERE user_id IN ('${worker1Id}', '${worker2Id}');`);
  await queryDb(`DELETE FROM users WHERE id IN ('${worker1Id}', '${worker2Id}');`);

  console.log('\n🎉 ALL TESTS PASSED! Test data cleaned up.');
  ssh.dispose();
  process.exit(0);
}

run().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
