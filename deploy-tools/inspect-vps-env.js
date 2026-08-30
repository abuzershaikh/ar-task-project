const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspectVps() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== VPS .env ===');
    const envRes = await ssh.execCommand('cat /opt/task-engine/.env');
    console.log(envRes.stdout);

    console.log('\n=== Submissions in Database ===');
    const subs = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, task_id, worker_id, status, review_status, data, proofs, created_at FROM submissions LIMIT 10;"');
    console.log(subs.stdout || '(No submissions)');

    console.log('\n=== Uploaded Files in Database ===');
    const files = await ssh.execCommand('mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, original_name, file_name, file_path, mime_type, file_size, created_at FROM files LIMIT 10;"');
    console.log(files.stdout || '(No files)');

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

inspectVps();
