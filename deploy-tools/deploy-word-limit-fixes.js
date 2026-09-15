const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deploy() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to Mumbai VPS!');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    const filesToUpload = [
      { local: path.join(localBase, 'shared/ai-generator/generators/deepseek-comment.generator.ts'), remote: `${remoteBase}/shared/ai-generator/generators/deepseek-comment.generator.ts` },
      { local: path.join(localBase, 'shared/ai-generator/generators/google-business-review.generator.ts'), remote: `${remoteBase}/shared/ai-generator/generators/google-business-review.generator.ts` },
      { local: path.join(localBase, 'shared/ai-generator/generators/youtube-comment.generator.ts'), remote: `${remoteBase}/shared/ai-generator/generators/youtube-comment.generator.ts` },
      { local: path.join(localBase, 'shared/ai-generator/generators/playstore-review.generator.ts'), remote: `${remoteBase}/shared/ai-generator/generators/playstore-review.generator.ts` },
      { local: path.join(localBase, 'apps/api/controllers/buyer/order.controller.ts'), remote: `${remoteBase}/apps/api/controllers/buyer/order.controller.ts` },
      { local: path.join(localBase, 'shared/services/order-activated.listener.ts'), remote: `${remoteBase}/shared/services/order-activated.listener.ts` },
    ];

    for (const f of filesToUpload) {
      console.log(`Uploading ${f.local} -> ${f.remote}`);
      await ssh.putFile(f.local, f.remote);
    }

    console.log('\nCompiling backend on VPS...');
    const buildRes = await ssh.execCommand('npm run build:api', { cwd: remoteBase });
    console.log('Build Output:', buildRes.stdout || 'Done');
    if (buildRes.stderr) console.error('Build Stderr:', buildRes.stderr);

    console.log('\nRestarting PM2 processes...');
    const restartRes = await ssh.execCommand('pm2 restart all', { cwd: remoteBase });
    console.log(restartRes.stdout);

    console.log('\nTesting Health...');
    const healthRes = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/health');
    console.log('Health:', healthRes.stdout);

  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deploy();
