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

const prIdx = html.indexOf('ytInitialPlayerResponse =');
if (prIdx !== -1) {
  const start = html.indexOf('{', prIdx);
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
  console.log('Found ytInitialPlayerResponse length:', jsonStr.length);
  try {
    const data = JSON.parse(jsonStr);
    console.log('Keys in ytInitialPlayerResponse:', Object.keys(data));
    console.log('playabilityStatus:', data.playabilityStatus);
    console.log('videoDetails:', data.videoDetails);
    console.log('microformat:', data.microformat);
  } catch(e) {
    console.log('JSON parse error:', e.message);
  }
}
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/check-player-response.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/check-player-response.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
