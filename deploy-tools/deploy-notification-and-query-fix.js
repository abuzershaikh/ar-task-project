const { NodeSSH } = require('node-ssh');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

async function main() {
  console.log('🚀 Connecting to VPS (65.20.77.112)...');
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });
  console.log('✅ Connected.');

  const rootDir = path.resolve(__dirname, '..');
  const filesToUpload = [
    {
      local: path.join(rootDir, 'Task engine', 'task-engine', 'queries', 'task-query.service.ts'),
      remote: '/opt/task-engine/task-engine/queries/task-query.service.ts',
    },
    {
      local: path.join(rootDir, 'Task engine', 'notification-engine', 'notification.service.ts'),
      remote: '/opt/task-engine/notification-engine/notification.service.ts',
    },
    {
      local: path.join(rootDir, 'Task engine', 'notification-engine', 'notification-engine.module.ts'),
      remote: '/opt/task-engine/notification-engine/notification-engine.module.ts',
    },
  ];

  for (const f of filesToUpload) {
    console.log(`📤 Uploading ${f.local} -> ${f.remote}...`);
    await ssh.putFile(f.local, f.remote);
    console.log(`✅ Uploaded ${path.basename(f.remote)}`);
  }

  // Build backend on VPS
  console.log('🔨 Building Task Engine on VPS...');
  const buildRes = await ssh.execCommand('npx nest build', { cwd: '/opt/task-engine' });
  console.log('STDOUT:\n', buildRes.stdout);
  if (buildRes.stderr) console.error('STDERR:\n', buildRes.stderr);

  // Restart PM2
  console.log('🔄 Restarting task-engine-api & task-engine-worker...');
  const restartRes = await ssh.execCommand('pm2 restart task-engine-api task-engine-worker', { cwd: '/opt/task-engine' });
  console.log(restartRes.stdout);

  // Check available tasks for sonathe333@gmail.com
  console.log('🔍 Testing Available Tasks API for sonathe333@gmail.com...');
  const testRes = await ssh.execCommand('curl -s -H "x-user-id: MYDovhuR8zcbLlvazaAG8qdWLXr1" -H "x-user-email: sonathe333@gmail.com" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available');
  try {
    const data = JSON.parse(testRes.stdout);
    const playstoreTasks = (data.tasks || []).filter(t => 
      (t.taskType || '').includes('PLAYSTORE') || 
      (t.taskType || '').includes('APP') ||
      (t.requirements?.targetUrl || '').includes('play.google.com')
    );
    console.log(`Total available tasks for sonathe: ${(data.tasks || []).length}`);
    console.log(`Play Store / App tasks for sonathe: ${playstoreTasks.length}`);
    console.log(playstoreTasks.map(t => ({ id: t.id, taskType: t.taskType, campaignId: t.campaignId, service: t.requirements?.serviceName })));
  } catch (e) {
    console.log('Raw output:', testRes.stdout);
  }

  console.log('🎉 Deployment complete!');
  process.exit(0);
}

main().catch(err => {
  console.error('Fatal:', err);
  process.exit(1);
});
