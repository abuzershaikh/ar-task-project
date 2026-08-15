const mysql = require('mysql2/promise');

async function testConnection() {
  console.log('Testing MySQL connection...');
  try {
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'taskapp',
      password: 'taskapp_password',
      database: 'task_platform'
    });
    
    console.log('Successfully connected to MySQL database.');
    
    // Check tables
    const [tables] = await connection.execute('SHOW TABLES');
    console.log('\nExisting Tables:');
    for (const row of tables) {
      console.log(`- ${Object.values(row)[0]}`);
    }
    
    // Test KYC table schema
    try {
      const [kycColumns] = await connection.execute('SHOW COLUMNS FROM kyc_profiles');
      console.log('\nKYC Table Columns:');
      for (const col of kycColumns) {
        console.log(`- ${col.Field} (${col.Type})`);
      }
    } catch (err) {
      console.log('KYC table not found or error reading it.');
    }

    await connection.end();
  } catch (err) {
    console.error('Database connection failed:', err.message);
  }
}

testConnection();
