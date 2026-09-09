const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });
  
  const testScript = `
const https = require('https');
const url = 'https://play.google.com/store/apps/details?id=in.swiggy.android.instamart&hl=en&gl=US';
https.get(url, {
  headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
  }
}, (res) => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => {
    const titleMatch = data.match(/<meta\\s+property=["']og:title["']\\s+content=["'](.*?)["']/i);
    const iconMatch = data.match(/<meta\\s+property=["']og:image["']\\s+content=["'](.*?)["']/i) ||
                      data.match(/<img[^>]+src=["'](https:\\/\\/play-lh\\.googleusercontent\\.com\\/[^"']+)["'][^>]*alt=["']Icon image["']/i);
    console.log('TITLE:', titleMatch ? titleMatch[1] : 'null');
    console.log('ICON:', iconMatch ? iconMatch[1] : 'null');
  });
});
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/test-playstore.js\n" + testScript + "\nEOF");
  const res = await ssh.execCommand("node /tmp/test-playstore.js");
  console.log('STDOUT:', res.stdout);
  console.log('STDERR:', res.stderr);
  ssh.dispose();
}
main().catch(console.error);
