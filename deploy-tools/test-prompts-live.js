const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testPrompts() {
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `test_title_${rnd}@test.com`,
      password: 'BuyerSecret@123',
      fullName: `Title Tester ${rnd}`,
      role: 'BUYER'
    })
  });
  const regJson = await regRes.json();
  const token = regJson.data?.accessToken;
  if (!token) {
    console.error('Failed to get auth token:', regJson);
    return;
  }

  const testCases = [
    {
      title: 'YouTube: Biryani Recipe with Video Title (Hindi)',
      serviceCode: 'YOUTUBE_COMMENT',
      videoTitle: 'Hyderabadi Chicken Dum Biryani Authentic Restaurant Recipe',
      topic: 'Masala ratio aur taste bohot accha hai',
      language: 'Hindi',
      tone: 'natural'
    },
    {
      title: 'YouTube: Python Coding Tutorial with Video Title (English)',
      serviceCode: 'YOUTUBE_COMMENT',
      videoTitle: 'Master Python Programming in 30 Days - Full Beginner Course',
      topic: 'Real world examples and clear code breakdown',
      language: 'English',
      tone: 'natural'
    },
    {
      title: 'YouTube: iPhone 16 Camera Test with Part 2 Request (Hindi)',
      serviceCode: 'YOUTUBE_COMMENT',
      videoTitle: 'iPhone 16 Pro Max Full Real-World Camera Review',
      topic: 'Bhai part 2 jaldi lana low light testing ka',
      language: 'Hindi',
      tone: 'enthusiastic'
    }
  ];

  for (const tc of testCases) {
    console.log(`\n======================================================`);
    console.log(`TEST: ${tc.title}`);
    console.log(`VIDEO TITLE: "${tc.videoTitle}"`);
    console.log(`INPUT PROMPT: "${tc.topic}"`);
    console.log(`======================================================`);

    const res = await fetch(`${BASE_URL}/buyer/orders/ai-preview-comments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        topic: tc.topic,
        prompt: tc.topic,
        language: tc.language,
        tone: tc.tone,
        count: 5,
        serviceCode: tc.serviceCode,
        videoTitle: tc.videoTitle,
        appName: tc.appName || tc.videoTitle
      })
    });

    const data = await res.json();
    console.log('API STATUS:', res.status);
    console.log('GENERATED COMMENTS:');
    (data.sampleComments || []).forEach((c, i) => {
      console.log(`  [${i + 1}] "${c}"`);
    });
  }
}

testPrompts().catch(console.error);
