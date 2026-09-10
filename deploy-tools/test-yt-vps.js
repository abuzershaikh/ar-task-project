const { NodeSSH } = require('node-ssh');
const fs = require('fs');
const path = require('path');
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

async function test(videoId) {
  return new Promise((resolve) => {
    const url = 'https://www.youtube.com/watch?v=' + videoId;
    const options = {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Cookie': 'CONSENT=YES+cb.20210328-17-p0.en+FX+410; SOCS=CAESEwgDEgk0ODE3Nzk3MjQaAmVuIAEaBgiA_LyaBg',
      },
      timeout: 10000,
    };

    console.log('Fetching:', url);
    https.get(url, options, (res) => {
      console.log('Status code:', res.statusCode);
      if (res.headers.location) console.log('Redirect:', res.headers.location);
      let html = '';
      res.on('data', chunk => {
        html += chunk;
      });
      res.on('end', () => {
        console.log('Total HTML length:', html.length);
        
        const m1 = html.match(/"lengthSeconds":"(\\d+)"/);
        console.log('match "lengthSeconds":', m1 ? m1[1] : 'null');

        const m2 = html.match(/itemprop="duration" content="([^"]+)"/);
        console.log('match itemprop="duration":', m2 ? m2[1] : 'null');

        const m3 = html.match(/"approxDurationMs":"(\\d+)"/);
        console.log('match "approxDurationMs":', m3 ? m3[1] : 'null');

        const m4 = html.match(/<meta property="og:title" content="([^"]+)"/);
        console.log('match og:title:', m4 ? m4[1] : 'null');

        const m5 = html.match(/<title>([^<]+)<\\/title>/);
        console.log('match <title>:', m5 ? m5[1] : 'null');

        console.log('Includes consent redirect / block:', html.includes('consent.youtube.com') || html.includes('before you continue'));
        
        // Also test Youtube Innertube player API
        testInnertube(videoId).then(resolve);
      });
    }).on('error', e => {
      console.error('Error:', e.message);
      resolve();
    });
  });
}

async function testInnertube(videoId) {
  return new Promise((resolve) => {
    console.log('\\n--- Testing YouTube Innertube Android / WEB Player API ---');
    const postData = JSON.stringify({
      context: {
        client: {
          clientName: 'ANDROID',
          clientVersion: '19.09.37',
          androidSdkVersion: 30,
          hl: 'en',
          gl: 'US'
        }
      },
      videoId: videoId
    });

    const req = https.request({
      hostname: 'www.youtube.com',
      port: 443,
      path: '/youtubei/v1/player',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'User-Agent': 'com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip'
      },
      timeout: 8000
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        console.log('Innertube status:', res.statusCode);
        try {
          const json = JSON.parse(body);
          console.log('Innertube playabilityStatus:', json.playabilityStatus?.status);
          const videoDetails = json.videoDetails;
          if (videoDetails) {
            console.log('Innertube videoDetails:', {
              title: videoDetails.title,
              lengthSeconds: videoDetails.lengthSeconds,
              author: videoDetails.author,
              channelId: videoDetails.channelId,
              isLiveContent: videoDetails.isLiveContent
            });
          } else {
            console.log('Innertube no videoDetails, keys:', Object.keys(json));
          }
        } catch(e) {
          console.error('Innertube JSON parse error:', e.message);
        }
        resolve();
      });
    });

    req.on('error', e => {
      console.error('Innertube error:', e.message);
      resolve();
    });
    req.write(postData);
    req.end();
  });
}

test('sViKU1eitc4');
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/test-yt.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test-yt.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
