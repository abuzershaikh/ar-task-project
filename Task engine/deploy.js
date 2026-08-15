const { Client } = require('ssh2');

const conn = new Client();
const config = { host: '95.179.178.6', port: 22, username: 'root', password: 'i_G72#y}(6gACDDU' };

const commands = `
cat << 'EOF' > /var/www/task-engine/update_schema.js
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/var/www/task-engine/Task engine/.env' });

async function main() {
    const connection = await mysql.createConnection({
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USERNAME || 'taskapp',
        password: process.env.DB_PASSWORD || 'taskapp_password',
        database: process.env.DB_DATABASE || 'task_platform'
    });

    try {
        console.log('Adding paypal_id to kyc_profiles table...');
        const sql = "ALTER TABLE kyc_profiles ADD COLUMN paypal_id VARCHAR(255) NULL;";
        try {
            await connection.execute(sql);
            console.log('Successfully executed:', sql);
        } catch (err) {
            if (err.code === 'ER_DUP_FIELDNAME') {
                console.log('Column already exists for:', sql);
            } else {
                console.error('Error executing:', sql, err.message);
            }
        }
        
        console.log('Done altering schema.');
    } catch (e) {
        console.error(e);
    } finally {
        await connection.end();
    }
}
main();
EOF
node /var/www/task-engine/update_schema.js
`;

conn.on('ready', () => {
  conn.exec(commands, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (d) => process.stdout.write(d)).stderr.on('data', (d) => process.stderr.write('STDERR: '+d));
  });
}).connect(config);
