const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkOutLog() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    const result = await ssh.execCommand('grep -B 5 "IDX_f2685f6c47073186552ef9bebb" /root/.pm2/logs/task-engine-out-0.log | head -n 30');
    console.log(result.stdout);
    if (!result.stdout) {
         const result2 = await ssh.execCommand('grep -B 5 "IDX_f2685f6c47073186552ef9bebb" /root/.pm2/logs/task-engine-out-1.log | head -n 30');
         console.log(result2.stdout);
    }
    
    ssh.dispose();
}
checkOutLog();
