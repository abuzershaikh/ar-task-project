const https = require('https');
const fs = require('fs');
const path = require('path');

const url = 'https://www.reviewsgateway.in/account/signin';

https.get(url, { rejectUnauthorized: false }, (res) => {
  let html = '';
  res.on('data', d => html += d);
  res.on('end', () => {
    fs.writeFileSync(path.join(__dirname, 'downloaded_signin.html'), html);
    console.log('Saved signin HTML, length:', html.length);
  });
}).on('error', e => console.error(e));
