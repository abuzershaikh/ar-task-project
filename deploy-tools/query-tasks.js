const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });
    const env = await ssh.execCommand('grep -i DB /opt/ar-task-engine/.env || grep -i DB /opt/*/.env || cat /root/.my.cnf');
    console.log('ENV:', env.stdout);
    const r = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, service_type, is_active FROM service_catalog;"');
    console.log(r.stdout);
    if (r.stderr) console.error(r.stderr);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}
main();
