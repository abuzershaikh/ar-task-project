const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✅ Connected to VPS');

    const pm2Status = await ssh.execCommand('pm2 status');
    console.log('PM2 Status:\n', pm2Status.stdout);

    console.log('\nChecking health endpoint...');
    const health = await ssh.execCommand('curl -s http://localhost:3000/api/v1/health || curl -s http://localhost:3000/health');
    console.log('Health response:', health.stdout);

    console.log('\nChecking buyer reviews endpoints (should require auth / return 401 Unauthorized):');
    const approveAllCheck = await ssh.execCommand('curl -s -X POST http://localhost:3000/api/v1/buyer/reviews/approve-all');
    console.log('POST /buyer/reviews/approve-all:', approveAllCheck.stdout);

    const autoApproveStatusCheck = await ssh.execCommand('curl -s -X GET http://localhost:3000/api/v1/buyer/reviews/auto-approve-status');
    console.log('GET /buyer/reviews/auto-approve-status:', autoApproveStatusCheck.stdout);

    const autoApproveToggleCheck = await ssh.execCommand('curl -s -X POST http://localhost:3000/api/v1/buyer/reviews/auto-approve-toggle');
    console.log('POST /buyer/reviews/auto-approve-toggle:', autoApproveToggleCheck.stdout);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

run();
