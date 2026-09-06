const https = require('https');
const fs = require('fs');
const path = require('path');

const url = 'https://www.reviewsgateway.in/';

https.get(url, { rejectUnauthorized: false }, (res) => {
  let html = '';
  res.on('data', d => html += d);
  res.on('end', () => {
    fs.writeFileSync(path.join(__dirname, 'downloaded_reviewsgateway.html'), html);
    console.log('Saved HTML, length:', html.length);
  });
}).on('error', e => console.error(e));
