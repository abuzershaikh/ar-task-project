const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testKycFlow() {
  console.log('--- Testing KYC & Bank Details Flow ---');
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const email = `bank_test_${rnd}@test.com`;

  // 1. Register
  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password: 'Password123!',
      fullName: 'Rahul Sharma',
      role: 'WORKER'
    })
  });
  const regData = await regRes.json();
  const token = regData.data?.accessToken;
  console.log('1. Worker registered, token:', !!token);

  // 2. Fetch KYC status before submission
  const kycBeforeRes = await fetch(`${BASE_URL}/worker/kyc/status`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const kycBefore = await kycBeforeRes.json();
  console.log('2. KYC Before:', JSON.stringify(kycBefore, null, 2));

  // 3. Submit Bank + UPI + PayPal
  const submitRes = await fetch(`${BASE_URL}/worker/kyc`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      fullName: 'Rahul Sharma',
      bankName: 'HDFC Bank',
      accountNumber: '50100234567890',
      ifscCode: 'HDFC0001234',
      upiId: 'rahul@okhdfcbank',
      paypalId: 'rahul.sharma@paypal.me'
    })
  });
  const submitData = await submitRes.json();
  console.log('3. Submit KYC Status:', submitRes.status, submitData);

  // 4. Fetch KYC status after submission
  const kycAfterRes = await fetch(`${BASE_URL}/worker/kyc/status`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const kycAfter = await kycAfterRes.json();
  console.log('4. KYC After:', JSON.stringify(kycAfter, null, 2));

  // 5. Fetch Profile after submission
  const profRes = await fetch(`${BASE_URL}/worker/profile`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const profData = await profRes.json();
  console.log('5. Profile after KYC:', JSON.stringify(profData, null, 2));
}

testKycFlow().catch(console.error);
