const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testSubmit() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== TEST SUBMIT FUNCTION DIRECTLY VIA VPS NODE ===');
  const res = await ssh.execCommand(`node -e "
    const { NodeSSH } = require('node-ssh');
    console.log('Testing review assignment logic...');
    const order = { reviewMode: 'BUYER', buyerId: 'buyer123' };
    const mode = (order.reviewMode || '').toString().trim().toLowerCase();
    let reviewerId = null;
    switch (mode) {
      case 'buyer': reviewerId = order.buyerId; break;
      case 'admin': reviewerId = 'admin'; break;
      case 'automatic': case 'auto': case 'system': reviewerId = 'system'; break;
      default: reviewerId = order.buyerId || 'admin'; break;
    }
    console.log('Result reviewerId:', reviewerId);
  "`, { cwd: '/opt/task-engine' });
  console.log(res.stdout);

  ssh.dispose();
}

testSubmit();
