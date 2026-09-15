const https = require('https');

const keyId = 'rzp_live_TI2wdFKYDJdAxY';
const keySecret = '0pNQOQBRWxmtdE8mPVLlvYfi';
const auth = Buffer.from(`${keyId}:${keySecret}`).toString('base64');

const postData = JSON.stringify({
  amount: 10000, // 100 INR in paise
  currency: 'INR',
  receipt: 'test_rcpt_' + Date.now(),
  notes: {
    test: 'verification'
  }
});

const req = https.request('https://api.razorpay.com/v1/orders', {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${auth}`,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
}, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', body);
  });
});

req.on('error', (err) => {
  console.error('Request Error:', err);
});

req.write(postData);
req.end();
