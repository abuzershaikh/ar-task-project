const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function trace() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const res = await ssh.execCommand('curl -s -H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: SUPER_ADMIN" http://127.0.0.1:3000/api/v1/admin/dashboard');
    console.log(res.stdout);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

trace();
