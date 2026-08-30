const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testApproveDirect() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- Simulating approve via curl to get full error response ---');
    // Let's call the approve endpoint with buyer auth or check response
    const tokenRes = await ssh.execCommand(`node -e "
      const jwt = require('jsonwebtoken');
      const token = jwt.sign({ id: 'd0797d56-e7e4-47a2-9051-0d95f4f89e2a', email: 'testbuyer@task.com', role: 'buyer' }, 'your-super-secret-jwt-key-task-engine-2024');
      console.log(token);
    "`, { cwd: '/opt/task-engine' });
    const token = tokenRes.stdout.trim();
    console.log('JWT Token generated:', token.substring(0, 20) + '...');

    const curlRes = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/reviews/1d9f55b7-6b5f-404e-a649-218100523eaa/approve -H "Content-Type: application/json" -H "Authorization: Bearer ${token}" -d '{"notes":"Approved"}'`);
    console.log('\nApprove Response:');
    console.log(curlRes.stdout);

    console.log('\n--- Checking error log tail ---');
    const errTail = await ssh.execCommand('tail -n 30 /root/.pm2/logs/task-engine-api-error-2.log');
    console.log(errTail.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

testApproveDirect();
