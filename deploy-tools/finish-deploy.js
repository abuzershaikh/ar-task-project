const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function finishDeploy() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 30000,
    });
    console.log('Connected to VPS!');

    // 1. Kill the hung create_admin script
    console.log('Clearing old create_admin PID...');
    await ssh.execCommand('pkill -f create_admin.js || true');

    // 2. Start PM2 services
    console.log('Starting PM2 task-engine services...');
    await ssh.execCommand('cd /opt/task-engine && pm2 start ecosystem.config.json --only task-engine-api,task-engine-worker');
    await ssh.execCommand('pm2 save');

    // 3. Wait for NestJS to initialize database tables
    console.log('Waiting 6s for NestJS TypeORM to initialize tables...');
    await new Promise(r => setTimeout(r, 6000));

    // 4. Check PM2 status
    const pm2List = await ssh.execCommand('pm2 list');
    console.log('\nPM2 Status:\n', pm2List.stdout);

    // 5. Test API health
    const health = await ssh.execCommand('curl -s http://localhost:3000/api/v1/health');
    console.log('\nAPI Health Check:', health.stdout);

    // 6. Check tables created in database
    const tables = await ssh.execCommand('mysql -e "USE task_platform; SHOW TABLES;"');
    console.log('\nDatabase Tables in task_platform:\n', tables.stdout);

    // 7. Seed Admin properly
    console.log('\nSeeding SuperAdmin user...');
    const seedScript = `
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

async function main() {
  let conn;
  try {
    conn = await mysql.createConnection({
      host: 'localhost',
      user: 'taskapp',
      password: 'taskapp_password',
      database: 'task_platform'
    });

    const admins = [
      { email: 'admin@taskpost.com', pass: 'Admin@123456', name: 'Super Admin' },
      { email: 'snapbizux@gmail.com', pass: '80978097', name: 'Snapbiz Admin' }
    ];

    for (const a of admins) {
      const hash = await bcrypt.hash(a.pass, 10);
      const [rows] = await conn.execute('SELECT id FROM users WHERE email = ?', [a.email]);
      if (rows.length > 0) {
        await conn.execute('UPDATE users SET password = ?, role = "SUPER_ADMIN", status = "ACTIVE" WHERE email = ?', [hash, a.email]);
        console.log('Updated admin:', a.email);
      } else {
        const id = crypto.randomUUID();
        await conn.execute('INSERT INTO users (id, email, fullName, password, role, status, emailVerified, phoneVerified, createdAt, updatedAt) VALUES (?, ?, ?, ?, "SUPER_ADMIN", "ACTIVE", 1, 1, NOW(), NOW())', [id, a.email, a.name, hash]);
        console.log('Created admin:', a.email);
      }
    }
  } catch (err) {
    console.error('Seed error:', err.message);
  } finally {
    if (conn) await conn.end();
  }
}
main();
`;
    await ssh.execCommand(`node -e "${seedScript.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`);

    // 8. Verify admin in DB
    const adminCheck = await ssh.execCommand('mysql -e "USE task_platform; SELECT id, email, role, status FROM users;"');
    console.log('\nAdmin Users in Database:\n', adminCheck.stdout);

    // 9. Check logs
    const apiLogs = await ssh.execCommand('pm2 logs task-engine-api --lines 20 --nostream');
    console.log('\nAPI Logs:\n', apiLogs.stdout);

    const workerLogs = await ssh.execCommand('pm2 logs task-engine-worker --lines 20 --nostream');
    console.log('\nWorker Logs:\n', workerLogs.stdout);

  } catch (err) {
    console.error('Finish deploy error:', err);
  } finally {
    ssh.dispose();
  }
}

finishDeploy();
