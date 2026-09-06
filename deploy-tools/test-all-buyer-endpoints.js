const http = require('http');

async function testGet(path, headers = {}) {
  return new Promise((resolve) => {
    const req = http.request({
      hostname: '65.20.77.112',
      port: 3001,
      path: path,
      method: 'GET',
      headers: {
        'x-user-email': 'testbuyer@reviewsgateway.in',
        'x-user-id': 'buyer-test-uid-123',
        'x-user-role': 'BUYER',
        ...headers,
      },
    }, (res) => {
      let body = '';
      res.on('data', (c) => body += c);
      res.on('end', () => {
        resolve({
          path,
          status: res.statusCode,
          body: body.slice(0, 150),
        });
      });
    });
    req.on('error', (e) => resolve({ path, error: e.message }));
    req.end();
  });
}

async function run() {
  const endpoints = [
    '/api/v1/buyer/dashboard',
    '/api/v1/buyer/services',
    '/api/v1/buyer/wallet/balance',
    '/api/v1/buyer/profile',
    '/api/v1/buyer/orders?page=1&limit=20',
    '/api/v1/admin/services',
    '/api/v1/buyer/wallet/transactions?page=1&limit=20',
  ];

  for (const ep of endpoints) {
    const res = await testGet(ep);
    console.log(`${res.status} | ${ep} -> ${res.body}`);
  }
}

run();
