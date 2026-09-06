const https = require('https');

function fetch(url) {
  return new Promise((resolve) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: data }));
    }).on('error', err => resolve({ error: err.message }));
  });
}

async function test() {
  const r1 = await fetch('https://www.reviewsgateway.in/account/signin/index.html');
  console.log('--- /account/signin/index.html ---');
  console.log('Status:', r1.status);
  console.log(r1.body?.substring(0, 500));

  const r2 = await fetch('https://www.reviewsgateway.in/account/signin/version.json');
  console.log('--- /account/signin/version.json ---');
  console.log('Status:', r2.status);
  console.log(r2.body);
}

test();
