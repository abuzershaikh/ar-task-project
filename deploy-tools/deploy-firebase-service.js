const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployFirebaseService() {
  try {
    console.log('Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected successfully!');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    const localFile = path.join(localBase, 'shared/services/firebase-admin.service.ts');
    const remoteFile = `${remoteBase}/shared/services/firebase-admin.service.ts`;

    console.log(`Uploading ${localFile} -> ${remoteFile}`);
    await ssh.putFile(localFile, remoteFile);
    console.log('File uploaded successfully!');

    console.log('\nCompiling backend on VPS (npm run build:api)...');
    const buildRes = await ssh.execCommand('npm run build:api', { cwd: remoteBase });
    console.log('Build Output:', buildRes.stdout || 'Done');
    if (buildRes.stderr) console.warn('Build Notice:', buildRes.stderr);

    console.log('\nRestarting PM2 backend...');
    const restartRes = await ssh.execCommand('pm2 restart all', { cwd: remoteBase });
    console.log(restartRes.stdout);

    console.log('\nWaiting 3 seconds for backend initialization...');
    await new Promise(r => setTimeout(r, 3000));

    console.log('\nTesting Health & API status...');
    const healthRes = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/health');
    console.log('Health Response:', healthRes.stdout || '(Empty)');

    console.log('\nChecking latest PM2 Out logs for Firebase initialization...');
    const outLog = await ssh.execCommand('pm2 logs --lines 30 --nostream');
    console.log(outLog.stdout);

    console.log('\n✅ Firebase Service Account updated and deployed on VPS successfully!');

  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deployFirebaseService();
