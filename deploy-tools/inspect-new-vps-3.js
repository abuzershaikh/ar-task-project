const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function inspect3() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
      readyTimeout: 30000,
    });

    async function run(title, cmd) {
      console.log(`=============================`);
      console.log(`>>> ${title}`);
      console.log(`Command: ${cmd}`);
      console.log(`=============================`);
      const res = await ssh.execCommand(cmd);
      if (res.stdout) console.log(res.stdout);
      if (res.stderr) console.error('STDERR:', res.stderr);
      console.log('');
    }

    await run('OS RELEASE DETAILS', 'cat /etc/redhat-release || cat /etc/os-release');
    await run('WHAT IS IN /opt/form_engine', 'ls -la /opt/form_engine 2>/dev/null');
    await run('CHECK PORT 3001 / 3000 / 7708', 'ss -tulpn | grep -E "3000|3001|3002|7708|80|443|3306|6379"');
    await run('TEST ACCESSING PORT 3001', 'curl -I http://127.0.0.1:3001/health 2>&1');
    await run('CHECK PM2 ALL INCLUDING STOPPED', 'pm2 list --all');

  } catch (err) {
    console.error('Inspection failed:', err);
  } finally {
    ssh.dispose();
  }
}

inspect3();
