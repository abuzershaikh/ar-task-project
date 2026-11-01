const https = require('https');
const http = require('http');

const url = 'https://maps.app.goo.gl/8TsYLjAEEEpUYspq7?g_st=ac';

function check(u, count = 0) {
  if (count > 6) return;
  console.log('Step ' + count + ': ' + u);
  const mod = u.startsWith('http:') ? http : https;
  const req = mod.get(u, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
  }, (res) => {
    console.log('Status: ' + res.statusCode + ' Location: ' + res.headers.location);
    if (res.headers.location) {
      check(res.headers.location, count + 1);
    } else {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const titleMatch = data.match(/<title>([^<]+)<\/title>/i);
        console.log('Body length: ' + data.length + ' Title: ' + (titleMatch ? titleMatch[1] : 'none'));
        const metaTitle = data.match(/meta\s+property="og:title"\s+content="([^"]+)"/i) || data.match(/meta\s+content="([^"]+)"\s+property="og:title"/i);
        console.log('OG:Title: ' + (metaTitle ? metaTitle[1] : 'none'));
      });
    }
  });
  req.on('error', err => console.error('Error: ' + err.message));
}

check(url);
