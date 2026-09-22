const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkCatalog() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== SERVICE CATALOG ===');
    const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, is_active FROM service_catalog;"');
    console.log(res.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkCatalog();
