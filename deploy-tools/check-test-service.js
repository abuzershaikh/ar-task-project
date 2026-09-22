const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkTestService() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== TEST SERVICE IN SERVICE_CATALOG ===');
    const res1 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM service_catalog WHERE code LIKE \'%TEST%\' OR id = \'5b586982-a573-41ad-919d-6da35d39c161\';"');
    console.log(res1.stdout);

    console.log('=== PRICING TIERS FOR TEST SERVICE ===');
    const res2 = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT * FROM service_pricing WHERE service_id = \'5b586982-a573-41ad-919d-6da35d39c161\';"');
    console.log(res2.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkTestService();
