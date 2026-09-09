const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

const scriptContent = `
const mysql = require('mysql2/promise');
const https = require('https');

function extractPackageId(input) {
  if (!input) return null;
  let clean = input.trim();
  if (clean.includes('id=')) {
    const match = clean.match(/[?&]id=([a-zA-Z0-9_]+(?:\\.[a-zA-Z0-9_]+)+)/i) ||
                  clean.match(/id=([a-zA-Z0-9_.]+)/i);
    if (match) return match[1].replace(/\\.+$/, '').split('&')[0];
  }
  if (clean.startsWith('market://details?id=')) {
    return clean.replace('market://details?id=', '').split('&')[0].replace(/\\.+$/, '');
  }
  const bareMatch = clean.match(/^([a-zA-Z0-9_]+(?:\\.[a-zA-Z0-9_]+)+)$/);
  if (bareMatch) return bareMatch[1];
  return null;
}

function fetchPlayStoreInfo(packageId) {
  return new Promise((resolve) => {
    const url = 'https://play.google.com/store/apps/details?id=' + packageId + '&hl=en&gl=US';
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
      },
      timeout: 8000,
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 400) {
          try {
            const titleMatch = data.match(/<meta\\s+property=["']og:title["']\\s+content=["'](.*?)["']/i) ||
                               data.match(/<title>(.*?)<\\/title>/i);
            let title = titleMatch ? titleMatch[1] : '';
            title = title
              .replace(/\\s*-\\s*Apps on Google Play.*/i, '')
              .replace(/\\s*-\\s*Google Play.*/i, '')
              .split(/[:\\-|–—]/)[0]
              .replace(/&amp;/g, '&')
              .replace(/&#39;/g, "'")
              .replace(/&quot;/g, '"')
              .trim();

            const iconMatch = data.match(/<meta\\s+property=["']og:image["']\\s+content=["'](.*?)["']/i) ||
                              data.match(/<img[^>]+src=["'](https:\\/\\/play-lh\\.googleusercontent\\.com\\/[^"']+)["'][^>]*alt=["']Icon image["']/i);
            let iconUrl = iconMatch ? iconMatch[1] : '';

            resolve({ success: true, appName: title || packageId, appIcon: iconUrl, packageId });
          } catch(e) {
            resolve({ success: false });
          }
        } else {
          resolve({ success: false });
        }
      });
    }).on('error', () => resolve({ success: false }));
  });
}

async function run() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  console.log('Connected to task_platform DB');

  // 1. Delete invalid dummy tasks like youtube.com/watch?v=test created as APP_INSTALL
  const [dummyRes] = await conn.query("DELETE FROM tasks WHERE task_type = 'APP_INSTALL' AND requirements LIKE '%youtube.com/watch?v=test%'");
  console.log('Deleted dummy test tasks:', dummyRes.affectedRows);

  // 2. Fetch all tasks with targetUrl
  const [tasks] = await conn.query("SELECT id, order_id, task_type, requirements, metadata FROM tasks WHERE task_type IN ('APP_INSTALL', 'PLAYSTORE_RATING', 'PLAYSTORE_REVIEW') OR requirements LIKE '%play.google.com%'");
  console.log('Found ' + tasks.length + ' Play Store tasks to check and synchronize');

  const cache = {};

  for (const t of tasks) {
    let req = typeof t.requirements === 'string' ? JSON.parse(t.requirements) : (t.requirements || {});
    let meta = typeof t.metadata === 'string' ? JSON.parse(t.metadata) : (t.metadata || {});

    const targetUrl = req.targetUrl || '';
    const pkg = extractPackageId(targetUrl);

    if (pkg) {
      if (!cache[pkg]) {
        console.log('Fetching live info for package: ' + pkg);
        cache[pkg] = await fetchPlayStoreInfo(pkg);
      }
      const info = cache[pkg];
      if (info && info.success) {
        req.appName = info.appName;
        req.appIcon = info.appIcon;
        req.packageId = info.packageId;

        meta.appName = info.appName;
        meta.appIcon = info.appIcon;
        meta.packageId = info.packageId;

        await conn.query("UPDATE tasks SET requirements = ?, metadata = ? WHERE id = ?", [JSON.stringify(req), JSON.stringify(meta), t.id]);
        console.log('Updated task ' + t.id + ' -> ' + info.appName + ' (' + pkg + ')');
      }
    }
  }

  // 3. Update orders
  const [orders] = await conn.query("SELECT id, requirements FROM orders WHERE service_code IN ('APP_INSTALL', 'PLAYSTORE_RATING', 'PLAYSTORE_REVIEW') OR requirements LIKE '%play.google.com%'");
  for (const o of orders) {
    let req = typeof o.requirements === 'string' ? JSON.parse(o.requirements) : (o.requirements || {});
    const targetUrl = req.targetUrl || '';
    const pkg = extractPackageId(targetUrl);
    if (pkg && cache[pkg] && cache[pkg].success) {
      const info = cache[pkg];
      req.appName = info.appName;
      req.appIcon = info.appIcon;
      req.packageId = info.packageId;
      await conn.query("UPDATE orders SET requirements = ? WHERE id = ?", [JSON.stringify(req), o.id]);
      console.log('Updated order ' + o.id + ' -> ' + info.appName);
    }
  }

  await conn.end();
  console.log('Finished updating tasks and orders!');
}

run().catch(console.error);
`;

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  // Upload the updated backend files first
  console.log('Uploading updated order.controller.ts and order-activated.listener.ts...');
  await ssh.putFile(
    'e:/pc2/android  project/Task  project/ar-task-project/Task engine/apps/api/controllers/buyer/order.controller.ts',
    '/opt/task-engine/apps/api/controllers/buyer/order.controller.ts'
  );
  await ssh.putFile(
    'e:/pc2/android  project/Task  project/ar-task-project/Task engine/shared/services/order-activated.listener.ts',
    '/opt/task-engine/shared/services/order-activated.listener.ts'
  );

  console.log('Building Task engine on server...');
  const buildRes = await ssh.execCommand('npx nest build', { cwd: '/opt/task-engine' });
  console.log('Build stdout:', buildRes.stdout);
  if (buildRes.stderr) console.log('Build stderr:', buildRes.stderr);

  console.log('Restarting PM2 backend services...');
  await ssh.execCommand('pm2 restart task-engine-api', { cwd: '/opt/task-engine' });
  await ssh.execCommand('pm2 restart task-engine-worker', { cwd: '/opt/task-engine' });

  console.log('Running DB repair script on server...');
  await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/fix-app-metadata.js\n${scriptContent}\nEOF`);
  const fixRes = await ssh.execCommand('node fix-app-metadata.js', { cwd: '/opt/task-engine' });
  console.log(fixRes.stdout);
  if (fixRes.stderr) console.log('Fix stderr:', fixRes.stderr);

  ssh.dispose();
}

main().catch(console.error);
