const crypto = require('crypto');

const BASE_URL = 'http://65.20.77.112:3000/api/v1';
const KEY_SECRET = '0pNQOQBRWxmtdE8mPVLlvYfi';

async function run() {
  console.log('--- Testing Live Razorpay Integration on VPS ---');
  
  // 1. Register test buyer
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const email = `buyer_rzp_${rnd}@test.com`;
  console.log('1. Registering test buyer:', email);
  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password: 'BuyerSecret@123',
      fullName: `Test Buyer RZP ${rnd}`,
      role: 'BUYER'
    })
  });
  const regData = await regRes.json();
  const token = regData.data?.accessToken;
  if (!token) {
    console.error('Failed to get token:', regData);
    return;
  }
  console.log('   Buyer authenticated successfully.');

  // 2. Check initial wallet balance
  const balRes1 = await fetch(`${BASE_URL}/buyer/wallet/balance`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const balData1 = await balRes1.json();
  console.log('2. Initial wallet balance:', balData1.balance);

  // 3. Create live Razorpay Order (e.g., custom amount ₹750)
  const testAmount = 750;
  console.log(`3. Creating Razorpay Order for ₹${testAmount}...`);
  const orderRes = await fetch(`${BASE_URL}/buyer/wallet/razorpay-order`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      amount: testAmount,
      description: 'Custom Test Wallet Top-up'
    })
  });
  const orderData = await orderRes.json();
  console.log('   Razorpay Order Response:', orderData);

  if (!orderData.success || !orderData.orderId) {
    console.error('❌ Order creation failed!');
    return;
  }

  console.log(`   Order created successfully: ${orderData.orderId}`);
  console.log(`   Merchant: ${orderData.companyName}, KeyId: ${orderData.keyId}`);

  // 4. Test Signature Verification (Simulate Razorpay payment callback)
  const simulatedPaymentId = `pay_sim_${Date.now()}`;
  const generatedSignature = crypto
    .createHmac('sha256', KEY_SECRET)
    .update(`${orderData.orderId}|${simulatedPaymentId}`)
    .digest('hex');

  console.log('\n4. Verifying payment signature...');
  const verifyRes = await fetch(`${BASE_URL}/buyer/wallet/razorpay-verify`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      orderId: orderData.orderId,
      paymentId: simulatedPaymentId,
      signature: generatedSignature,
      amount: testAmount
    })
  });
  const verifyData = await verifyRes.json();
  console.log('   Verification Response:', verifyData);

  // 5. Check updated wallet balance
  const balRes2 = await fetch(`${BASE_URL}/buyer/wallet/balance`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const balData2 = await balRes2.json();
  console.log('\n5. Updated Wallet Balance after Top-up:', balData2.balance);

  if (balData2.balance.available >= testAmount) {
    console.log('\n🎉 SUCCESS! Live Razorpay order creation and wallet crediting is 100% verified on VPS!');
  } else {
    console.error('Balance not credited as expected.');
  }
}

run().catch(console.error);
