const http = require('http');
const https = require('https');

async function testRequest(options, headers = {}) {
  return new Promise((resolve) => {
    const mod = options.protocol === 'https:' ? https : http;
    const req = mod.request({
      ...options,
      headers: {
        ...headers,
      },
    }, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: body.slice(0, 300),
        });
      });
    });

    req.on('error', (err) => {
      resolve({ error: err.message });
    });

    req.end();
  });
}

async function run() {
  console.log('--- 1. Testing OPTIONS /api/v1/buyer/dashboard on port 3000 (direct NestJS) ---');
  const r1 = await testRequest({
    hostname: '65.20.77.112',
    port: 3000,
    path: '/api/v1/buyer/dashboard',
    method: 'OPTIONS',
  }, {
    'Origin': 'http://65.20.77.112:3001',
    'Access-Control-Request-Method': 'GET',
    'Access-Control-Request-Headers': 'authorization,x-user-email,x-user-id,x-user-role,content-type',
  });
  console.log('Result 1 (Port 3000 OPTIONS):', r1);

  console.log('\n--- 2. Testing OPTIONS /api/v1/buyer/dashboard on port 3001 (Nginx proxy) ---');
  const r2 = await testRequest({
    hostname: '65.20.77.112',
    port: 3001,
    path: '/api/v1/buyer/dashboard',
    method: 'OPTIONS',
  }, {
    'Origin': 'http://65.20.77.112:3001',
    'Access-Control-Request-Method': 'GET',
    'Access-Control-Request-Headers': 'authorization,x-user-email,x-user-id,x-user-role,content-type',
  });
  console.log('Result 2 (Port 3001 OPTIONS):', r2);

  console.log('\n--- 3. Testing GET /api/v1/buyer/dashboard on port 3001 (Nginx proxy) with headers ---');
  const r3 = await testRequest({
    hostname: '65.20.77.112',
    port: 3001,
    path: '/api/v1/buyer/dashboard',
    method: 'GET',
  }, {
    'x-user-email': 'testbuyer@reviewsgateway.in',
    'x-user-id': 'buyer-test-uid-123',
    'x-user-role': 'BUYER',
  });
  console.log('Result 3 (Port 3001 GET Dashboard):', r3);

  console.log('\n--- 4. Testing GET /api/v1/buyer/dashboard on https://reviewsgateway.in ---');
  const r4 = await testRequest({
    protocol: 'https:',
    hostname: 'reviewsgateway.in',
    path: '/api/v1/buyer/dashboard',
    method: 'GET',
  }, {
    'x-user-email': 'testbuyer@reviewsgateway.in',
    'x-user-id': 'buyer-test-uid-123',
    'x-user-role': 'BUYER',
  });
  console.log('Result 4 (HTTPS Domain GET Dashboard):', r4);
}

run();
