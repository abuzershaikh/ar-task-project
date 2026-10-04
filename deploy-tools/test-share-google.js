const https = require('https');
const http = require('http');
const { URL } = require('url');

function followUrl(inputUrl, maxRedirects = 10) {
  return new Promise((resolve, reject) => {
    let currentUrl = inputUrl;
    let redirects = 0;

    function step(u) {
      console.log(`Step [${redirects}]: ${u}`);
      const parsed = new URL(u);
      const client = parsed.protocol === 'https:' ? https : http;

      const req = client.get(u, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        }
      }, (res) => {
        console.log(`Status: ${res.statusCode}, Location: ${res.headers.location}`);
        
        let body = '';
        res.on('data', chunk => { body += chunk; });
        res.on('end', () => {
          if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
            redirects++;
            if (redirects > maxRedirects) {
              return resolve({ finalUrl: currentUrl, body });
            }
            const nextUrl = new URL(res.headers.location, u).toString();
            return step(nextUrl);
          }
          resolve({ finalUrl: u, statusCode: res.statusCode, headers: res.headers, body });
        });
      });
      req.on('error', reject);
    }

    step(inputUrl);
  });
}

followUrl('https://share.google/rhI6QKATqwd8F3YY0').then(res => {
  console.log('Final URL:', res.finalUrl);
  console.log('Status code:', res.statusCode);
  console.log('Body length:', res.body ? res.body.length : 0);
  console.log('Body snippet:', res.body ? res.body.substring(0, 1000) : '');
  
  // Look for title
  const titleMatch = res.body.match(/<title[^>]*>([^<]+)<\/title>/i);
  console.log('Title Match:', titleMatch ? titleMatch[1] : null);
  
  // Look for og:title
  const ogTitleMatch = res.body.match(/<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i) ||
                       res.body.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']/i);
  console.log('og:title:', ogTitleMatch ? ogTitleMatch[1] : null);

  // Look for place name in URL
  const placeMatch = res.finalUrl.match(/\/maps\/place\/([^\/@?]+)/i);
  console.log('placeMatch:', placeMatch ? placeMatch[1] : null);
}).catch(console.error);
