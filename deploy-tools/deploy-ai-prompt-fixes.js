const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployAiPromptFixes() {
  try {
    console.log('--- Connecting to Mumbai VPS (65.20.77.112) ---');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('✓ Connected successfully');

    const localBase = path.resolve(__dirname, '..', 'Task engine');

    const filesToUpload = [
      {
        local: path.join(localBase, 'shared', 'ai-generator', 'review-sanitizer.ts'),
        remote: '/opt/task-engine/shared/ai-generator/review-sanitizer.ts'
      },
      {
        local: path.join(localBase, 'shared', 'ai-generator', 'generators', 'generator.interface.ts'),
        remote: '/opt/task-engine/shared/ai-generator/generators/generator.interface.ts'
      },
      {
        local: path.join(localBase, 'shared', 'ai-generator', 'generators', 'deepseek-comment.generator.ts'),
        remote: '/opt/task-engine/shared/ai-generator/generators/deepseek-comment.generator.ts'
      },
      {
        local: path.join(localBase, 'shared', 'ai-generator', 'generators', 'youtube-comment.generator.ts'),
        remote: '/opt/task-engine/shared/ai-generator/generators/youtube-comment.generator.ts'
      },
      {
        local: path.join(localBase, 'shared', 'ai-generator', 'generators', 'playstore-review.generator.ts'),
        remote: '/opt/task-engine/shared/ai-generator/generators/playstore-review.generator.ts'
      },
      {
        local: path.join(localBase, 'apps', 'api', 'controllers', 'buyer', 'order.controller.ts'),
        remote: '/opt/task-engine/apps/api/controllers/buyer/order.controller.ts'
      },
      {
        local: path.join(localBase, 'shared', 'services', 'order-activated.listener.ts'),
        remote: '/opt/task-engine/shared/services/order-activated.listener.ts'
      }
    ];

    console.log('\n--- 1. Uploading modified files to VPS ---');
    for (const f of filesToUpload) {
      await ssh.putFile(f.local, f.remote);
      console.log(`✓ Uploaded ${path.basename(f.remote)}`);
    }

    console.log('\n--- 2. Building Task Engine on VPS ---');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) {
      console.error('Build stderr:', buildRes.stderr);
    }

    console.log('\n--- 3. Restarting PM2 backend services ---');
    await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    await ssh.execCommand('pm2 restart task-engine-worker', { cwd: '/opt/task-engine' });
    console.log('✓ PM2 services restarted');

    console.log('\n✅ Deployment complete!');
  } catch (err) {
    console.error('Deployment error:', err);
  } finally {
    ssh.dispose();
  }
}

deployAiPromptFixes();
