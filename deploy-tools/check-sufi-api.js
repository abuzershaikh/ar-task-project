const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const res = await ssh.execCommand('curl -s -H "x-user-email: sufieditz@gmail.com" -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
  const json = JSON.parse(res.stdout);
  const list = json.tasks || json.data || json;
  console.log('Total tasks:', list.length);
  list.forEach((t, i) => {
    const type = t.taskType || t.type;
    const order = t.orderId || t.campaignId;
    const req = t.requirements || {};
    const pkg = req.packageId || (t.metadata || {}).packageId;
    const title = req.serviceName || t.title;
    console.log(`[${i+1}] ID: ${t.id} | Type: ${type} | Order: ${order} | Pkg: ${pkg} | Title: ${title}`);
  });

  process.exit(0);
}

run().catch(console.error);
