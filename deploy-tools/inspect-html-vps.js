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
const fs = require('fs');

const videoId = 'sViKU1eitc4';
const url = 'https://www.youtube.com/watch?v=' + videoId;

const options = {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  },
  timeout: 10000,
};

https.get(url, options, (res) => {
  let html = '';
  res.on('data', chunk => html += chunk);
  res.on('end', () => {
    fs.writeFileSync('/tmp/yt.html', html);
    console.log('Saved /tmp/yt.html, length:', html.length);

    // Search for keywords
    const keywords = ['length', 'duration', 'playerResponse', 'videoDetails', 'approxDuration', 'pt', 'PT'];
    for (const kw of keywords) {
      let idx = 0;
      let count = 0;
      while ((idx = html.indexOf(kw, idx)) !== -1 && count < 5) {
        const snippet = html.substring(Math.max(0, idx - 40), Math.min(html.length, idx + 80));
        console.log(\`Found "\${kw}": \`, snippet.replace(/\\n/g, ' '));
        idx += kw.length;
        count++;
      }
    }
  });
});
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/inspect-html.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/inspect-html.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
