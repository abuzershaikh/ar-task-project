const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testLiveAiPreview() {
  console.log('--- 1. Registering/Logging in Buyer on VPS ---');
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const email = `deepseek_buyer_${rnd}@test.com`;

  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: email,
      password: 'BuyerSecret@123',
      fullName: `DeepSeek Buyer ${rnd}`,
      role: 'BUYER'
    })
  });
  const regJson = await regRes.json();
  const token = regJson.data?.accessToken;
  console.log('✓ Buyer Auth Token:', token ? 'Obtained successfully' : 'Failed');

  if (!token) {
    console.error('Registration failed:', regJson);
    return;
  }

  console.log('\n--- 2. Requesting AI Sample Comments Preview (5 items) ---');
  const startTime = Date.now();
  const previewRes = await fetch(`${BASE_URL}/buyer/orders/ai-preview-comments`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      topic: 'How to build high-ticket client acquisition funnel',
      language: 'English',
      tone: 'professional',
      count: 25,
      serviceCode: 'YOUTUBE_COMMENT'
    })
  });

  const previewJson = await previewRes.json();
  const elapsed = Date.now() - startTime;
  console.log(`✓ API Response Status: ${previewRes.status} (Elapsed: ${elapsed}ms)`);
  console.log('\nResponse Data:');
  console.log(JSON.stringify(previewJson, null, 2));

  if (previewJson.sampleComments) {
    console.log('\n--- Generated Sample Comments (DeepSeek AI) ---');
    previewJson.sampleComments.forEach((c, idx) => {
      console.log(`[Sample ${idx + 1}] ${c}`);
    });
  }
}

testLiveAiPreview();
