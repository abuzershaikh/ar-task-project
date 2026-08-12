const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function getLogs() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    const result = await ssh.execCommand('tail -n 100 /root/.pm2/logs/task-engine-error-0.log');
    console.log(result.stdout);
    ssh.dispose();
}
getLogs();
