const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectAudio() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const services = await ssh.execCommand("mysql -e 'SELECT id, code, name, audio_guide_url FROM task_platform.service_catalog;'");
  console.log('=== SERVICE CATALOG ===');
  console.log(services.stdout);
  process.exit(0);
}

inspectAudio().catch(e => { console.error(e); process.exit(1); });
