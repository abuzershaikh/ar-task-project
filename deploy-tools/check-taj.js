const https = require('https');

https.get('https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z', {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
  }
}, (res) => {
  let body = '';
  res.on('data', chunk => { body += chunk; });
  res.on('end', () => {
    // Check all matches of ["Taj Mahal", ...]
    const idx = body.indexOf('Taj Mahal');
    console.log('Index of Taj Mahal:', idx);
    console.log(body.substring(idx - 100, idx + 400));
  });
});
