const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testAdminDashboard() {
  console.log('Testing Admin Dashboard on VPS:', BASE_URL);

  // 1. Admin Login
  const loginRes = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'snapbizux@gmail.com',
      password: '80978097'
    })
  });
  const loginJson = await loginRes.json();
  const token = loginJson.data?.accessToken;
  console.log('Login status:', loginRes.status, 'Token:', token ? 'OK' : 'FAIL');

  if (!token) return;

  // 2. Call /admin/dashboard
  console.log('\n2. Testing GET /admin/dashboard ...');
  try {
    const dRes = await fetch(`${BASE_URL}/admin/dashboard`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log('   Status:', dRes.status);
    const dJson = await dRes.json();
    console.log('   Response:', JSON.stringify(dJson, null, 2));
  } catch (err) {
    console.error('   /admin/dashboard error:', err);
  }

  // 3. Call /admin/dashboard/earnings
  console.log('\n3. Testing GET /admin/dashboard/earnings ...');
  try {
    const eRes = await fetch(`${BASE_URL}/admin/dashboard/earnings`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log('   Status:', eRes.status);
    const eJson = await eRes.json();
    console.log('   Response:', JSON.stringify(eJson, null, 2));
  } catch (err) {
    console.error('   /admin/dashboard/earnings error:', err);
  }
}

testAdminDashboard();
