const https = require('https');
const fs = require('fs');
const path = require('path');

function download(url, dest) {
  return new Promise((resolve, reject) => {
    https.get(url, { rejectUnauthorized: false }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redirectUrl = res.headers.location;
        if (!redirectUrl.startsWith('http')) {
          redirectUrl = new URL(redirectUrl, url).toString();
        }
        return download(redirectUrl, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`Failed ${url}: ${res.statusCode}`));
      }
      const dir = path.dirname(dest);
      fs.mkdirSync(dir, { recursive: true });
      const file = fs.createWriteStream(dest);
      res.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', reject);
  });
}

async function run() {
  const base = 'https://www.reviewsgateway.in';
  const assets = [
    '/assetes/css/style.css',
    '/assetes/js/main.js'
  ];

  for (const a of assets) {
    const target = path.join(__dirname, 'downloaded_site', a);
    try {
      await download(base + a, target);
      console.log('Downloaded:', a);
    } catch (e) {
      console.error('Error downloading', a, e.message);
    }
  }
}

run();
