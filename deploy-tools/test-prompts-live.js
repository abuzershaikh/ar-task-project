const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testPrompts() {
  const rnd = Math.floor(1000 + Math.random() * 9000);
  const regRes = await fetch(`${BASE_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `test_prompt_${rnd}@test.com`,
      password: 'BuyerSecret@123',
      fullName: `Prompt Tester ${rnd}`,
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
      title: 'YouTube: Ask for Part 2 (Hindi)',
      serviceCode: 'YOUTUBE_COMMENT',
      topic: 'Bhai please part 2 jaldi lao, adha concept samajh aaya aage ka dekhna hai',
      language: 'Hindi',
      tone: 'natural'
    },
    {
      title: 'YouTube: Praise Audio / Mic Clarity (English)',
      serviceCode: 'YOUTUBE_COMMENT',
      topic: 'Praise the audio clarity and clear microphone voiceover',
      language: 'English',
      tone: 'enthusiastic'
    },
    {
      title: 'YouTube: Trading Strategy & Indicators (Hindi)',
      serviceCode: 'YOUTUBE_COMMENT',
      topic: 'Intraday chart analysis and trading indicators bohot sahi hain',
      language: 'Hindi',
      tone: 'natural'
    },
    {
      title: 'Play Store: Fast Payment & Cashout (Hindi)',
      serviceCode: 'APP_REVIEW',
      appName: 'Cashify',
      topic: 'Instant payment and quick money transfer in wallet',
      language: 'Hindi',
      tone: 'natural'
    }
  ];

  for (const tc of testCases) {
    console.log(`\n======================================================`);
    console.log(`TEST: ${tc.title}`);
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
        appName: tc.appName || ''
      })
    });

    const json = await res.json();
    if (json.sampleComments) {
      json.sampleComments.forEach((c, idx) => {
        console.log(`  [${idx + 1}] ${c}`);
      });
    } else {
      console.log('Error / No comments:', json);
    }
  }
}

testPrompts().catch(console.error);
