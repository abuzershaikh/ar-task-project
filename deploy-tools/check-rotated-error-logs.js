const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== LIST ALL LOGS IN /root/.pm2/logs ===');
    console.log((await ssh.execCommand('ls -lht /root/.pm2/logs/')).stdout);

    console.log('\n=== CHECK NON-EMPTY ERROR LOGS ===');
    console.log((await ssh.execCommand('find /root/.pm2/logs/ -type f -size +0c -name "*error*" -exec ls -lh {} \\;')).stdout);

    console.log('\n=== READ NON-EMPTY ERROR LOGS (if any) ===');
    console.log((await ssh.execCommand('for f in $(find /root/.pm2/logs/ -type f -size +0c -name "*error*"); do echo "--- $f ---"; tail -n 20 $f; done')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();
