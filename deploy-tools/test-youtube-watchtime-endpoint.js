async function test() {
  const url = 'http://65.20.77.112:3000/api/buyer/orders/youtube-video-info';
  const testVideo = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'; // 3m 32s (212s)

  console.log('Testing Non-Combo (YOUTUBE_LIKE)...');
  try {
    const resLike = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        url: testVideo,
        serviceCode: 'YOUTUBE_LIKE',
      }),
    });
    const dataLike = await resLike.json();
    console.log('Non-Combo Result:');
    console.log('  durationSeconds:', dataLike.durationSeconds);
    console.log('  durationFormatted:', dataLike.durationFormatted);
    console.log('  requiredWatchSeconds:', dataLike.requiredWatchSeconds);
    console.log('  requiredWatchFormatted:', dataLike.requiredWatchFormatted);
    console.log('  isCappedAt2Min:', dataLike.isCappedAt2Min);
    console.log('  maxCapSeconds:', dataLike.maxCapSeconds);
  } catch (err) {
    console.error('Non-Combo Error:', err.message);
  }

  console.log('\nTesting Combo (YOUTUBE_COMBO)...');
  try {
    const resCombo = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        url: testVideo,
        serviceCode: 'YOUTUBE_COMBO',
      }),
    });
    const dataCombo = await resCombo.json();
    console.log('Combo Result:');
    console.log('  durationSeconds:', dataCombo.durationSeconds);
    console.log('  durationFormatted:', dataCombo.durationFormatted);
    console.log('  requiredWatchSeconds:', dataCombo.requiredWatchSeconds);
    console.log('  requiredWatchFormatted:', dataCombo.requiredWatchFormatted);
    console.log('  isCappedAt5Min:', dataCombo.isCappedAt5Min);
    console.log('  maxCapSeconds:', dataCombo.maxCapSeconds);
  } catch (err) {
    console.error('Combo Error:', err.message);
  }
}

test();
