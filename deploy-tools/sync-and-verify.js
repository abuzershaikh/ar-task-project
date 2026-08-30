const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runMigrationsAndSeed() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 30000,
    });
    console.log('Connected to VPS!');

    // 1. Check tables
    let tables = await ssh.execCommand('mysql -e "USE task_platform; SHOW TABLES;"');
    console.log('Current Tables:', tables.stdout || '(None)');

    // 2. Run migrations via npx typeorm or ts-node data-source
    console.log('Running schema sync/migration...');
    const syncScript = `
const { AppDataSource } = require('./dist/data-source');
async function init() {
  await AppDataSource.initialize();
  console.log('DataSource Initialized. Synchronizing schema...');
  await AppDataSource.synchronize(false);
  console.log('Schema synchronized successfully!');
  await AppDataSource.destroy();
}
init().catch(err => { console.error('Sync error:', err); process.exit(1); });
`;
    await ssh.execCommand(`node -e "${syncScript.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });

    // 3. Check tables again
    tables = await ssh.execCommand('mysql -e "USE task_platform; SHOW TABLES;"');
    console.log('\nTables after sync:\n', tables.stdout);

    // 4. Seed admin
    console.log('\nSeeding SuperAdmin...');
    const seedScript = `
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

async function seed() {
  const conn = await mysql.createConnection({
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
      console.log('✅ Admin updated:', a.email);
    } else {
      const id = crypto.randomUUID();
      await conn.execute('INSERT INTO users (id, email, fullName, password, role, status, emailVerified, phoneVerified, createdAt, updatedAt) VALUES (?, ?, ?, ?, "SUPER_ADMIN", "ACTIVE", 1, 1, NOW(), NOW())', [id, a.email, a.name, hash]);
      console.log('✅ Admin created:', a.email);
    }
  }

  // Seed default service catalog if empty
  const [services] = await conn.execute('SELECT id FROM service_catalog LIMIT 1');
  if (services.length === 0) {
    const s1Id = crypto.randomUUID();
    await conn.execute('INSERT INTO service_catalog (id, code, name, description, isActive, version, createdAt, updatedAt) VALUES (?, "YOUTUBE_LIKE", "YouTube Video Like", "High quality real user likes", 1, 1, NOW(), NOW())', [s1Id]);
    await conn.execute('INSERT INTO service_pricing (id, serviceId, buyerUnitPrice, marginType, marginValue, workerReward, currency, version, isActive, createdAt, updatedAt) VALUES (?, ?, 2.00, "FIXED", 0.50, 1.50, "INR", 1, 1, NOW(), NOW())', [crypto.randomUUID(), s1Id]);
    
    const s2Id = crypto.randomUUID();
    await conn.execute('INSERT INTO service_catalog (id, code, name, description, isActive, version, createdAt, updatedAt) VALUES (?, "YOUTUBE_SUBSCRIBE", "YouTube Channel Subscribe", "Permanent subscribers", 1, 1, NOW(), NOW())', [s2Id]);
    await conn.execute('INSERT INTO service_pricing (id, serviceId, buyerUnitPrice, marginType, marginValue, workerReward, currency, version, isActive, createdAt, updatedAt) VALUES (?, ?, 5.00, "FIXED", 1.50, 3.50, "INR", 1, 1, NOW(), NOW())', [crypto.randomUUID(), s2Id]);

    const s3Id = crypto.randomUUID();
    await conn.execute('INSERT INTO service_catalog (id, code, name, description, isActive, version, createdAt, updatedAt) VALUES (?, "APP_INSTALL", "Android App Install & Open", "Install app from Play Store", 1, 1, NOW(), NOW())', [s3Id]);
    await conn.execute('INSERT INTO service_pricing (id, serviceId, buyerUnitPrice, marginType, marginValue, workerReward, currency, version, isActive, createdAt, updatedAt) VALUES (?, ?, 10.00, "PERCENTAGE", 30.00, 7.00, "INR", 1, 1, NOW(), NOW())', [crypto.randomUUID(), s3Id]);

    console.log('✅ Default Service Catalog & Pricing seeded!');
  }

  await conn.end();
}
seed().catch(console.error);
`;
    await ssh.execCommand(`node -e "${seedScript.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });

    // 5. Test auth endpoint
    console.log('\nTesting Auth API with Snapbiz Admin...');
    const authRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    console.log('Login Response:', authRes.stdout);

    // 6. Test external access
    console.log('\nTesting External URL access...');
    const extHealth = await ssh.execCommand('curl -s http://65.20.77.112:3000/api/v1/health');
    console.log('External Health:', extHealth.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

runMigrationsAndSeed();
