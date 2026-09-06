const http = require('http');

function testVpsBackend() {
  const data = JSON.stringify({
    email: 'test@example.com',
    password: 'Password123!'
  });

  const req = http.request({
    host: '65.20.77.112',
    port: 3000,
    path: '/api/v1/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  }, (res) => {
    console.log('VPS Port 3000 Status:', res.statusCode);
    let body = '';
    res.on('data', d => body += d);
    res.on('end', () => console.log('VPS Port 3000 Response:', body));
  });

  req.on('error', e => console.error('VPS Error:', e.message));
  req.write(data);
  req.end();
}

testVpsBackend();
