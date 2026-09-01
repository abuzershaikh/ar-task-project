const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== 1. RECENT PM2 LOGS ===');
  const logs = await ssh.execCommand('pm2 logs task-engine-api --lines 40 --nostream');
  console.log(logs.stdout || logs.stderr);

  console.log('\n=== 2. WORKERS IN MYSQL DATABASE ===');
  const workers = await ssh.execCommand("mysql -u taskuser -p'TaskSecureRoot2026!' task_platform -e \"SELECT id, email, role, status, metadata FROM users WHERE role='WORKER';\"");
  console.log(workers.stdout);

  console.log('\n=== 3. NOTIFICATIONS IN MYSQL DATABASE ===');
  const notifs = await ssh.execCommand("mysql -u taskuser -p'TaskSecureRoot2026!' task_platform -e \"SELECT id, user_id, type, title, created_at FROM notifications ORDER BY created_at DESC LIMIT 10;\"");
  console.log(notifs.stdout);

  console.log('\n=== 4. FIRESTORE WORKERS AND NOTIFICATIONS ===');
  const firestoreCheck = await ssh.execCommand(`cd /opt/task-engine && node -e "
    const admin = require('firebase-admin');
    const serviceAccount = require('./dist/shared/services/firebase-admin.service.js');
    const { FirebaseAdminService } = serviceAccount;
    const fcm = new FirebaseAdminService();
    fcm.onModuleInit();
    async function checkFs() {
      const usersSnap = await fcm.firestore.collection('users').get();
      console.log('Firestore Total Users:', usersSnap.size);
      usersSnap.forEach(d => {
        const u = d.data();
        console.log(' - User ID:', d.id, '| Role:', u.role, '| Email:', u.email, '| FCM Token:', u.fcmToken ? (u.fcmToken.substring(0, 15) + '...') : 'NONE');
      });
      const notifSnap = await fcm.firestore.collection('notifications').orderBy('createdAt', 'desc').limit(5).get();
      console.log('\\nFirestore Notifications Count:', notifSnap.size);
      notifSnap.forEach(n => {
        const nd = n.data();
        console.log(' - Notification:', nd.title, '| Target:', nd.target, '| Type:', nd.type);
      });
      process.exit(0);
    }
    checkFs().catch(e => { console.error(e); process.exit(1); });
  "`);
  console.log(firestoreCheck.stdout || firestoreCheck.stderr);

  ssh.dispose();
}

inspect().catch(console.error);
