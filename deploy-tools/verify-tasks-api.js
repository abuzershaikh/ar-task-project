const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

  // 1. PM2 error logs
  console.log('--- PM2 Errors ---');
  const errLog = await ssh.execCommand('tail -n 25 /root/.pm2/logs/task-engine-api-error-4.log');
  console.log(errLog.stdout || '(no errors)');

  // 2. Test Available Tasks for sonathe333@gmail.com
  console.log('\n--- Available Tasks for sonathe333@gmail.com ---');
  const res1 = await ssh.execCommand('curl -s -H "x-user-id: MYDovhuR8zcbLlvazaAG8qdWLXr1" -H "x-user-email: sonathe333@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
  try {
    const data = JSON.parse(res1.stdout);
    const tasks = data.tasks || [];
    console.log(`Total available tasks: ${tasks.length}`);
    const playstore = tasks.filter(t => 
      (t.taskType || '').includes('PLAYSTORE') || 
      (t.taskType || '').includes('APP') ||
      (t.requirements?.targetUrl || '').includes('play.google.com')
    );
    console.log(`Playstore tasks count: ${playstore.length}`);
    for (const t of playstore) {
      console.log(` - ID: ${t.id} | Type: ${t.taskType} | Campaign: ${t.campaignId} | App: ${t.requirements?.appName || t.metadata?.appName || t.requirements?.packageId}`);
    }
  } catch (e) {
    console.log('Error parsing response:', e.message, '\nRaw:', res1.stdout);
  }

  process.exit(0);
}

run().catch(console.error);
