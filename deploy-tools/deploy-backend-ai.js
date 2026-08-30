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

    // Upload changed/new files
    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    const filesToUpload = [
      { local: path.join(localBase, 'shared/ai-generator/generators/generator.interface.ts'), remote: `${remoteBase}/shared/ai-generator/generators/generator.interface.ts` },
      { local: path.join(localBase, 'shared/ai-generator/generators/youtube-comment.generator.ts'), remote: `${remoteBase}/shared/ai-generator/generators/youtube-comment.generator.ts` },
      { local: path.join(localBase, 'shared/ai-generator/ai-generator.service.ts'), remote: `${remoteBase}/shared/ai-generator/ai-generator.service.ts` },
      { local: path.join(localBase, 'shared/database/entities/order-unit.entity.ts'), remote: `${remoteBase}/shared/database/entities/order-unit.entity.ts` },
      { local: path.join(localBase, 'shared/database/repositories/order-unit.repository.ts'), remote: `${remoteBase}/shared/database/repositories/order-unit.repository.ts` },
      { local: path.join(localBase, 'shared/database/database.module.ts'), remote: `${remoteBase}/shared/database/database.module.ts` },
      { local: path.join(localBase, 'shared/services/services.module.ts'), remote: `${remoteBase}/shared/services/services.module.ts` },
      { local: path.join(localBase, 'shared/services/order-activated.listener.ts'), remote: `${remoteBase}/shared/services/order-activated.listener.ts` },
    ];

    await ssh.execCommand(`mkdir -p ${remoteBase}/shared/ai-generator/generators`);

    for (const f of filesToUpload) {
      console.log(`Uploading ${f.local} -> ${f.remote}`);
      await ssh.putFile(f.local, f.remote);
    }

    console.log('\nCompiling backend on VPS...');
    const buildRes = await ssh.execCommand('npm run build:api', { cwd: remoteBase });
    console.log('Build Output:', buildRes.stdout || 'Done');
    if (buildRes.stderr) console.error('Build Stderr:', buildRes.stderr);

    console.log('\nRestarting PM2 process...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout);

    console.log('\nTesting Health & API status...');
    const healthRes = await ssh.execCommand('curl -s http://127.0.0.1:3000/api/v1/health');
    console.log('Health:', healthRes.stdout);

  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deploy();
