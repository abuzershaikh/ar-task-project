const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function getFailedQuery() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    // TypeORM usually logs queries if logging is true. Let's get the 20 lines before the QueryFailedError
    const result = await ssh.execCommand('grep -B 20 "QueryFailedError: Duplicate key name" /root/.pm2/logs/task-engine-error-0.log | head -n 30');
    console.log(result.stdout);
    
    ssh.dispose();
}
getFailedQuery();
