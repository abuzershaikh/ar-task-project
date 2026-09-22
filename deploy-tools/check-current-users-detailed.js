const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkCurrentData() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== ALL USERS IN USERS TABLE ===');
    const usersRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, full_name, phone_number, role, status, created_at FROM users;"');
    console.log(usersRes.stdout);

    console.log('=== ALL WORKERS IN WORKERS TABLE ===');
    const workersRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, user_id, display_name, phone_number, kyc_status, onboarding_status, created_at FROM workers;"');
    console.log(workersRes.stdout);

    console.log('=== ANY BUYER RECORDS OR ROLES? ===');
    const buyersRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, email, full_name, role FROM users WHERE role = \'BUYER\';"');
    console.log(buyersRes.stdout);

    console.log('=== ANY ORDERS? ===');
    const ordersRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT count(*) FROM orders;"');
    console.log(ordersRes.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkCurrentData();
