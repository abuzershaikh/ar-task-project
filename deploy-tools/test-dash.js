const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
  const script = `
    const jwt = require('jsonwebtoken');
    require('dotenv').config({ path: '/opt/task-engine/.env' });
    const secret = process.env.JWT_SECRET || 'super-secret-jwt-key';
    const token = jwt.sign({ sub: 'MYDovhuR8zcbLlvazaAG8qdWLXr1', email: 'sonathe333@gmail.com', role: 'BUYER' }, secret, { expiresIn: '1h' });
    fetch('http://127.0.0.1:3000/api/v1/buyer/dashboard', { headers: { Authorization: 'Bearer ' + token } })
      .then(r => r.json())
      .then(d => console.log('DASHBOARD RESULT:', JSON.stringify(d, null, 2)))
      .catch(e => console.error(e));
  `;
  const res = await ssh.execCommand(`node -e "${script.replace(/\n/g, ' ')}"`, { cwd: '/opt/task-engine' });
  console.log(res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}
run();
