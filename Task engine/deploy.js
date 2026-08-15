const { Client } = require('ssh2');

const conn = new Client();
const config = { host: '95.179.178.6', port: 22, username: 'root', password: 'i_G72#y}(6gACDDU' };

const commands = `
cat << 'EOF' > /var/www/task-engine/check_pm2_env.js
const mysql = require('mysql2/promise');
require('dotenv').config({ path: '/var/www/task-engine/Task engine/.env' });

async function main() {
    console.log('NODE_ENV from dotenv:', process.env.NODE_ENV);
}
main();
EOF
node /var/www/task-engine/check_pm2_env.js
pm2 env 0 | grep NODE_ENV
`;

conn.on('ready', () => {
  conn.exec(commands, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (d) => process.stdout.write(d)).stderr.on('data', (d) => process.stderr.write('STDERR: '+d));
  });
}).connect(config);
