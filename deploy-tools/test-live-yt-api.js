const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testLive() {
  console.log('Testing live YouTube info on VPS API:');
  const testUrls = [
    'https://www.youtube.com/watch?v=sViKU1eitc4',
    'https://youtu.be/frBKNr6uS8E',
    'https://www.youtube.com/watch?v=eZJlxTJolG4'
  ];

  for (const url of testUrls) {
    console.log('\nTesting URL:', url);
    const res = await fetch(`${BASE_URL}/buyer/orders/youtube-video-info`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url })
    });
    const json = await res.json();
    console.log('Response status:', res.status);
    console.log('Video Info:', json);
  }
}

testLive();
