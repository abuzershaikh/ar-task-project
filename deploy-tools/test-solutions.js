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
const fs = require('fs');
const https = require('https');

const videoId = 'sViKU1eitc4';

// 1. Test oEmbed API
function testOembed() {
  return new Promise(resolve => {
    https.get('https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=' + videoId + '&format=json', (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        console.log('oEmbed response:', res.statusCode, d);
        resolve();
      });
    });
  });
}

// 2. Test Embed page
function testEmbed() {
  return new Promise(resolve => {
    https.get('https://www.youtube.com/embed/' + videoId, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://google.com'
      }
    }, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        console.log('Embed page status:', res.statusCode, 'length:', d.length);
        const m = d.match(/"lengthSeconds":"(\\d+)"/) || d.match(/approxDurationMs":"(\\d+)"/);
        console.log('Embed duration match:', m ? m[0] : 'none');
        const t = d.match(/<title>([^<]+)<\\/title>/);
        console.log('Embed title:', t ? t[1] : 'none');
        resolve();
      });
    });
  });
}

// 3. Test Innertube with TVHTML5 or IOS client
function testInnertubeClients() {
  const clients = [
    {
      name: 'IOS',
      client: { clientName: 'IOS', clientVersion: '19.29.1', deviceModel: 'iPhone14,3', userAgent: 'com.google.ios.youtube/19.29.1 (iPhone14,3; U; CPU iOS 17_5_1 like Mac OS X; en_US)', hl: 'en', gl: 'US' }
    },
    {
      name: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
      client: { clientName: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER', clientVersion: '2.0', hl: 'en', gl: 'US' }
    },
    {
      name: 'ANDROID_TESTSUITE',
      client: { clientName: 'ANDROID_TESTSUITE', clientVersion: '1.9', hl: 'en', gl: 'US' }
    },
    {
      name: 'WEB_EMBEDDED_PLAYER',
      client: { clientName: 'WEB_EMBEDDED_PLAYER', clientVersion: '1.20240901.01.00', hl: 'en', gl: 'US' }
    }
  ];

  return Promise.all(clients.map(c => {
    return new Promise(resolve => {
      const postData = JSON.stringify({
        context: { client: c.client },
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
          'User-Agent': c.client.userAgent || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      }, (res) => {
        let b = '';
        res.on('data', ch => b += ch);
        res.on('end', () => {
          try {
            const j = JSON.parse(b);
            const status = j.playabilityStatus?.status;
            const length = j.videoDetails?.lengthSeconds;
            const title = j.videoDetails?.title;
            console.log(\`Client \${c.name}: status=\${res.statusCode}, playability=\${status}, lengthSeconds=\${length}, title=\${title}\`);
          } catch(e) {
            console.log(\`Client \${c.name}: error parsing JSON\`);
          }
          resolve();
        });
      });
      req.on('error', () => resolve());
      req.write(postData);
      req.end();
    });
  }));
}

// 4. Check ytInitialData in /tmp/yt.html
function checkInitialData() {
  const html = fs.readFileSync('/tmp/yt.html', 'utf8');
  const idx = html.indexOf('ytInitialData =');
  if (idx !== -1) {
    const start = html.indexOf('{', idx);
    let depth = 0;
    let end = start;
    for (let i = start; i < html.length; i++) {
      if (html[i] === '{') depth++;
      else if (html[i] === '}') {
        depth--;
        if (depth === 0) {
          end = i + 1;
          break;
        }
      }
    }
    const jsonStr = html.substring(start, end);
    console.log('ytInitialData length:', jsonStr.length);
    // Search for length or duration or time in this json
    const matches = [...jsonStr.matchAll(/"(\\d+:\\d+)"/g)];
    console.log('Time-like strings in ytInitialData:', matches.slice(0, 10).map(m => m[1]));
    const simpleTexts = [...jsonStr.matchAll(/"simpleText":"([^"]+)"/g)];
    const timeTexts = simpleTexts.filter(m => /\\d+:\\d+/.test(m[1])).map(m => m[1]);
    console.log('time-like simpleText:', timeTexts.slice(0, 10));
  }
}

async function start() {
  await testOembed();
  await testEmbed();
  await testInnertubeClients();
  checkInitialData();
}

start();
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/test-solutions.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test-solutions.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
