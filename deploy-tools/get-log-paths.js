const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function getLogPaths() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    const res = await ssh.execCommand('pm2 jlist');
    const apps = JSON.parse(res.stdout);
    const taskApi = apps.find(a => a.name === 'task-engine-api');
    console.log('Task Engine API paths:');
    console.log('out_log:', taskApi.pm2_env.pm_out_log_path);
    console.log('err_log:', taskApi.pm2_env.pm_err_log_path);

    console.log('\n--- Error Log Tail ---');
    const errTail = await ssh.execCommand(`tail -n 50 "${taskApi.pm2_env.pm_err_log_path}"`);
    console.log(errTail.stdout);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

getLogPaths();
