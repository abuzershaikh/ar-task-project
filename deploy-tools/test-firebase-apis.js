const https = require('https');

function testFirebaseConfig(name, apiKey) {
  return new Promise((resolve) => {
    // Ping IdentityToolkit to check if apiKey is valid
    const url = `https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=${apiKey}`;
    const req = https.request(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        resolve({ name, status: res.statusCode, body: data });
      });
    });
    req.on('error', e => resolve({ name, error: e.message }));
    req.write(JSON.stringify({
      providerId: 'google.com',
      continueUri: 'https://reviewsgateway.in'
    }));
    req.end();
  });
}

async function run() {
  console.log('=== Testing Old Config (review-gateway) ===');
  const oldRes = await testFirebaseConfig('review-gateway', 'AIzaSyC1OOU-gFYTdRlLi_oZ-u6yOaNf2gEQGWM');
  console.log(oldRes.name, 'Status:', oldRes.status, '\nBody:', oldRes.body || oldRes.error);

  console.log('\n=== Testing New Config (taskz-87679) ===');
  const newRes = await testFirebaseConfig('taskz-87679', 'AIzaSyAOgf1YfNpqCcryvFfzh3GBJxo0AVh_oKI');
  console.log(newRes.name, 'Status:', newRes.status, '\nBody:', newRes.body || newRes.error);
}

run();
