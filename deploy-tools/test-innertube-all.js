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

async function getDurationViaInnertube(videoId, clientName = 'ANDROID_TESTSUITE', clientVersion = '1.9') {
  return new Promise(resolve => {
    const postData = JSON.stringify({
      context: {
        client: {
          clientName: clientName,
          clientVersion: clientVersion,
          hl: 'en',
          gl: 'US'
        }
      },
      videoId: videoId
    });

    const req = https.request({
      hostname: 'www.youtube.com',
      port: 443,
      path: '/youtubei/v1/player?prettyPrint=false',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      timeout: 6000
    }, (res) => {
      let b = '';
      res.on('data', ch => b += ch);
      res.on('end', () => {
        try {
          const j = JSON.parse(b);
          const details = j.videoDetails;
          if (details && details.lengthSeconds) {
            resolve({
              success: true,
              videoId,
              title: details.title,
              author: details.author,
              lengthSeconds: parseInt(details.lengthSeconds, 10),
              thumbnail: details.thumbnail?.thumbnails?.[details.thumbnail.thumbnails.length - 1]?.url
            });
            return;
          }
        } catch(e) {}
        resolve({ success: false });
      });
    });

    req.on('error', () => resolve({ success: false }));
    req.on('timeout', () => { req.destroy(); resolve({ success: false }); });
    req.write(postData);
    req.end();
  });
}

async function testAll() {
  const videos = ['sViKU1eitc4', 'frBKNr6uS8E', 'eZJlxTJolG4', 'dQw4w9WgXcQ', 'jNQXAC9IVRw'];
  for (const v of videos) {
    const res = await getDurationViaInnertube(v);
    console.log(\`Video \${v}: \`, res);
  }
}

testAll();
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/test-innertube-all.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test-innertube-all.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
