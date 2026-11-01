const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const script = `
const { GoogleMapsMetadataService } = require('/opt/task-engine/dist/shared/services/google-maps-metadata.service.js');

async function test() {
  const service = new GoogleMapsMetadataService();
  const url = 'https://maps.app.goo.gl/8TsYLjAEEEpUYspq7?g_st=ac';
  console.log('Testing URL:', url);
  try {
    const res = await service.getBusinessMetadata(url);
    console.log('Result:', JSON.stringify(res, null, 2));
  } catch (err) {
    console.error('Error:', err);
  }
}
test();
`;

  await ssh.execCommand("cat << 'EOF' > /tmp/test_gmb.js\n" + script + "\nEOF");
  const res = await ssh.execCommand('node /tmp/test_gmb.js');
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

run().catch(console.error);
