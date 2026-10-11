const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const nodeScript = `
const mysql = require('/opt/task-engine/node_modules/mysql2/promise');

async function main() {
  const conn = await mysql.createConnection({
    host: '127.0.0.1',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  const [tasks] = await conn.query("SELECT id, requirements, metadata FROM tasks WHERE order_id='dd75d9c6-2a6f-47b1-a53a-45dd9aa36229'");
  console.log('Found tasks:', tasks.length);

  for (const t of tasks) {
    let req = typeof t.requirements === 'string' ? JSON.parse(t.requirements) : (t.requirements || {});
    let meta = typeof t.metadata === 'string' ? JSON.parse(t.metadata) : (t.metadata || {});

    delete req.appName;
    delete meta.appName;

    if (req.videoTitle) {
      req.videoTitle = req.videoTitle.replace(/App Installs/gi, 'Installs').replace(/app install/gi, 'installs');
    }
    if (Array.isArray(req.sampleComments)) {
      req.sampleComments = req.sampleComments.map(c => c.replace(/App Installs/gi, 'Installs').replace(/app install/gi, 'installs'));
    }

    await conn.query("UPDATE tasks SET requirements=?, metadata=? WHERE id=?", [
      JSON.stringify(req),
      JSON.stringify(meta),
      t.id
    ]);
  }

  // Update order
  const [orders] = await conn.query("SELECT id, requirements FROM orders WHERE id='dd75d9c6-2a6f-47b1-a53a-45dd9aa36229'");
  if (orders.length > 0) {
    let oreq = typeof orders[0].requirements === 'string' ? JSON.parse(orders[0].requirements) : (orders[0].requirements || {});
    delete oreq.appName;
    if (oreq.videoTitle) {
      oreq.videoTitle = oreq.videoTitle.replace(/App Installs/gi, 'Installs').replace(/app install/gi, 'installs');
    }
    await conn.query("UPDATE orders SET requirements=? WHERE id=?", [JSON.stringify(oreq), orders[0].id]);
  }

  console.log('MySQL updates finished successfully!');
  await conn.end();
}

main().catch(console.error);
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/fix_order_task.js\n${nodeScript}\nEOF`);
  const nodeRes = await ssh.execCommand('node /tmp/fix_order_task.js');
  console.log('Node script output:', nodeRes.stdout, nodeRes.stderr);

  // Re-verify API
  const apiRes = await ssh.execCommand(`curl -s -H "x-user-email: brandnew_worker@gmail.com" -H "x-user-id: newworker999" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available`);
  const data = JSON.parse(apiRes.stdout);
  const updatedTask = (data.tasks || []).find(t => t.orderId === 'dd75d9c6-2a6f-47b1-a53a-45dd9aa36229');
  console.log('=== VERIFIED API TARGET TASK ===');
  console.log('ID:', updatedTask?.id);
  console.log('TaskType:', updatedTask?.taskType);
  console.log('appName in requirements:', updatedTask?.requirements?.appName);
  console.log('videoTitle in requirements:', updatedTask?.requirements?.videoTitle);

  // Simulate old APK logic on this task now:
  const t = updatedTask;
  const type = (t.taskType || t.type || '').toLowerCase();
  const reqStr = JSON.stringify(t.requirements || {}).toLowerCase();
  const titleStr = (t.title || t.serviceTitle || t.serviceName || (t.requirements?.serviceName) || '').toLowerCase();
  const targetUrl = (t.targetUrl || t.url || t.requirements?.targetUrl || '').toLowerCase();
  const combined = `${type} ${reqStr} ${titleStr} ${targetUrl}`;

  const isAppInstall = type.includes('install') || combined.includes('install & open') || combined.includes('app install');

  let platform = 'google_maps';
  if (type.includes('google_business') || type.includes('google_maps') || type.includes('gmb') || type.includes('map') || combined.includes('google business') || combined.includes('google maps')) {
    platform = 'google_maps';
  } else if (type.includes('app_install') || (type.includes('install') && !type.includes('instagram')) || combined.includes('install & open') || combined.includes('app install') || combined.includes('playstore') || combined.includes('play.google')) {
    platform = 'playstore';
  } else if (type.includes('youtube') || combined.includes('youtube') || type.includes('yt_')) {
    platform = 'youtube';
  }

  console.log('Simulated Old APK isAppInstall:', isAppInstall);
  console.log('Simulated Old APK platform:', platform);

  ssh.dispose();
}

run().catch(console.error);
