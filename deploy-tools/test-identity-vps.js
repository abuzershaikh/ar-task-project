const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const script = `
const { resolveShortUrl, extractTaskIdentity } = require('/opt/task-engine/dist/shared/common/utils/task-identity.util.js');

async function test() {
  const url = 'https://maps.app.goo.gl/8TsYLjAEEEpUYspq7?g_st=ac';
  console.log('Resolving short URL...');
  const resolved = await resolveShortUrl(url, 4000);
  console.log('Resolved:', resolved);

  const identity = extractTaskIdentity({
    targetUrl: resolved,
    requirements: { targetUrl: resolved, businessName: 'Surat Marriott Hotel', appName: 'Surat Marriott Hotel' },
    metadata: { targetUrl: resolved, businessName: 'Surat Marriott Hotel', appName: 'Surat Marriott Hotel' },
  });
  console.log('Identity:', JSON.stringify(identity, null, 2));
}
test().catch(console.error);
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/test_identity.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/test_identity.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
