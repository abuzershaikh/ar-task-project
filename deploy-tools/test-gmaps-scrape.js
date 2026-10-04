const https = require('https');
const http = require('http');
const { URL } = require('url');

async function testFetch(inputUrl) {
  const parsed = new URL(inputUrl);
  const client = parsed.protocol === 'https:' ? https : http;

  const res = await new Promise((resolve, reject) => {
    const req = client.get(inputUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
      timeout: 10000,
    }, (r) => {
      let body = '';
      r.on('data', chunk => {
        body += chunk;
        if (body.length > 500000) req.destroy();
      });
      r.on('end', () => resolve({ statusCode: r.statusCode, headers: r.headers, body }));
      r.on('close', () => resolve({ statusCode: r.statusCode, headers: r.headers, body }));
    });
    req.on('error', reject);
  });

  // Look for og: or twitter: or schema.org or meta
  const metas = res.body.match(/<meta[^>]+>/gi) || [];
  console.log('Metas found:');
  metas.forEach(m => {
    if (m.includes('og:') || m.includes('title') || m.includes('image') || m.includes('description')) {
      console.log('  ', m);
    }
  });

  // Check script tags or JSON data
  const matches = res.body.match(/\"Taj Mahal\"/g);
  console.log('Matches for "Taj Mahal":', matches ? matches.length : 0);

  // Check regex for meta content
  const ogTitle = res.body.match(/itemprop=["']name["']\s+content=["'](.*?)["']/i);
  console.log('itemprop name:', ogTitle ? ogTitle[1] : null);
}

testFetch('https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z').catch(console.error);
