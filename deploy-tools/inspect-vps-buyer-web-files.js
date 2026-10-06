const { NodeSSH } = require('node-ssh');
const AdmZip = require('adm-zip');
const path = require('path');
const fs = require('fs');

const ssh = new NodeSSH();

const config = {
  host: '65.20.77.112',
  username: 'root',
  password: 'G8u$RW{5m46buXgw',
  readyTimeout: 60000,
};

const WEB_DIR = path.resolve(__dirname, '../buyer-web');

async function main() {
  console.log('Connecting to VPS...');
  await ssh.connect(config);
  console.log('Connected!');

  const ls = await ssh.execCommand('ls -la /var/www/buyer-web');
  console.log('Current files in /var/www/buyer-web:\n', ls.stdout);

  ssh.dispose();
}

main().catch(err => {
  console.error(err);
  ssh.dispose();
});
