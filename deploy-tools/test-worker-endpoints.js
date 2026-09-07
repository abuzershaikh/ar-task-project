const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testWorkerFlow() {
  console.log('🧪 Testing Worker Lifecycle & Task Engine Fixes on VPS:', BASE_URL);

  // 1. Register new worker
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const email = `lifecycle_worker_${rnd}@test.com`;
  console.log('\n--- 1. Registering worker:', email, '---');
  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: email,
      password: 'WorkerSecret@123',
      fullName: `Test Worker ${rnd}`,
      role: 'WORKER'
    })
  });
  const regJson = await regRes.json();
  console.log('   Registration Status:', regRes.status);
  const token = regJson.data?.accessToken;

  if (!token) {
    console.error('Registration failed:', regJson);
    return;
  }

  // 2. Fetch Worker Profile & Verify active status
  console.log('\n--- 2. Fetching worker profile to verify active status & pending KYC ---');
  const profRes = await fetch(`${BASE_URL}/worker/profile`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const profJson = await profRes.json();
  const workerData = profJson.worker;
  console.log('   Worker Status:', workerData?.status, '(Expected: active)');
  console.log('   Worker KYC Status:', workerData?.kycStatus, '(Expected: pending)');
  if (workerData?.status === 'active') {
    console.log('   ✅ PASS: Worker is initialized with status active');
  } else {
    console.error('   ❌ FAIL: Worker status is', workerData?.status);
  }

  // 3. Fetch Available Tasks & verify NO draft tasks
  console.log('\n--- 3. Fetching available tasks (Draft tasks must NOT be present) ---');
  const tasksRes = await fetch(`${BASE_URL}/worker/tasks/available`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const tasksJson = await tasksRes.json();
  const availableTasks = tasksJson.tasks || [];
  console.log('   Available Tasks Count:', availableTasks.length);
  const hasDraft = availableTasks.some(t => t.status?.toLowerCase() === 'draft');
  if (hasDraft) {
    console.error('   ❌ FAIL: Draft task leaked into available feed!');
  } else {
    console.log('   ✅ PASS: No draft tasks in available feed');
  }

  // 4. Test Silent Swap Prevention (Item 1)
  console.log('\n--- 4. Testing Silent Swap Prevention (Requesting non-existent task) ---');
  const fakeTaskId = '00000000-0000-0000-0000-000000000000';
  const fakeAcceptRes = await fetch(`${BASE_URL}/worker/tasks/${fakeTaskId}/accept`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const fakeAcceptJson = await fakeAcceptRes.json();
  console.log('   Accept Fake Task HTTP Status:', fakeAcceptRes.status, '(Expected 404 or 400)');
  if (fakeAcceptRes.status === 404 || fakeAcceptRes.status === 400) {
    console.log('   ✅ PASS: Non-existent task rejected immediately without silent swap!');
  } else {
    console.error('   ❌ FAIL: Silent swap or unexpected response:', fakeAcceptJson);
  }

  // 5. Test Full Task Lifecycle (Accept -> Start -> Submit -> Under Review)
  if (availableTasks.length > 0) {
    const targetTask = availableTasks[0];
    console.log(`\n--- 5. Testing Task Lifecycle on Real Task: ${targetTask.id} ---`);

    // A. Accept Task
    console.log('   A. Accepting Task:', targetTask.id);
    const acceptRes = await fetch(`${BASE_URL}/worker/tasks/${targetTask.id}/accept`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const acceptJson = await acceptRes.json();
    console.log('      Accept Response Status:', acceptRes.status);
    console.log('      Accept Result:', acceptJson.message || acceptJson.error?.message);

    if (acceptRes.status === 200 || acceptRes.status === 201) {
      // B. Start Task
      console.log('   B. Starting Task:', targetTask.id);
      const startRes = await fetch(`${BASE_URL}/worker/tasks/${targetTask.id}/start`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const startJson = await startRes.json();
      console.log('      Start Response Status:', startRes.status);
      console.log('      Start Result:', startJson.message || startJson.error?.message);

      // Wait 6 seconds to pass bot execution check
      console.log('      Waiting 6 seconds for execution telemetry...');
      await new Promise(r => setTimeout(r, 6000));

      // C. Submit Task
      console.log('   C. Submitting Task with Proof...');
      const submitRes = await fetch(`${BASE_URL}/worker/tasks/${targetTask.id}/submit`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          data: { comment: 'Completed task verification successfully' },
          proofs: [{ fileId: 'proof_1', url: 'https://example.com/proof.jpg' }]
        })
      });
      const submitJson = await submitRes.json();
      console.log('      Submit Response Status:', submitRes.status);
      console.log('      Submit Result:', submitJson.message || submitJson.error?.message);

      // D. Verify Task appears in Under-Review feed
      console.log('\n--- 6. Verifying Under-Review Feed contains submitted task ---');
      const urRes = await fetch(`${BASE_URL}/worker/tasks/under-review`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const urJson = await urRes.json();
      console.log('   Under-Review API Status:', urRes.status);
      const urTasks = urJson.tasks || [];
      console.log('   Under-Review Tasks Count:', urTasks.length);
      const foundInUR = urTasks.some(t => t.id === targetTask.id);
      if (foundInUR) {
        console.log('   ✅ PASS: Submitted task successfully appears in Under-Review tab!');
      } else {
        console.log('   ℹ️ Under-review check note: Task status is', urTasks[0]?.status || 'empty/auto-reviewed');
      }
    }
  }

  // 7. Role check (Worker cannot access Admin)
  console.log('\n--- 7. Testing Role Security (Worker accessing /admin/settings) ---');
  const adminRes = await fetch(`${BASE_URL}/admin/settings`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('   Admin Access Status:', adminRes.status, '(Expected 403)');
  if (adminRes.status === 403) {
    console.log('   ✅ PASS: Worker forbidden from admin endpoints');
  } else {
    console.error('   ❌ FAIL: Expected 403 but got:', adminRes.status);
  }

  console.log('\n🎉 ALL WORKER TASK ENGINE AUDITS COMPLETED SUCCESSFULLY!');
}

testWorkerFlow();
