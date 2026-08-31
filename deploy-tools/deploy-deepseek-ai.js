const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployDeepSeekAI() {
  try {
    console.log('--- Connecting to VPS (65.20.77.112) ---');
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    console.log('✓ Connected');

    const localTaskEngine = path.resolve(__dirname, '..', 'Task engine');

    // 1. Ensure DEEPSEEK_API_KEY is in .env
    console.log('\n--- 1. Updating .env with DEEPSEEK_API_KEY ---');
    const envCheck = await ssh.execCommand('grep -q "DEEPSEEK_API_KEY" /opt/task-engine/.env && echo "FOUND" || echo "NOT_FOUND"');
    const dsKey = process.env.DEEPSEEK_API_KEY || 'SET_YOUR_KEY_HERE';
    if (envCheck.stdout.includes('NOT_FOUND')) {
      await ssh.execCommand(`echo "\nDEEPSEEK_API_KEY=${dsKey}" >> /opt/task-engine/.env`);
      console.log('✓ Added DEEPSEEK_API_KEY to .env');
    } else {
      await ssh.execCommand(`sed -i 's/^DEEPSEEK_API_KEY=.*/DEEPSEEK_API_KEY=${dsKey}/' /opt/task-engine/.env`);
      console.log('✓ Updated DEEPSEEK_API_KEY in .env');
    }

    // 2. Upload updated files
    console.log('\n--- 2. Uploading DeepSeek AI Files to VPS ---');

    await ssh.putFile(
      path.join(localTaskEngine, 'shared', 'ai-generator', 'generators', 'deepseek-comment.generator.ts'),
      '/opt/task-engine/shared/ai-generator/generators/deepseek-comment.generator.ts'
    );
    console.log('✓ Uploaded deepseek-comment.generator.ts');

    await ssh.putFile(
      path.join(localTaskEngine, 'shared', 'ai-generator', 'ai-generator.service.ts'),
      '/opt/task-engine/shared/ai-generator/ai-generator.service.ts'
    );
    console.log('✓ Uploaded ai-generator.service.ts');

    await ssh.putFile(
      path.join(localTaskEngine, 'shared', 'services', 'services.module.ts'),
      '/opt/task-engine/shared/services/services.module.ts'
    );
    console.log('✓ Uploaded services.module.ts');

    await ssh.putFile(
      path.join(localTaskEngine, 'apps', 'api', 'controllers', 'buyer', 'order.controller.ts'),
      '/opt/task-engine/apps/api/controllers/buyer/order.controller.ts'
    );
    console.log('✓ Uploaded order.controller.ts');

    // 3. Compile backend
    console.log('\n--- 3. Compiling Task Engine Backend on VPS ---');
    const buildRes = await ssh.execCommand('npm run build', { cwd: '/opt/task-engine' });
    console.log(buildRes.stdout);
    if (buildRes.stderr && !buildRes.stdout) console.error(buildRes.stderr);

    // 4. Restart PM2
    console.log('\n--- 4. Restarting PM2 process ---');
    const pm2Res = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
    console.log(pm2Res.stdout);

    console.log('\n✅ Deployment complete!');

  } catch (err) {
    console.error('Deployment failed:', err);
  } finally {
    ssh.dispose();
  }
}

deployDeepSeekAI();
