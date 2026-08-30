const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkSubmissions() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_id, worker_id, status, review_status, data, proofs FROM submissions;"');
    console.log('=== Submissions in Database ===');
    console.log(res.stdout);

    const taskRes = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_type, status, assigned_to, metadata FROM tasks;"');
    console.log('=== Tasks in Database ===');
    console.log(taskRes.stdout);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

checkSubmissions();
