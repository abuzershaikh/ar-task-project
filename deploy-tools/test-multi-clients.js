const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const scriptContent = `
const https = require('https');

async function testVideo(videoId) {
  const clients = [
    { clientName: 'ANDROID_TESTSUITE', clientVersion: '1.9' },
    { clientName: 'MWEB', clientVersion: '2.20240901.01.00', hl: 'en', gl: 'US' },
    { clientName: 'WEB', clientVersion: '2.20240901.01.00', hl: 'en', gl: 'US' },
    { clientName: 'TVHTML5', clientVersion: '7.20240901.01.00', hl: 'en', gl: 'US' },
    { clientName: 'ANDROID', clientVersion: '19.09.37', androidSdkVersion: 30, hl: 'en', gl: 'US' }
  ];

  for (const c of clients) {
    const postData = JSON.stringify({
      context: { client: c },
      videoId: videoId
    });

    const res = await new Promise(resolve => {
      const req = https.request({
        hostname: 'www.youtube.com',
        port: 443,
        path: '/youtubei/v1/player',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
          'User-Agent': 'Mozilla/5.0'
        },
        timeout: 5000
      }, r => {
        let b = '';
        r.on('data', ch => b += ch);
        r.on('end', () => {
          try {
            const j = JSON.parse(b);
            resolve({
              client: c.clientName,
              status: j.playabilityStatus?.status,
              length: j.videoDetails?.lengthSeconds,
              title: j.videoDetails?.title
            });
          } catch(e) { resolve({ client: c.clientName, err: e.message }); }
        });
      });
      req.on('error', e => resolve({ client: c.clientName, err: e.message }));
      req.write(postData);
      req.end();
    });

    console.log(res);
  }
}

testVideo('jNQXAC9IVRw');
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/test-multi-clients.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test-multi-clients.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
