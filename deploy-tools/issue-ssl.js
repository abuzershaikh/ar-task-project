const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function issueSSL() {
  try {
    console.log('Connecting to VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    console.log('Connected!');

    console.log('\nIssuing Free Let\'s Encrypt SSL Certificate for swiftcommerce.in...');
    const cmd = 'certbot --nginx -d swiftcommerce.in -d www.swiftcommerce.in --non-interactive --agree-tos -m admin@swiftcommerce.in --redirect';
    console.log(`> ${cmd}`);
    const res = await ssh.execCommand(cmd);
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    if (res.code === 0) {
      console.log('\n🎉 SSL Certificate Successfully Installed!');
      console.log('Enabling automatic renewal timer...');
      await ssh.execCommand('systemctl enable --now certbot-renew.timer || true');
      console.log('Your website is now secure: https://swiftcommerce.in');
    } else {
      console.log('\n⚠️ SSL Issuance not ready yet. Please wait for global DNS propagation to complete and re-run.');
    }
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

issueSSL();
