const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function tailOut() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    const res = await ssh.execCommand('tail -n 30 /root/.pm2/logs/task-engine-out-0.log');
    console.log(res.stdout);
    ssh.dispose();
}

tailOut();
