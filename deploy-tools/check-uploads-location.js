const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkUploads() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('--- CHECK FILES TABLE ---');
    const files = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM files LIMIT 5;"');
    console.log(files.stdout);

    console.log('--- CHECK PM2 ---');
    const pm2 = await ssh.execCommand('pm2 list');
    console.log(pm2.stdout);

    console.log('--- CHECK UPLOADS DIRECTORIES ---');
    const uploads = await ssh.execCommand('find /root /var/www -type d -name uploads 2>/dev/null');
    console.log(uploads.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkUploads();
