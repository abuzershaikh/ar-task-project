const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function checkBuyerWallets() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('=== Checking all buyer wallets and user accounts on VPS ===');
    const res = await ssh.execCommand(`node -e "
      const { DataSource } = require('typeorm');
      const ormConfig = require('./dist/shared/database/ormconfig').default || require('./dist/shared/database/ormconfig');
      const ds = new DataSource(ormConfig);
      (async () => {
        await ds.initialize();
        const users = await ds.query('SELECT id, email, role, full_name FROM users WHERE role=\\'BUYER\\' OR role=\\'SUPER_ADMIN\\'');
        console.log('Buyers / Super Admins:', users);
        const wallets = await ds.query('SELECT * FROM wallets');
        console.log('All Wallets in DB:', wallets);
        await ds.destroy();
      })();
    "`, { cwd: '/opt/task-engine' });

    console.log(res.stdout);
    if (res.stderr) console.error('STDERR:', res.stderr);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

checkBuyerWallets();
