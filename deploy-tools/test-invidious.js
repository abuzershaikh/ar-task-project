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

function fetchJson(url) {
  return new Promise((resolve) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 4000 }, (res) => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => {
        try { resolve(JSON.parse(b)); } catch(e) { resolve(null); }
      });
    }).on('error', () => resolve(null))
      .on('timeout', () => resolve(null));
  });
}

async function test() {
  const invidious = await fetchJson('https://inv.tux.pizza/api/v1/videos/jNQXAC9IVRw');
  console.log('Invidious inv.tux.pizza duration:', invidious?.lengthSeconds, invidious?.title);

  const piped = await fetchJson('https://pipedapi.kavin.rocks/streams/jNQXAC9IVRw');
  console.log('Piped duration:', piped?.duration, piped?.title);
}

test();
`;

  await ssh.execCommand(`cat << 'EOF' > /tmp/test-invidious.js\n${scriptContent}\nEOF`);
  const res = await ssh.execCommand('node /tmp/test-invidious.js');
  console.log(res.stdout);
  console.error(res.stderr);

  ssh.dispose();
}

run();
