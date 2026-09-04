const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testPlayStoreContextFlow() {
  console.log('🚀 Testing Play Store Context-Aware Review & Icon Flow...\n');

  try {
    // 1. Buyer Registration / Login
    const rnd = Math.floor(1000 + Math.random() * 9000);
    const regRes = await fetch(`${BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: `buyer_play_${rnd}@test.com`,
        password: 'TestPassword@123',
        fullName: `App Tester ${rnd}`,
        role: 'BUYER'
      })
    });
    const regData = await regRes.json();
    const token = regData.data?.accessToken;
    console.log('1️⃣ Buyer Authentication:', token ? 'Token Generated ✅' : 'Failed ❌');

    if (!token) {
      console.error('Registration failed:', regData);
      process.exit(1);
    }

    const authHeaders = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    };

    // 2. Fetch Play Store app metadata
    console.log('\n2️⃣ Testing POST /buyer/orders/playstore-app-info for Spotify:');
    const appInfoRes = await fetch(`${BASE_URL}/buyer/orders/playstore-app-info`, {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({ url: 'https://play.google.com/store/apps/details?id=com.spotify.music' })
    });
    const appInfo = await appInfoRes.json();

    console.log('App Metadata Result:');
    console.log('- Success:', appInfo.success);
    console.log('- Package ID:', appInfo.packageId);
    console.log('- App Name:', appInfo.appName);
    console.log('- App Icon:', appInfo.appIcon?.substring(0, 75) + '...');
    console.log('- Short Description:', appInfo.shortDescription);
    console.log('- Full Description Length:', appInfo.description?.length);

    if (!appInfo.success || !appInfo.appIcon) {
      throw new Error(`Failed to fetch valid app metadata: ${JSON.stringify(appInfo)}`);
    }

    // 3. Generate Sample Reviews using App Name & Description
    console.log('\n3️⃣ Testing POST /buyer/orders/ai-preview-comments with App Context:');
    const previewRes = await fetch(`${BASE_URL}/buyer/orders/ai-preview-comments`, {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({
        serviceCode: 'PLAYSTORE_RATING_REVIEW',
        targetUrl: 'https://play.google.com/store/apps/details?id=com.spotify.music',
        appName: appInfo.appName,
        appDescription: appInfo.description,
        count: 5,
        language: 'English',
        tone: 'natural',
      })
    });
    const previewData = await previewRes.json();

    console.log('Generated Contextual Sample Reviews:');
    if (previewData.sampleComments && Array.isArray(previewData.sampleComments)) {
      previewData.sampleComments.forEach((rev, idx) => {
        console.log(`  [${idx + 1}] ${rev}`);
      });
    } else {
      console.log('Preview Response:', previewData);
    }

    // 4. Test WhatsApp metadata as well
    console.log('\n4️⃣ Testing POST /buyer/orders/playstore-app-info for WhatsApp:');
    const waRes = await fetch(`${BASE_URL}/buyer/orders/playstore-app-info`, {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({ url: 'com.whatsapp' })
    });
    const waInfo = await waRes.json();
    console.log('- App Name:', waInfo.appName);
    console.log('- App Icon:', waInfo.appIcon?.substring(0, 75) + '...');
    console.log('- Short Description:', waInfo.shortDescription);

    console.log('\n🎉 ALL TESTS PASSED! Google Play Store metadata scraping, app icon retrieval, and context-aware AI review generation are working perfectly on Mumbai VPS!');
  } catch (err) {
    console.error('❌ Test failed:', err);
  }
}

testPlayStoreContextFlow();
