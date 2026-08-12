const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testEndpoints() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('Testing Endpoints on VPS...');

    // Flush logs first so we see clean error logs if any occur
    await ssh.execCommand('pm2 flush');

    console.log('\n1. Testing Auth Register (BUYER)...');
    const testEmail = `test_${Date.now()}@example.com`;
    const regRes = await ssh.execCommand(`curl -s -X POST -H "Content-Type: application/json" -d '{"email":"${testEmail}","password":"Password123!","fullName":"Test User","role":"BUYER"}' http://localhost:3000/api/v1/auth/register`);
    console.log('Register Response:', regRes.stdout);

    console.log('\n2. Testing Auth Login...');
    const loginRes = await ssh.execCommand(`curl -s -X POST -H "Content-Type: application/json" -d '{"email":"${testEmail}","password":"Password123!"}' http://localhost:3000/api/v1/auth/login`);
    console.log('Login Response:', loginRes.stdout);

    console.log('\n3. Checking PM2 logs after requests...');
    const logs = await ssh.execCommand('pm2 logs task-engine --lines 30 --nostream');
    console.log('PM2 Logs Output:\n', logs.stdout);
    if (logs.stderr) console.log('PM2 Logs Error:\n', logs.stderr);

    ssh.dispose();
}
testEndpoints().catch(err => console.error(err));
