const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function test() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 60000,
  });

  const res = await ssh.execCommand(`node -e "
    const jwt = require('jsonwebtoken');
    require('dotenv').config({ path: '/opt/task-engine/.env' });
    const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_1234567890';
    const token = jwt.sign({ sub: 'MYDovhuR8zcbLlvazaAG8qdWLXr1', email: 'sonathe333@gmail.com' }, secret, { expiresIn: '1h' });
    fetch('http://127.0.0.1:3000/api/v1/worker/tasks/available', {
      headers: {
        'x-user-email': 'sonathe333@gmail.com',
        'x-user-id': 'MYDovhuR8zcbLlvazaAG8qdWLXr1',
        'x-user-role': 'WORKER'
      }
    }).then(async r => {
      console.log('Status without Token:', r.status);
      console.log('Body without Token:', await r.text());
    }).catch(e => console.error(e));
  "`, { cwd: '/opt/task-engine' });

  console.log('STDOUT:', res.stdout);
  if (res.stderr) console.error('STDERR:', res.stderr);
  ssh.dispose();
}

test();
