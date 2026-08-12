const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function start() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('Connected! Starting PM2...');
    const result = await ssh.execCommand('cd /var/www/task-engine && pm2 start dist/main.js --name task-engine -i 2');
    console.log(result.stdout);
    console.error(result.stderr);
    await ssh.execCommand('pm2 save');
    console.log('App started and PM2 saved.');
    ssh.dispose();
}
start();
