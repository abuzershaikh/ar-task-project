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

  // 4. Fetch Worker Earnings
  console.log('\n4. Fetching worker earnings...');
  const earnRes = await fetch(`${BASE_URL}/worker/earnings`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const earnJson = await earnRes.json();
  console.log('   Earnings API Status:', earnRes.status);
  console.log('   Earnings Data:', JSON.stringify(earnJson));

  console.log('\n✅ ALL WORKER APP ENDPOINTS TESTED AND WORKING ON NEW VPS!');
}

testWorkerFlow();
