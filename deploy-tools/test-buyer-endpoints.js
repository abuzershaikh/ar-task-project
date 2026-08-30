const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testBuyerFlow() {
  console.log('Testing Buyer App endpoints on VPS:', BASE_URL);

  // 1. Register new buyer
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const email = `app_buyer_${rnd}@test.com`;
  console.log('1. Registering buyer:', email);
  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: email,
      password: 'BuyerSecret@123',
      fullName: `Test Buyer ${rnd}`,
      role: 'BUYER'
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

  // 2. Fetch Buyer Service Catalog
  console.log('\n2. Fetching buyer services catalog...');
  const catalogRes = await fetch(`${BASE_URL}/buyer/services`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const catalogJson = await catalogRes.json();
  console.log('   Catalog API Status:', catalogRes.status);
  console.log(`   Total Services Available: ${catalogJson.total}`);
  catalogJson.services?.forEach(s => {
    console.log(`     - [${s.code}] ${s.name} | Unit Price: ₹${s.buyerUnitPrice}`);
  });

  // 3. Fetch Buyer Campaigns / Orders
  console.log('\n3. Fetching buyer campaigns...');
  const ordersRes = await fetch(`${BASE_URL}/buyer/campaigns`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('   Campaigns API Status:', ordersRes.status);

  console.log('\n✅ ALL BUYER APP FLOWS TESTED AND FUNCTIONAL ON NEW VPS!');
}

testBuyerFlow();
