const https = require('https');

https.get('https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z', {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
  }
}, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    const idx = body.indexOf('Taj Mahal');
    console.log('Snippet around Taj Mahal:');
    console.log(body.substring(Math.max(0, idx - 100), Math.min(body.length, idx + 200)));
  });
});
