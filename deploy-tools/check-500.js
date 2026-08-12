const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check500() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    // Clear logs
    await ssh.execCommand('pm2 flush');
    console.log("Cleared logs.");
    
    // Trigger request
    const curlResult = await ssh.execCommand('curl -X POST -H "Content-Type: application/json" -d \'{"email":"test@test.com","password":"Password123!","fullName":"Test User","role":"BUYER","phone":"+1234567890"}\' http://localhost:3000/api/v1/auth/register');
    console.log("CURL:", curlResult.stdout);
    
    // Wait a sec for log to write
    await new Promise(r => setTimeout(r, 1000));
    
    // Get logs
    const result = await ssh.execCommand('pm2 logs task-engine --lines 20 --nostream');
    console.log(result.stdout);
    if (result.stderr) console.error(result.stderr);
    
    ssh.dispose();
}
check500();
