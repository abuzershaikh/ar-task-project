const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');

async function createAdmin() {
  try {
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'taskapp',
      password: 'taskapp_password',
      database: 'task_platform'
    });
    
    console.log('Connected to MySQL');
    
    const email = 'snapbizux@gmail.com';
    const plainPassword = '80978097';
    const role = 'SUPER_ADMIN';

    // Hash the password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(plainPassword, saltRounds);

    const [existing] = await connection.execute('SELECT id FROM users WHERE email = ?', [email]);
    
    if (existing.length > 0) {
      console.log(`User ${email} already exists. Updating password and role...`);
      await connection.execute(
        'UPDATE users SET password = ?, role = ?, status = "ACTIVE" WHERE email = ?',
        [hashedPassword, role, email]
      );
      console.log('Admin user updated successfully!');
    } else {
      console.log(`Creating new user ${email}...`);
      
      // Need a random UUID for ID. We can use crypto module
      const crypto = require('crypto');
      const id = crypto.randomUUID();
      
      await connection.execute(
        `INSERT INTO users (id, email, fullName, password, role, status, emailVerified, phoneVerified, createdAt, updatedAt) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())`,
        [id, email, 'Admin User', hashedPassword, role, 'ACTIVE', 1, 1]
      );
      console.log('Admin user created successfully!');
    }

    await connection.end();
  } catch (err) {
    console.error('Database error:', err.message);
  }
}

createAdmin();
