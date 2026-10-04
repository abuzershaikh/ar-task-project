const https = require('https');
const { URL } = require('url');

const searchUrl = 'https://www.google.com/search?client=ms-android-oppo-rvo3&hs=Gbkq&sca_esv=7a80360a426ed37a&cs=0&output=search&kgmid=/g/11f2sg9qp5&q=BABA+Caterers&shem=epsd1,ltae,rimspwouoe&shndl=30&source=sh/x/loc/act/m1/2&kgs=2164e109a789ebf0&utm_source=epsd1,ltae,rimspwouoe,sh/x/loc/act/m1/2';

const parsed = new URL(searchUrl);
console.log('Search query param "q":', parsed.searchParams.get('q'));

https.get(searchUrl, {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
  }
}, (res) => {
  let body = '';
  res.on('data', chunk => { body += chunk; });
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    const matches = body.match(/BABA\s*Caterers/gi);
    console.log('Matches for BABA Caterers:', matches ? matches.length : 0);

    // Look for data-attrid="title"
    const titleAttr = body.match(/data-attrid=["']title["'][^>]*>([^<]+)/i);
    console.log('data-attrid title:', titleAttr ? titleAttr[1] : null);

    // Look for span or h2 with title
    const h2s = body.match(/<h2[^>]*>([^<]+)<\/h2>/gi) || [];
    console.log('H2s:', h2s.slice(0, 5));

    // Look for images
    const imgs = body.match(/https:\/\/[^"']+(?:googleusercontent|gstatic|ggpht)[^"']+/gi) || [];
    console.log('Sample images:', imgs.slice(0, 3));
  });
});
