const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkLogForError() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('=== GREP FOR Unknown review mode ===');
  const res = await ssh.execCommand(`grep -i "Unknown review mode" /root/.pm2/logs/*.log`);
  console.log(res.stdout || res.stderr);

  console.log('=== GREP FOR 500 IN OUT LOG WITH CONTEXT ===');
  const res2 = await ssh.execCommand(`grep -B 2 -A 10 "POST /api/v1/worker/tasks/df50e363-aa85-47e3-8198-3b8143c5bbf6/submit 500" /root/.pm2/logs/task-engine-api-out-2.log`);
  console.log(res2.stdout || res2.stderr);

  ssh.dispose();
}

checkLogForError();
