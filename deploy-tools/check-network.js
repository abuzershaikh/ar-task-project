const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkNetwork() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    console.log('Connected to VPS...\n');

    console.log('--- 1. UFW Firewall Status ---');
    const ufw = await ssh.execCommand('ufw status');
    console.log(ufw.stdout);

    console.log('\n--- 2. Listening Ports ---');
    const netstat = await ssh.execCommand('netstat -tulpn');
    console.log(netstat.stdout);

    console.log('\n--- 3. Nginx Status & Config ---');
    const nginxStatus = await ssh.execCommand('systemctl status nginx || service nginx status');
    console.log(nginxStatus.stdout);

    const nginxConf = await ssh.execCommand('cat /etc/nginx/sites-enabled/* 2>/dev/null || cat /etc/nginx/conf.d/* 2>/dev/null');
    console.log('Nginx Sites Config:\n', nginxConf.stdout || '(No sites-enabled config found)');

    ssh.dispose();
}

checkNetwork().catch(err => console.error(err));
