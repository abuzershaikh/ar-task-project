const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const code = await ssh.execCommand('sed -n "50,85p" /opt/task-engine/dist/main.js');
    console.log('--- /opt/task-engine/dist/main.js lines 50-85 ---');
    console.log(code.stdout);

    const tsCode = await ssh.execCommand('sed -n "30,55p" /opt/task-engine/apps/api/main.ts');
    console.log('--- /opt/task-engine/apps/api/main.ts lines 30-55 ---');
    console.log(tsCode.stdout);
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
