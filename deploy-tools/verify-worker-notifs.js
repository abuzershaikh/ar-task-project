const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  const resUnread = await ssh.execCommand('curl -s -H "x-user-id: kQzd3bZD7pgA908xGE6NoGogetB3" -H "x-user-email: sufieditz@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/notifications/unread-count');
  console.log('Unread count response:', resUnread.stdout);

  process.exit(0);
}

run().catch(console.error);
