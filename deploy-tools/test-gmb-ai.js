const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const payload = JSON.stringify({
    serviceCode: 'GOOGLE_BUSINESS_REVIEW',
    topic: 'delicious food and timely catering',
    appName: 'BABA Caterers',
    businessName: 'BABA Caterers',
    count: 3,
    language: 'English',
    tone: 'natural',
    minWords: 15,
    maxWords: 40,
  });

  const res = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders/ai-preview-comments -H "Content-Type: application/json" -d '${payload}'`);
  console.log('AI preview response:', res.stdout);

  ssh.dispose();
}

main().catch(console.error);
