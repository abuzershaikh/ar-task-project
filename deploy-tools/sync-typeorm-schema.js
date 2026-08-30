const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function syncSchema() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Synchronizing TypeORM entities schema on VPS...');
    const runner = `
const { DataSource } = require('typeorm');
const mysql = require('mysql2/promise');

async function sync() {
  // 1. Get all table column definitions from MariaDB information_schema and alter missing columns
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  const alters = [
    // Service Catalog
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS worker_limit int NOT NULL DEFAULT 1",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS min_accept_hours int NOT NULL DEFAULT 1",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS max_accept_hours int NOT NULL DEFAULT 72",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS min_complete_hours int NOT NULL DEFAULT 1",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS max_complete_hours int NOT NULL DEFAULT 168",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS watchtime_seconds int NOT NULL DEFAULT 0",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS video_tutorial_url varchar(500) NULL",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS audio_guide_url varchar(500) NULL",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS admin_instructions text NULL",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS link_field_label varchar(150) NULL DEFAULT 'Target Link / URL'",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS link_field_placeholder varchar(250) NULL DEFAULT 'https://...'",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS text_field_label varchar(150) NULL DEFAULT 'Custom Text / Instructions'",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS text_field_placeholder varchar(250) NULL DEFAULT 'Enter text, comments or keywords...'",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS watch_time_options json NULL",
    "ALTER TABLE service_catalog ADD COLUMN IF NOT EXISTS deleted_at timestamp NULL DEFAULT NULL",
    
    // Orders
    "ALTER TABLE orders ADD COLUMN IF NOT EXISTS extension_count int NOT NULL DEFAULT 0",
    "ALTER TABLE orders ADD COLUMN IF NOT EXISTS extension_history json NULL",
    
    // Tasks
    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS attempts json NULL",
    "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS current_assignment_id varchar(255) NULL"
  ];

  for (const sql of alters) {
    try {
      await conn.execute(sql);
      console.log('Executed:', sql);
    } catch (e) {
      console.warn('Warning:', e.message);
    }
  }

  await conn.end();
  console.log('All missing columns added successfully!');
}

sync().catch(err => { console.error('Error:', err); process.exit(1); });
`;
    await ssh.execCommand(`node -e "${runner.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });

    // Restart API
    console.log('Restarting task-engine-api...');
    await ssh.execCommand('pm2 restart task-engine-api');
    await new Promise(r => setTimeout(r, 2000));

    // Test Admin Services API again
    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    const data = JSON.parse(loginRes.stdout);
    const token = data.data.accessToken;

    const servicesRes = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/admin/services -H "Authorization: Bearer ${token}"`);
    console.log('\nAdmin Services API Output:\n', servicesRes.stdout);

    const buyerServicesRes = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/buyer/services -H "Authorization: Bearer ${token}"`);
    console.log('\nBuyer Services API Output:\n', buyerServicesRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}
syncSchema();
