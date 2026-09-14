const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function test() {
  const reg = await fetch(BASE_URL + '/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'gmb_real_' + Date.now() + '@test.com', password: 'Password@123', fullName: 'Tester', role: 'BUYER' })
  });
  const token = (await reg.json()).data?.accessToken;
  
  console.log('--- TEST 1: Short Word Range (10-20 words) for A2m Infotech (English) ---');
  const res1 = await fetch(BASE_URL + '/buyer/orders/ai-preview-comments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    body: JSON.stringify({
      appName: 'A2m Infotech',
      businessName: 'A2m Infotech',
      serviceCode: 'GOOGLE_BUSINESS_REVIEW',
      language: 'English',
      minWords: 10,
      maxWords: 20
    })
  });
  const data1 = await res1.json();
  data1.sampleComments.forEach((c, i) => {
    const w = c.split(/\s+/).length;
    console.log(`[${i+1}] (${w} words): ${c}`);
  });

  console.log('\n--- TEST 2: Medium/Balanced Range (25-45 words) for A2m Infotech (English) ---');
  const res2 = await fetch(BASE_URL + '/buyer/orders/ai-preview-comments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    body: JSON.stringify({
      appName: 'A2m Infotech',
      businessName: 'A2m Infotech',
      serviceCode: 'GOOGLE_BUSINESS_REVIEW',
      language: 'English',
      minWords: 25,
      maxWords: 45
    })
  });
  const data2 = await res2.json();
  data2.sampleComments.forEach((c, i) => {
    const w = c.split(/\s+/).length;
    console.log(`[${i+1}] (${w} words): ${c}`);
  });

  console.log('\n--- TEST 3: Hinglish Reviews for A2m Infotech (20-40 words) ---');
  const res3 = await fetch(BASE_URL + '/buyer/orders/ai-preview-comments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    body: JSON.stringify({
      appName: 'A2m Infotech',
      businessName: 'A2m Infotech',
      serviceCode: 'GOOGLE_BUSINESS_REVIEW',
      language: 'Hinglish',
      minWords: 20,
      maxWords: 40
    })
  });
  const data3 = await res3.json();
  data3.sampleComments.forEach((c, i) => {
    const w = c.split(/\s+/).length;
    console.log(`[${i+1}] (${w} words): ${c}`);
  });
}

test();
