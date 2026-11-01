const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const testUrls = [
    'https://maps.app.goo.gl/9yGZ7L6zXJ4aB1n67',
    'https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z',
    'https://goo.gl/maps/xyz123',
  ];

  for (const url of testUrls) {
    console.log('\n--- Testing URL:', url);
    const res = await ssh.execCommand(
      `curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders/google-business-info -H "Content-Type: application/json" -d '{"url":"${url}"}'`
    );
    console.log('Response:', res.stdout);
  }

  ssh.dispose();
}

run().catch(console.error);
