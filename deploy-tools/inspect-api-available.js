const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  // Get a worker token
  const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
  let token = '';
  try {
    const data = JSON.parse(loginRes.stdout);
    token = data.accessToken || data.token || (data.data && data.data.accessToken);
  } catch(e) {}

  const availableRes = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/worker/tasks/available -H "Authorization: Bearer ${token}"`);
  const data = JSON.parse(availableRes.stdout);
  console.log('Total available tasks:', data.tasks?.length);
  for (const t of (data.tasks || [])) {
    console.log({
      id: t.id,
      orderId: t.orderId,
      taskType: t.taskType,
      targetUrl: t.requirements?.targetUrl,
      appName: t.requirements?.appName,
      appIcon: t.requirements?.appIcon ? t.requirements.appIcon.substring(0, 60) + '...' : null
    });
  }
  ssh.dispose();
}
main().catch(console.error);
