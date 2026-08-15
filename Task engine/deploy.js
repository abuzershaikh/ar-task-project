const { Client } = require('ssh2');

const conn = new Client();
const config = { host: '95.179.178.6', port: 22, username: 'root', password: 'i_G72#y}(6gACDDU' };

const commands = `
cd "/var/www/task-engine/Task engine"
git pull origin task-engine
npm run build
pm2 restart all
`;

conn.on('ready', () => {
  conn.exec(commands, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (d) => process.stdout.write(d)).stderr.on('data', (d) => process.stderr.write('STDERR: '+d));
  });
}).connect(config);
