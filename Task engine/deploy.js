const { Client } = require('ssh2');

const conn = new Client();
const config = { host: '95.179.178.6', port: 22, username: 'root', password: 'i_G72#y}(6gACDDU' };

const commands = `mysql -u taskapp -ptaskapp_password task_platform -e 'UPDATE users SET password="$2b$10$sww97yTBVG1.ZklepAmy5.YthpxJpvlbxDBPaT4rsULUer8lSVb1e" WHERE email="snapbizux@gmail.com";'`;

conn.on('ready', () => {
  conn.exec(commands, (err, stream) => {
    if (err) throw err;
    stream.on('close', () => conn.end()).on('data', (d) => process.stdout.write(d)).stderr.on('data', (d) => process.stderr.write('STDERR: '+d));
  });
}).connect(config);
