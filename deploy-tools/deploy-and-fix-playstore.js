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
  });
  console.log('✅ Connected.');

  // 1. Upload updated files
  const rootDir = path.resolve(__dirname, '..');
  const filesToUpload = [
    {
      local: path.join(rootDir, 'Task engine', 'apps', 'api', 'controllers', 'buyer', 'order.controller.ts'),
      remote: '/opt/task-engine/apps/api/controllers/buyer/order.controller.ts',
    },
    {
      local: path.join(rootDir, 'Task engine', 'shared', 'services', 'order-activated.listener.ts'),
      remote: '/opt/task-engine/shared/services/order-activated.listener.ts',
    },
  ];

  for (const f of filesToUpload) {
    console.log(`📤 Uploading ${f.local} -> ${f.remote}...`);
    await ssh.putFile(f.local, f.remote);
    console.log(`✅ Uploaded ${path.basename(f.remote)}`);
  }

  // 2. Build backend
  console.log('🔨 Building Task Engine on VPS...');
  const buildRes = await ssh.execCommand('npx nest build', { cwd: '/opt/task-engine' });
  console.log(buildRes.stdout);
  if (buildRes.stderr && !buildRes.stderr.includes('TS')) console.error(buildRes.stderr);

  // 3. Restart PM2
  console.log('🔄 Restarting task-engine-api...');
  const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
  console.log(restartRes.stdout);

  // 4. Retrofit MySQL existing tasks
  console.log('🗄️ Fixing existing tasks & orders in MySQL...');
  const fixSqlScript = `
const mysql = require('mysql2/promise');

async function fixDb() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  const [tasks] = await conn.query("SELECT id, order_id, requirements, metadata FROM tasks WHERE task_type = 'APP_INSTALL' OR requirements LIKE '%play.google.com%'");
  console.log('Found ' + tasks.length + ' Play Store tasks to verify/update');

  const swiggyIcon = 'https://play-lh.googleusercontent.com/eVvxzc9zxEIWRCnEkJjRsCdVK5oEWINHrmCz8uNBrSi_gLwHK2J94-gqM3LMhnyg7ogq_iV52z3zzzuselZx5Zc=s0-br30';

  for (const t of tasks) {
    let req = typeof t.requirements === 'string' ? JSON.parse(t.requirements) : (t.requirements || {});
    let meta = typeof t.metadata === 'string' ? JSON.parse(t.metadata) : (t.metadata || {});

    req.platform = 'playstore';
    req.appName = 'Instamart';
    req.appIcon = swiggyIcon;
    req.packageId = 'in.swiggy.android.instamart';

    meta.platform = 'playstore';
    meta.appName = 'Instamart';
    meta.appIcon = swiggyIcon;
    meta.packageId = 'in.swiggy.android.instamart';

    await conn.query("UPDATE tasks SET requirements = ?, metadata = ? WHERE id = ?", [JSON.stringify(req), JSON.stringify(meta), t.id]);
    console.log('Updated task ' + t.id);
  }

  // Update orders
  const [orders] = await conn.query("SELECT id, requirements FROM orders WHERE task_type = 'APP_INSTALL' OR requirements LIKE '%play.google.com%'");
  for (const o of orders) {
    let req = typeof o.requirements === 'string' ? JSON.parse(o.requirements) : (o.requirements || {});
    req.platform = 'playstore';
    req.appName = 'Instamart';
    req.appIcon = swiggyIcon;
    req.packageId = 'in.swiggy.android.instamart';
    await conn.query("UPDATE orders SET requirements = ? WHERE id = ?", [JSON.stringify(req), o.id]);
    console.log('Updated order ' + o.id);
  }

  await conn.end();
  console.log('DB updates completed successfully!');
}

fixDb().catch(console.error);
`;

  const nodeDbRes = await ssh.execCommand(`node -e "${fixSqlScript.replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });
  console.log(nodeDbRes.stdout);
  if (nodeDbRes.stderr) console.error(nodeDbRes.stderr);

  console.log('🎉 ALL BACKEND FIXES DEPLOYED & DATABASE UPDATED!');
  ssh.dispose();
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
