const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function check() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const res = await ssh.execCommand('cat /etc/nginx/conf.d/reviewsgateway.conf');
    console.log('reviewsgateway.conf:\n', res.stdout);

    const res2 = await ssh.execCommand('curl -v -H "Host: reviewsgateway.in" http://127.0.0.1 2>&1');
    console.log('Curl output:\n', res2.stdout);
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

check();
