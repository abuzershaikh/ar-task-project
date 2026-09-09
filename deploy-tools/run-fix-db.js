const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const scriptContent = `
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
  console.log('Found ' + orders.length + ' orders to update');
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
  console.log('SUCCESS: All DB records updated!');
}

fixDb().catch(console.error);
`;

  await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/fix-db.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node fix-db.js', { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error(res.stderr);

  ssh.dispose();
}

main().catch(console.error);
