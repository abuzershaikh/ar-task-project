async function testLive() {
  const BASE_URL = 'http://65.20.77.112:3000/api/v1';

  console.log('--- TEST 1: Play Store Scraper Endpoint ---');
  try {
    const res1 = await fetch(`${BASE_URL}/buyer/orders/playstore-app-info`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        url: 'https://play.google.com/store/apps/details?id=com.reglobe.cashify'
      })
    });
    const data1 = await res1.json();
    console.log('Response Status:', res1.status);
    console.log('Response Data:', JSON.stringify(data1, null, 2));
    if (data1.description || data1.shortDescription) {
      console.error('❌ ERROR: Description is still present in response!');
    } else {
      console.log('✅ PASS: Description is NOT extracted or returned!');
    }
  } catch (err) {
    console.error('Test 1 error:', err.message);
  }

  console.log('\n--- TEST 2: AI Review Preview Generator ---');
  try {
    const res2 = await fetch(`${BASE_URL}/buyer/orders/ai-preview-comments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        serviceCode: 'PLAYSTORE_5STAR_REVIEW',
        appName: 'Cashify',
        topic: 'fast pickup and good price',
        language: 'English',
        tone: 'natural',
        count: 5
      })
    });
    const data2 = await res2.json();
    console.log('Response Status:', res2.status);
    console.log('Sample Reviews:');
    (data2.sampleComments || []).forEach((c, idx) => {
      console.log(`  ${idx + 1}. "${c}"`);
    });

    const hasStars = (data2.sampleComments || []).some(c => /⭐|★|5\s*star/i.test(c));
    if (hasStars) {
      console.error('❌ ERROR: Star or rating detected in reviews!');
    } else {
      console.log('✅ PASS: No stars or ratings found, natural human tone verified!');
    }
  } catch (err) {
    console.error('Test 2 error:', err.message);
  }

  console.log('\n--- TEST 3: AI Review Preview with Empty Prompt (Organic App Praise) ---');
  try {
    const res3 = await fetch(`${BASE_URL}/buyer/orders/ai-preview-comments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        serviceCode: 'PLAYSTORE_5STAR_REVIEW',
        appName: 'Cashify',
        topic: '',
        language: 'Hindi',
        tone: 'natural',
        count: 5
      })
    });
    const data3 = await res3.json();
    console.log('Response Status:', res3.status);
    console.log('Sample Hindi Reviews:');
    (data3.sampleComments || []).forEach((c, idx) => {
      console.log(`  ${idx + 1}. "${c}"`);
    });
  } catch (err) {
    console.error('Test 3 error:', err.message);
  }

  process.exit(0);
}

testLive();
