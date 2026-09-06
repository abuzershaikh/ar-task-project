const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const res1 = await ssh.execCommand('dig NS reviewsgateway.in +short');
  console.log('NS RECORDS from VPS:\n', res1.stdout);

  const res2 = await ssh.execCommand('dig A reviewsgateway.in +short');
  console.log('A RECORDS from VPS:\n', res2.stdout);

  const res3 = await ssh.execCommand('dig A www.reviewsgateway.in +short');
  console.log('www A RECORDS from VPS:\n', res3.stdout);

  const res4 = await ssh.execCommand('dig @8.8.8.8 NS reviewsgateway.in +short');
  console.log('Google DNS NS:\n', res4.stdout);

  const res5 = await ssh.execCommand('dig @8.8.8.8 A reviewsgateway.in +short');
  console.log('Google DNS A:\n', res5.stdout);

  const res6 = await ssh.execCommand('dig @ns1.bluehost.in A reviewsgateway.in +short');
  console.log('Bluehost NS1 A record:\n', res6.stdout || res6.stderr);

  ssh.dispose();
  process.exit(0);
}

check().catch(e => { console.error(e); process.exit(1); });
