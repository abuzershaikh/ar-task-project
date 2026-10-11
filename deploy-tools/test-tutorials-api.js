const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const r1 = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/buyer/tutorials');
  console.log('GET /api/v1/buyer/tutorials count:', JSON.parse(r1.stdout).total);

  const rSearch = await ssh.execCommand('curl -s "http://127.0.0.1:3000/api/v1/buyer/tutorials?q=install"');
  console.log('SEARCH "install" (tag match) results:', JSON.parse(rSearch.stdout).tutorials.map(t => t.title));

  const r2 = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/buyer/tutorials/categories');
  console.log('GET /api/v1/buyer/tutorials/categories:\n', r2.stdout);

  const r3 = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/worker/tutorials');
  console.log('GET /api/v1/worker/tutorials:\n', r3.stdout);

  ssh.dispose();
}

main().catch(console.error);
