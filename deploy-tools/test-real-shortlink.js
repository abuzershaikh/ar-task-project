const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  // Real active Google maps shortlink
  const url = 'https://maps.app.goo.gl/fF1o5aRfxr68c9pL8'; // e.g. a random real shop
  const res = await ssh.execCommand(
    `curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders/google-business-info -H "Content-Type: application/json" -d '{"url":"https://maps.app.goo.gl/fF1o5aRfxr68c9pL8"}'`
  );
  console.log('REAL SHORTLINK RESPONSE:\n', res.stdout);

  ssh.dispose();
}

run().catch(console.error);
