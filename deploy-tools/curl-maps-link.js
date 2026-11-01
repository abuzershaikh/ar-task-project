const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  
  const res = await ssh.execCommand(
    `curl -sIL "https://maps.app.goo.gl/fF1o5aRfxr68c9pL8" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"`
  );
  console.log('CURL HEADERS:\n', res.stdout);

  const resBody = await ssh.execCommand(
    `curl -sL "https://maps.app.goo.gl/fF1o5aRfxr68c9pL8" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" | head -n 30`
  );
  console.log('CURL BODY:\n', resBody.stdout);

  ssh.dispose();
}

run().catch(console.error);
