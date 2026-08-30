const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function diagnoseApproveError() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('=== Checking task 1d9f55b7-6b5f-404e-a649-218100523eaa and its submission in MySQL ===');
    const query = `mysql -u root -p'G8u$RW{5m46buXgw' -e "USE task_platform; SELECT id, order_id, campaign_id, status, assigned_to FROM tasks WHERE id='1d9f55b7-6b5f-404e-a649-218100523eaa'; SELECT id, task_id, worker_id, status, review_status FROM task_submissions WHERE task_id='1d9f55b7-6b5f-404e-a649-218100523eaa';"`;
    const res = await ssh.execCommand(query);
    console.log(res.stdout);
    if (res.stderr) console.error(res.stderr);

    console.log('=== Testing direct call / log in NestJS ===');
    const logs = await ssh.execCommand('grep -C 5 "Approving task 1d9f55b7" /root/.pm2/logs/task-engine-api-error.log /root/.pm2/logs/task-engine-api-out.log');
    console.log(logs.stdout);
    if (logs.stderr) console.error(logs.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

diagnoseApproveError();
