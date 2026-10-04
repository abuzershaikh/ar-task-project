const https = require('https');
const { URL } = require('url');

const target = 'https://www.google.com/search?client=ms-android-oppo-rvo3&hs=Gbkq&sca_esv=7a80360a426ed37a&cs=0&output=search&kgmid=/g/11f2sg9qp5&q=BABA+Caterers&shem=epsd1,ltae,rimspwouoe&shndl=30&source=sh/x/loc/act/m1/2&kgs=2164e109a789ebf0&utm_source=epsd1,ltae,rimspwouoe,sh/x/loc/act/m1/2';

https.get(target, {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; RMX3085) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'en-IN,en;q=0.9',
  }
}, (res) => {
  let body = '';
  res.on('data', chunk => { body += chunk; });
  res.on('end', () => {
    console.log('Mobile length:', body.length);
    // Find all text around "BABA" or "Caterer"
    const idx = body.indexOf('BABA');
    console.log('Index of BABA:', idx);
    if (idx !== -1) {
      console.log('Snippet around BABA:\n', body.substring(Math.max(0, idx - 100), idx + 400));
    }
    // Also look for address or rating or phone
    const addr = body.match(/(\d{6})/); // PIN code
    console.log('PIN code match:', addr ? addr[0] : null);

    // Look for spans or divs with text
    const textSnippets = body.match(/<span[^>]*>([^<]{10,120})<\/span>/g) || [];
    console.log('Sample span texts:');
    textSnippets.slice(0, 15).forEach(s => console.log('  ', s.replace(/<[^>]+>/g, '')));
  });
});
