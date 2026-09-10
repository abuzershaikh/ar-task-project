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
const html = fs.readFileSync('/tmp/yt.html', 'utf8');

// 1. Search microformatDataRenderer
const mfIdx = html.indexOf('microformatDataRenderer');
if (mfIdx !== -1) {
  console.log('microformatDataRenderer snippet:');
  console.log(html.substring(mfIdx - 50, mfIdx + 500));
}

// 2. Search ytInitialPlayerResponse
const prIdx = html.indexOf('ytInitialPlayerResponse');
console.log('ytInitialPlayerResponse index:', prIdx);
if (prIdx !== -1) {
  console.log(html.substring(prIdx, prIdx + 300));
}

// 3. Search ytInitialData
const dataIdx = html.indexOf('ytInitialData =');
console.log('ytInitialData index:', dataIdx);
if (dataIdx !== -1) {
  console.log(html.substring(dataIdx, dataIdx + 300));
}

// 4. Look for video length / duration anywhere in json objects
const regexes = [
  /lengthSeconds/g,
  /approxDurationMs/g,
  /durationSeconds/g,
  /simpleText/g,
  /accessibility/g
];

regexes.forEach(r => {
  const matches = [...html.matchAll(r)];
  console.log(r.source, 'count:', matches.length);
  if (matches.length > 0) {
    const idx = matches[0].index;
    console.log('  sample:', html.substring(Math.max(0, idx - 40), idx + 80).replace(/\\n/g, ' '));
  }
});
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/analyze-yt.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/analyze-yt.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
