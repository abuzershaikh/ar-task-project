const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Connected to VPS. Uploading Tutorial Engine files...');

  const baseLocal = path.resolve(__dirname, '..', 'Task engine');

  // Ensure remote directories exist
  await ssh.execCommand('mkdir -p /opt/task-engine/tutorial-engine/services');
  await ssh.execCommand('mkdir -p /opt/task-engine/apps/api/controllers/admin');
  await ssh.execCommand('mkdir -p /opt/task-engine/apps/api/controllers/buyer');
  await ssh.execCommand('mkdir -p /opt/task-engine/apps/api/controllers/worker');

  const filesToUpload = [
    {
      local: path.join(baseLocal, 'shared/database/entities/tutorial.entity.ts'),
      remote: '/opt/task-engine/shared/database/entities/tutorial.entity.ts'
    },
    {
      local: path.join(baseLocal, 'shared/database/repositories/tutorial.repository.ts'),
      remote: '/opt/task-engine/shared/database/repositories/tutorial.repository.ts'
    },
    {
      local: path.join(baseLocal, 'shared/database/database.module.ts'),
      remote: '/opt/task-engine/shared/database/database.module.ts'
    },
    {
      local: path.join(baseLocal, 'tutorial-engine/services/tutorial.service.ts'),
      remote: '/opt/task-engine/tutorial-engine/services/tutorial.service.ts'
    },
    {
      local: path.join(baseLocal, 'tutorial-engine/tutorial-engine.module.ts'),
      remote: '/opt/task-engine/tutorial-engine/tutorial-engine.module.ts'
    },
    {
      local: path.join(baseLocal, 'apps/api/controllers/admin/tutorial-admin.controller.ts'),
      remote: '/opt/task-engine/apps/api/controllers/admin/tutorial-admin.controller.ts'
    },
    {
      local: path.join(baseLocal, 'apps/api/controllers/buyer/tutorial-buyer.controller.ts'),
      remote: '/opt/task-engine/apps/api/controllers/buyer/tutorial-buyer.controller.ts'
    },
    {
      local: path.join(baseLocal, 'apps/api/controllers/worker/tutorial-worker.controller.ts'),
      remote: '/opt/task-engine/apps/api/controllers/worker/tutorial-worker.controller.ts'
    },
    {
      local: path.join(baseLocal, 'apps/api/app.module.ts'),
      remote: '/opt/task-engine/apps/api/app.module.ts'
    },
  ];

  for (const f of filesToUpload) {
    console.log(`Uploading ${path.basename(f.local)} -> ${f.remote}`);
    await ssh.putFile(f.local, f.remote);
  }

  console.log('Building NestJS on VPS...');
  const buildRes = await ssh.execCommand('cd /opt/task-engine && npx nest build');
  console.log('VPS build result:\n', buildRes.stdout, buildRes.stderr);

  console.log('Restarting PM2 processes...');
  const pm2Res = await ssh.execCommand('pm2 restart task-engine-api');
  console.log('PM2 restart output:\n', pm2Res.stdout);

  // Test API endpoint directly on VPS
  console.log('Testing GET /api/v1/buyer/tutorials on VPS...');
  const curlRes = await ssh.execCommand('curl -s http://localhost:3000/api/v1/buyer/tutorials');
  console.log('Buyer tutorials response:\n', curlRes.stdout);

  console.log('Testing GET /api/v1/buyer/tutorials/categories on VPS...');
  const catRes = await ssh.execCommand('curl -s http://localhost:3000/api/v1/buyer/tutorials/categories');
  console.log('Categories response:\n', catRes.stdout);

  ssh.dispose();
  console.log('Deployment complete!');
}

run().catch(console.error);
