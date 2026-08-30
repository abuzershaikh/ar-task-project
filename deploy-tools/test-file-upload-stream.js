const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testUploadAndStream() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    // 1. Create a dummy test image on VPS
    await ssh.execCommand('echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > /tmp/sample_screenshot.png');

    // 2. Upload file
    const uploadRes = await ssh.execCommand('curl -s -v -X POST -H "x-user-email: snapbizux@gmail.com" -H "x-user-id: 15QuKnQDcwS5NLacLIQ8V8CElnA2" -H "x-user-role: WORKER" -F "file=@/tmp/sample_screenshot.png;type=image/png" http://127.0.0.1:3000/api/v1/files/upload');
    console.log('UPLOAD STDOUT:\n', uploadRes.stdout);
    console.log('UPLOAD STDERR:\n', uploadRes.stderr);

    if (uploadRes.stdout) {
      try {
        const json = JSON.parse(uploadRes.stdout);
        console.log('\nParsed JSON:', json);
        if (json.url) {
          const streamUrl = json.url.replace('http://65.20.77.112:3000', 'http://127.0.0.1:3000');
          console.log('\nTesting Public Image Stream GET without any auth headers:', streamUrl);
          const streamRes = await ssh.execCommand(`curl -s -I ${streamUrl}`);
          console.log('STREAM HEADERS:\n', streamRes.stdout);
        }
      } catch (e) {
        console.error('JSON parse error:', e);
      }
    }

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

testUploadAndStream();
