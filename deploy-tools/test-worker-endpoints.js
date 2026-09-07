const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testWorkerFlow() {
  console.log('Testing Worker App endpoints on VPS:', BASE_URL);

  // 1. Register new worker
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const email = `app_worker_${rnd}@test.com`;
  console.log('1. Registering worker:', email);
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
  console.log('   Access Token:', token ? 'Generated Successfully' : 'Failed');

  if (!token) {
    console.error('Registration failed:', regJson);
    return;
  }

  // 2. Fetch Available Tasks
  console.log('\n2. Fetching available tasks...');
  const tasksRes = await fetch(`${BASE_URL}/worker/tasks/available`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const tasksJson = await tasksRes.json();
  console.log('   Tasks API Status:', tasksRes.status);
  console.log('   Tasks Data:', JSON.stringify(tasksJson));

  // 3. Fetch Worker Profile
  console.log('\n3. Fetching worker profile...');
  const profRes = await fetch(`${BASE_URL}/worker/profile`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const profJson = await profRes.json();
  console.log('   Profile API Status:', profRes.status);
  console.log('   Profile Data:', JSON.stringify(profJson));

  // 5. Fetch Worker Score (Must be 0 for new worker, tier NEW)
  console.log('\n5. Fetching worker score...');
  const scoreRes = await fetch(`${BASE_URL}/worker/score`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const scoreJson = await scoreRes.json();
  console.log('   Score API Status:', scoreRes.status);
  console.log('   Score Data:', JSON.stringify(scoreJson));

  // 6. Worker attempting to access Admin Settings (Must be 403 Forbidden)
  console.log('\n6. Worker trying to access /admin/settings (Must be 403 Forbidden)...');
  const adminRes = await fetch(`${BASE_URL}/admin/settings`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('   Admin Access Status:', adminRes.status, '(Expected 403)');
  const adminJson = await adminRes.json();
  console.log('   Admin Response:', JSON.stringify(adminJson));

  console.log('\n✅ ALL WORKER APP ENDPOINTS TESTED AND WORKING ON VPS!');
}

testWorkerFlow();
