const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('--- Nginx conf.d files ---');
    const ls = await ssh.execCommand('ls -la /etc/nginx/conf.d/');
    console.log(ls.stdout);

    console.log('--- Existing config content ---');
    const cat = await ssh.execCommand('cat /etc/nginx/conf.d/*.conf');
    console.log(cat.stdout);
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

check();
