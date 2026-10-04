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
    // Extract the big JSON blob: window.APP_INITIALIZATION_STATE or )]}'\n
    const match = body.match(/\)\]\}\'\s*([\s\S]*?)<\/script>/);
    if (match) {
      console.log('Found blob, length:', match[1].length);
      const textStrings = match[1].match(/"([^"\\]{4,150})"/g) || [];
      console.log('Sample string literals in blob:');
      const unique = [...new Set(textStrings.map(s => s.replace(/^"|"$/g, '')))];
      console.log(unique.filter(s => !s.startsWith('http') && !s.includes('\\') && !s.includes('/')).slice(0, 40));
    }
  });
});
