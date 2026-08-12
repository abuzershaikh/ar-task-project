const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkServer() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('Connected to VPS...');
    
    // Check if app is responding locally on the VPS
    const curlResult = await ssh.execCommand('curl -X POST -H "Content-Type: application/json" -d \'{}\' http://localhost:3000/api/v1/auth/register');
    console.log("Curl Output:", curlResult.stdout, curlResult.stderr);
    
    // Check if port 3000 is open in firewall
    const ufwResult = await ssh.execCommand('ufw status');
    console.log("UFW Status:", ufwResult.stdout);
    
    // Check listening ports
    const netstatResult = await ssh.execCommand('netstat -tulpn | grep 3000');
    console.log("Netstat:", netstatResult.stdout);
    
    ssh.dispose();
}
checkServer();
