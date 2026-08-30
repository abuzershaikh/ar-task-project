const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkTaskSubmissions() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const res = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_id, worker_id, status, review_status, data, proofs FROM task_submissions;"');
    console.log('=== task_submissions in Database ===');
    console.log(res.stdout);
  } catch (e) {
    console.error(e);
  } finally {
    ssh.dispose();
  }
}

checkTaskSubmissions();
