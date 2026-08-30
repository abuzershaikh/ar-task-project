const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testBuyerWorkerFlow() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- Testing Clean Worker State ---');
    const cleanTasks = await ssh.execCommand('curl -s -H "x-user-email: snapbizux@gmail.com" -H "x-user-id: 15QuKnQDcwS5NLacLIQ8V8CElnA2" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('Available tasks for worker before any buyer order:', cleanTasks.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

testBuyerWorkerFlow();
