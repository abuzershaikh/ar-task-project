const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testAvailableTasks() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    
    console.log('--- Test GET /worker/tasks/available for Worker MYDovhuR8zcbLlvazaAG8qdWLXr1 ---');
    const res1 = await ssh.execCommand('curl -s -H "x-user-id: MYDovhuR8zcbLlvazaAG8qdWLXr1" -H "x-user-email: snapbizux@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('Response for MYDovhuR8zcbLlvazaAG8qdWLXr1:\n', res1.stdout);

    console.log('\n--- Test GET /worker/tasks/available without Worker ID (or new worker) ---');
    const res2 = await ssh.execCommand('curl -s -H "x-user-id: new_worker_123" -H "x-user-email: new@worker.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    console.log('Response for new worker:\n', res2.stdout);

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

testAvailableTasks();
