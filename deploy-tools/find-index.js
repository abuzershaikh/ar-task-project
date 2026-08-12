const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function findDuplicateIndex() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    // We will search the source code for the hash, maybe it is hardcoded?
    const result = await ssh.execCommand('grep -rn "IDX_97672ac88f789774dd47f7c8be" /var/www/task-engine');
    console.log("GREP:", result.stdout);
    
    ssh.dispose();
}
findDuplicateIndex();
