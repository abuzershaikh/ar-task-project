const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testStatusToggle() {
  console.log('Testing Status Toggle API on VPS...');
  const loginRes = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'snapbizux@gmail.com', password: '80978097' })
  });
  const { data } = await loginRes.json();
  const token = data.accessToken;

  // 1. Get first worker
  const wRes = await fetch(`${BASE_URL}/admin/workers`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const wData = await wRes.json();
  const worker = wData.workers[0];
  console.log(`Testing with worker: ${worker.name} (id: ${worker.id}, status: ${worker.status})`);

  // 2. Set status to INACTIVE
  console.log('Setting status to INACTIVE...');
  const upRes = await fetch(`${BASE_URL}/admin/workers/${worker.id}/status`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({ status: 'INACTIVE' })
  });
  console.log('Update response:', await upRes.json());

  // 3. Verify in dashboard
  const dRes1 = await fetch(`${BASE_URL}/admin/dashboard`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const dJson1 = await dRes1.json();
  console.log('Dashboard after setting INACTIVE:');
  console.log(dJson1.dashboard.users);

  // 4. Restore status to ACTIVE
  console.log('Restoring status back to ACTIVE...');
  await fetch(`${BASE_URL}/admin/workers/${worker.id}/status`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({ status: 'ACTIVE' })
  });

  // 5. Verify restored in dashboard
  const dRes2 = await fetch(`${BASE_URL}/admin/dashboard`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const dJson2 = await dRes2.json();
  console.log('Dashboard after restoring ACTIVE:');
  console.log(dJson2.dashboard.users);
}

testStatusToggle();
