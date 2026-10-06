const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testAdminBuyers() {
  console.log('Testing Admin Buyers endpoint...');
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
  console.log('Login status:', loginRes.status);

  // Call /admin/buyers
  const buyersRes = await fetch(`${BASE_URL}/admin/buyers?page=1&limit=50`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('/admin/buyers status:', buyersRes.status);
  const buyersJson = await buyersRes.json();
  console.log('/admin/buyers count:', buyersJson.buyers?.length);

  // Call /admin/wallet/buyers
  const walletRes = await fetch(`${BASE_URL}/admin/wallet/buyers`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('/admin/wallet/buyers status:', walletRes.status);
  const walletJson = await walletRes.json();
  console.log('/admin/wallet/buyers response:', JSON.stringify(walletJson, null, 2));
}

testAdminBuyers();
