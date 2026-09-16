const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 60000,
    });

    const taskId = 'e8937ea1-e8a3-47e4-b64e-775d595a0661';
    const subId = '27c596a6-228d-45aa-a891-8fa9861b3328';

    console.log('=== 1. TASK DETAILS ===');
    const tRes = await ssh.execCommand(`mysql -e 'SELECT * FROM task_platform.tasks WHERE id = "${taskId}";'`);
    console.log(tRes.stdout);

    console.log('=== 2. SUBMISSION DETAILS ===');
    const sRes = await ssh.execCommand(`mysql -e 'SELECT * FROM task_platform.task_submissions WHERE id = "${subId}";'`);
    console.log(sRes.stdout);

    console.log('=== 3. WHO SUBMITTED THIS TASK? ===');
    const wRes = await ssh.execCommand(`mysql -e 'SELECT s.id, s.worker_id, u.id as user_table_id, u.email, u.role, s.reward, s.status, s.created_at, s.reviewed_at FROM task_platform.task_submissions s LEFT JOIN task_platform.users u ON s.worker_id = u.id WHERE s.id = "${subId}";'`);
    console.log(wRes.stdout);

    console.log('=== 4. WORKERS TABLE (WORKER PROFILE) ===');
    const wrkRes = await ssh.execCommand(`mysql -e 'SELECT * FROM task_platform.workers WHERE user_id = "MYDovhuR8zcbLlvazaAG8qdWLXr1" OR id = "MYDovhuR8zcbLlvazaAG8qdWLXr1";'`);
    console.log(wrkRes.stdout);

    console.log('=== 5. ALL SUBMISSIONS BY WORKER (IF ANY) ===');
    const allSubs = await ssh.execCommand(`mysql -e 'SELECT * FROM task_platform.task_submissions WHERE worker_id = "MYDovhuR8zcbLlvazaAG8qdWLXr1" ORDER BY created_at DESC;'`);
    console.log(allSubs.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
