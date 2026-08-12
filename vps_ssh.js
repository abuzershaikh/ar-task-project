const { Client } = require('ssh2');

const config = {
  host: '95.179.178.6',
  port: 22,
  username: 'root',
  password: 'i_G72#y}(6gACDDU',
  readyTimeout: 15000,
};

const command = process.argv[2] || 'ls -la /root/';

const conn = new Client();
conn.on('ready', () => {
  conn.exec(command, (err, stream) => {
    if (err) { console.error('Exec error:', err); conn.end(); return; }
    let output = '';
    let errOutput = '';
    stream.on('close', (code) => {
      if (output) console.log(output);
      if (errOutput) console.error('STDERR:', errOutput);
      conn.end();
    }).on('data', (data) => {
      output += data.toString();
    }).stderr.on('data', (data) => {
      errOutput += data.toString();
    });
  });
}).on('error', (err) => {
  console.error('Connection error:', err.message);
}).connect(config);
