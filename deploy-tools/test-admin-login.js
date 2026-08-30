const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkUsers() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 10000,
    });
    const users = await ssh.execCommand('mysql -e "USE task_platform; SELECT id, email, role, status, password FROM users;"');
    console.log('Users in DB:\n', users.stdout);

    // Test password compare directly using node
    const testScript = `
const bcrypt = require('bcrypt');
async function test() {
  const hash = '$2b$10$...';
  const match = await bcrypt.compare('80978097', hash);
  console.log('Match:', match);
}
`;
    // Let's create an admin with proper bcrypt hash directly via Node in /opt/task-engine
    const createScript = `
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');
const crypto = require('crypto');

async function create() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'taskapp',
    password: 'taskapp_password',
    database: 'task_platform'
  });

  const hash1 = await bcrypt.hash('80978097', 10);
  const hash2 = await bcrypt.hash('Admin@123456', 10);

  await conn.execute('DELETE FROM users WHERE email IN ("snapbizux@gmail.com", "admin@taskpost.com")');
  
  await conn.execute('INSERT INTO users (id, email, full_name, password, role, status, email_verified, phone_verified, created_at, updated_at) VALUES (?, "snapbizux@gmail.com", "Snapbiz Admin", ?, "SUPER_ADMIN", "ACTIVE", 1, 1, NOW(), NOW())', [crypto.randomUUID(), hash1]);
  await conn.execute('INSERT INTO users (id, email, full_name, password, role, status, email_verified, phone_verified, created_at, updated_at) VALUES (?, "admin@taskpost.com", "Super Admin", ?, "SUPER_ADMIN", "ACTIVE", 1, 1, NOW(), NOW())', [crypto.randomUUID(), hash2]);

  console.log('Admins re-created with fresh bcrypt hashes!');
  await conn.end();
}
create().catch(console.error);
`;
    await ssh.execCommand(`node -e "${createScript.replace(/"/g, '\\"').replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });

    // Test login API
    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    console.log('\nSnapbiz Login Response:\n', loginRes.stdout);

    const loginRes2 = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"admin@taskpost.com","password":"Admin@123456"}'`);
    console.log('\nTaskPost Login Response:\n', loginRes2.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}
checkUsers();
