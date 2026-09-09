const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testSql() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    
    // Test heredoc execution
    const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform << 'EOF'
SET FOREIGN_KEY_CHECKS = 0;
SELECT count(*) FROM tasks;
EOF
`);
    console.log('STDOUT:', res.stdout);
    console.log('STDERR:', res.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

testSql();
