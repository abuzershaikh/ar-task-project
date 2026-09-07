const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function checkLiveScore() {
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const email = `score_worker_${rnd}@test.com`;
  console.log('Registering test worker:', email);
  
  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password: 'WorkerPass123!',
      fullName: 'Test Worker Score',
      role: 'WORKER'
    })
  });
  const regData = await regRes.json();
  const token = regData.data?.accessToken;
  console.log('Token received:', !!token);

  if (!token) {
    console.error('Registration failed:', regData);
    return;
  }

  // Check /worker/profile
  console.log('\n--- GET /worker/profile ---');
  const profRes = await fetch(`${BASE_URL}/worker/profile`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const profData = await profRes.json();
  console.log(JSON.stringify(profData, null, 2));

  // Check /worker/score
  console.log('\n--- GET /worker/score ---');
  const scoreRes = await fetch(`${BASE_URL}/worker/score`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const scoreData = await scoreRes.json();
  console.log(JSON.stringify(scoreData, null, 2));
}

checkLiveScore().catch(console.error);
