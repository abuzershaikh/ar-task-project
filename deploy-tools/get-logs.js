const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function getLogs() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    const result = await ssh.execCommand('pm2 logs task-engine --lines 100 --nostream');
    console.log(result.stdout);
    console.error(result.stderr);
    ssh.dispose();
}
getLogs();
