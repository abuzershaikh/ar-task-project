const mysql = require('mysql2/promise');

async function checkAdmins() {
  try {
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'taskapp',
      password: 'taskapp_password',
      database: 'task_platform'
    });
    
    console.log('Checking Admin users...');
    
    const [users] = await connection.execute('SELECT id, email, role, status FROM users WHERE role IN ("ADMIN", "SUPER_ADMIN")');
    console.log('\nAdmin Users:', users);

    await connection.end();
  } catch (err) {
    console.error('Database connection failed:', err.message);
  }
}

checkAdmins();
