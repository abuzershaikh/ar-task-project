const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');

const ssh = new NodeSSH();

async function downloadServerCode() {
  try {
    console.log('Connecting to VPS to pull latest server code...');
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU',
      readyTimeout: 30000,
    });

    console.log('Packaging latest code on server (/var/www/task-engine)...');
    await ssh.execCommand('cd /var/www/task-engine && tar --exclude="node_modules" --exclude="dist" -czf /tmp/server-latest-task-engine.tar.gz .');

    const localZipPath = path.resolve(__dirname, 'server-latest-task-engine.tar.gz');
    console.log(`Downloading server code package to ${localZipPath}...`);
    await ssh.getFile(localZipPath, '/tmp/server-latest-task-engine.tar.gz');

    console.log('DOWNLOAD COMPLETE! Server code safely saved to deploy-tools/server-latest-task-engine.tar.gz');
  } catch (err) {
    console.error('Download failed:', err);
  } finally {
    ssh.dispose();
  }
}

downloadServerCode();
