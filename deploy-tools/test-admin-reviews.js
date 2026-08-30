const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testAdminReviews() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const r = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/admin/reviews/pending');
    console.log('Admin Reviews Response:');
    console.log(r.stdout);
    if (r.stderr) console.error(r.stderr);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

testAdminReviews();
