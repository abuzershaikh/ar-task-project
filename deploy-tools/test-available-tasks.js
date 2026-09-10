const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testAvailableTasks() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    
    console.log('--- Test GET /worker/tasks/available for sonathe333@gmail.com ---');
    const res1 = await ssh.execCommand('curl -s -H "x-user-id: MYDovhuR8zcbLlvazaAG8qdWLXr1" -H "x-user-email: sonathe333@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const data1 = JSON.parse(res1.stdout);
    console.log('Count for sonathe:', (data1.tasks || []).length);
    console.log('Task campaigns for sonathe:', (data1.tasks || []).map(t => ({ id: t.id, campaignId: t.campaignId, orderId: t.orderId })));

    console.log('\n--- Test GET /worker/tasks/available for sufieditz@gmail.com (kQzd3bZD7pgA908xGE6NoGogetB3) ---');
    const res2 = await ssh.execCommand('curl -s -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-email: sufieditz@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
    const data2 = JSON.parse(res2.stdout);
    console.log('Count for sufieditz:', (data2.tasks || []).length);
    console.log('Task campaigns for sufieditz:', (data2.tasks || []).map(t => ({ id: t.id, campaignId: t.campaignId, orderId: t.orderId })));

  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

testAvailableTasks();
