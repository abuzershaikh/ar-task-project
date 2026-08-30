const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testUpload() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    await ssh.execCommand('echo "test screenshot file content" > /tmp/sample_screenshot.png');
    const res = await ssh.execCommand(`curl -s -i -X POST -H 'x-user-email: testworker@gmail.com' -H 'x-user-role: WORKER' -F 'file=@/tmp/sample_screenshot.png;type=image/png' http://127.0.0.1:3000/api/v1/files/upload`);
    console.log('Server response:');
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

testUpload();
