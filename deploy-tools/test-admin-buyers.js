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
  console.log('/admin/buyers response:', JSON.stringify(buyersJson, null, 2));

  // Call /admin/orders
  const ordersRes = await fetch(`${BASE_URL}/admin/orders?page=1&limit=50`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('/admin/orders status:', ordersRes.status);
  const ordersJson = await ordersRes.json();
  console.log('/admin/orders response:', JSON.stringify(ordersJson, null, 2));
}

testAdminBuyers();
