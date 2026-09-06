const https = require('https');
const fs = require('fs');
const path = require('path');

const pages = [
  '/',
  '/index.html',
  '/account/signin/',
  '/account/signup/',
  '/services/',
  '/services/google-reviews-growth/',
  '/services/app-install-reviews/',
  '/services/complete-app-growth/',
  '/faq/',
  '/contact/',
  '/legal/privacy-policy/',
  '/legal/terms-of-conditions/',
  '/legal/refund-policy/',
  '/components/header.html',
  '/components/footer.html',
  '/components/cookie-banner.html',
  '/assetes/css/style.css',
  '/assetes/js/main.js',
  '/assetes/js/cookie-banner.js',
  '/assetes/js/firebase-init.js',
  '/assetes/js/firebase-auth.js'
];

const baseDir = path.join(__dirname, 'downloaded_site');

function fetchUrl(urlPath) {
  return new Promise((resolve) => {
    const fullUrl = 'https://www.reviewsgateway.in' + urlPath;
    https.get(fullUrl, { rejectUnauthorized: false }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let loc = res.headers.location;
        if (loc.startsWith('/')) loc = 'https://www.reviewsgateway.in' + loc;
        https.get(loc, { rejectUnauthorized: false }, (r2) => {
          let data = '';
          r2.on('data', chunk => data += chunk);
          r2.on('end', () => resolve({ path: urlPath, status: r2.statusCode, data }));
        }).on('error', () => resolve({ path: urlPath, status: 500 }));
        return;
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ path: urlPath, status: res.statusCode, data }));
    }).on('error', () => resolve({ path: urlPath, status: 500 }));
  });
}

async function run() {
  for (const p of pages) {
    const res = await fetchUrl(p);
    console.log(`[${res.status}] ${p} (length: ${res.data ? res.data.length : 0})`);
    if (res.status === 200 && res.data) {
      let filePath = p;
      if (filePath.endsWith('/')) filePath += 'index.html';
      const dest = path.join(baseDir, filePath);
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.writeFileSync(dest, res.data);
    }
  }
}

run();
