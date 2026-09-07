const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployVPS() {
  console.log('Connecting to VPS 65.20.77.112 ...');
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  console.log('Uploading build/web to VPS /var/www/buyer-web ...');
  const localWebDir = path.resolve(__dirname, '../buyer-web-app/build/web');
  await ssh.putDirectory(localWebDir, '/var/www/buyer-web', {
    recursive: true,
    concurrency: 10,
    validate: function(itemPath) {
      const baseName = path.basename(itemPath);
      return !baseName.startsWith('.');
    }
  });
  console.log('VPS upload complete!');
  const reloadRes = await ssh.execCommand('systemctl reload nginx');
  console.log('Nginx reloaded:', reloadRes.stdout || 'OK');
  ssh.dispose();
}

deployVPS().catch(console.error);
