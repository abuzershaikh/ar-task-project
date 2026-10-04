const http = require('http');

http.get('http://65.20.77.112:3000/api/v1/buyer/services', res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Headers:', res.headers);
    console.log('Body:', data.slice(0, 500));
  });
}).on('error', console.error);
