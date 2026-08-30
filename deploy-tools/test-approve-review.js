const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testApproveReview() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- Calling POST /api/v1/admin/reviews/39d7b123-0cf4-4f67-81a1-9a2e145c6311/approve ---');
    const res = await ssh.execCommand('curl -s -X POST http://127.0.0.1:3000/api/v1/admin/reviews/39d7b123-0cf4-4f67-81a1-9a2e145c6311/approve');
    console.log('Approve response:');
    console.log(res.stdout);

    console.log('\n--- Checking pending reviews ---');
    const pendingRes = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/admin/reviews/pending');
    console.log(pendingRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

testApproveReview();
