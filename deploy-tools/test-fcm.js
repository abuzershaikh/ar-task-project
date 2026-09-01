const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testPush() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Sending test push notification via VPS backend...');
  const res = await ssh.execCommand(`cd /opt/task-engine && node -e "
    const { FirebaseAdminService } = require('./dist/shared/services/firebase-admin.service.js');
    const fcm = new FirebaseAdminService();
    fcm.onModuleInit();
    fcm.sendTaskBroadcastNotification({
      title: '🎉 Task Alert: ₹2 Available!',
      body: 'New YouTube Video Comment task is ready. Tap to complete!',
      reward: 2,
      serviceCode: 'YOUTUBE_COMMENT'
    }).then(() => {
      console.log('Broadcast dispatched successfully!');
      setTimeout(() => process.exit(0), 2000);
    }).catch(e => { console.error(e); process.exit(1); });
  "`);

  console.log(res.stdout || res.stderr);
  ssh.dispose();
}

testPush().catch(console.error);
