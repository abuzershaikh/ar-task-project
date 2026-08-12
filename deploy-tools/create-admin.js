const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function createAdminUser() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('Connected to VPS...');

    const email = 'snapbizux@gmail.com';
    const rawPassword = '80978097';

    // Run a self-contained node script using root privileges on VPS
    const nodeJsScript = `
const bcrypt = require('/var/www/task-engine/node_modules/bcrypt');
const mysql = require('/var/www/task-engine/node_modules/mysql2/promise');

async function run() {
  const hash = await bcrypt.hash('${rawPassword}', 10);
  console.log('Generated bcrypt hash length:', hash.length);
  
  // Connect using socket / local root auth
  const conn = await mysql.createConnection({
    socketPath: '/var/run/mysqld/mysqld.sock',
    user: 'root',
    database: 'task_platform'
  });

  const [existing] = await conn.execute('SELECT id FROM users WHERE email = ?', ['${email}']);
  
  if (existing.length > 0) {
    await conn.execute(
      'UPDATE users SET password = ?, role = "SUPER_ADMIN", status = "ACTIVE", login_attempts = 0, locked_until = NULL WHERE email = ?',
      [hash, '${email}']
    );
    console.log('Admin user updated successfully');
  } else {
    const id = require('crypto').randomUUID();
    await conn.execute(
      'INSERT INTO users (id, email, password, full_name, role, status, email_verified, phone_verified, login_attempts, created_at, updated_at) VALUES (?, ?, ?, ?, "SUPER_ADMIN", "ACTIVE", 1, 1, 0, NOW(), NOW())',
      [id, '${email}', hash, 'Super Admin']
    );
    console.log('Admin user created successfully');
  }
  
  await conn.end();
}

run().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
`;

    // Upload temporary script to VPS and execute with node
    await ssh.execCommand(`cat << 'EOF' > /tmp/seed_admin.js\n${nodeJsScript}\nEOF`);
    const runRes = await ssh.execCommand('node /tmp/seed_admin.js');
    console.log('Node Output:', runRes.stdout);
    if (runRes.stderr) console.error('Node Error:', runRes.stderr);

    await ssh.execCommand('rm -f /tmp/seed_admin.js');

    // Test Login via curl
    console.log('\n--- Testing Login with snapbizux@gmail.com ---');
    const loginRes = await ssh.execCommand(`curl -s -X POST -H "Content-Type: application/json" -d '{"email":"${email}","password":"${rawPassword}"}' http://localhost:3000/api/v1/auth/login`);
    console.log('Login Response:\n', loginRes.stdout);

    ssh.dispose();
}

createAdminUser().catch(err => console.error(err));
