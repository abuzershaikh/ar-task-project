const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runTest() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    // Check PM2 status
    const pm2 = await ssh.execCommand('pm2 status task-engine-api');
    console.log(pm2.stdout);

    // Call available tasks
    const testRes = await ssh.execCommand('curl -s -v -H "x-user-email: testworker@gmail.com" -H "x-user-id: tw_123" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('STDOUT:', testRes.stdout);
    console.log('STDERR:', testRes.stderr);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

runTest();
