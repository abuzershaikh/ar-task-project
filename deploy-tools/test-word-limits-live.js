async function testLimits() {
  const tests = [
    {
      name: 'Instagram Comments (minWords: 4, maxWords: 8)',
      payload: {
        serviceCode: 'INSTAGRAM_COMMENT',
        topic: 'Amazing reel edit and transition',
        language: 'Hinglish',
        tone: 'natural',
        count: 5,
        minWords: 4,
        maxWords: 8,
      }
    },
    {
      name: 'YouTube Comments (minWords: 4, maxWords: 8)',
      payload: {
        serviceCode: 'YOUTUBE_COMBO',
        topic: 'Trading chart tutorial part 2',
        language: 'Hinglish',
        tone: 'natural',
        count: 5,
        minWords: 4,
        maxWords: 8,
      }
    },
    {
      name: 'Play Store Review (minWords: 4, maxWords: 8)',
      payload: {
        serviceCode: 'PLAYSTORE_REVIEW',
        appName: 'Cashify Clone',
        topic: 'fast app and instant payout',
        language: 'English',
        tone: 'natural',
        count: 5,
        minWords: 4,
        maxWords: 8,
      }
    }
  ];

  for (const t of tests) {
    console.log(`\n================= TESTING ${t.name} =================`);
    try {
      const resp = await fetch('http://65.20.77.112:3000/api/v1/buyer/orders/ai-preview-comments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(t.payload)
      });
      const data = await resp.json();
      console.log('API Status:', resp.status);
      const comments = data.sampleComments || [];
      console.log(`Received ${comments.length} comments:`);
      for (let i = 0; i < comments.length; i++) {
        const c = comments[i];
        const wordCount = c.split(/\s+/).filter(Boolean).length;
        console.log(`  [${i + 1}] (${wordCount} words): "${c}"`);
        if (wordCount > t.payload.maxWords) {
          console.error(`  ❌ VIOLATION: Exceeds maxWords (${wordCount} > ${t.payload.maxWords})`);
        } else {
          console.log(`  ✅ PASSED: Within ${t.payload.minWords}-${t.payload.maxWords} words`);
        }
      }
    } catch (err) {
      console.error('Error:', err.response?.data || err.message);
    }
  }
}

testLimits();
