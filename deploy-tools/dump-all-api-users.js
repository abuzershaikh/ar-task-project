const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });
    
    console.log('--- ALL WORKERS FROM API ---');
    const w = await ssh.execCommand('curl -s -H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: SUPER_ADMIN" http://127.0.0.1:3000/api/v1/admin/workers');
    const data = JSON.parse(w.stdout);
    console.log('API Worker Count:', data.workers ? data.workers.length : 0);
    if (data.workers) {
      data.workers.forEach((item, index) => {
        console.log(`${index + 1}. Name: "${item.name}" | Email: "${item.email}" | Role: "${item.status}" | ID: ${item.id}`);
      });
    }

    console.log('\n--- ALL BUYERS FROM API ---');
    const b = await ssh.execCommand('curl -s -H "x-user-email: admin@taskpost.com" -H "x-user-id: 102f44e4-a79a-4efd-88c8-b32927bd7ea7" -H "x-user-role: SUPER_ADMIN" http://127.0.0.1:3000/api/v1/admin/buyers');
    const dataB = JSON.parse(b.stdout);
    console.log('API Buyer Count:', dataB.buyers ? dataB.buyers.length : 0);
    if (dataB.buyers) {
      dataB.buyers.forEach((item, index) => {
        console.log(`${index + 1}. Name: "${item.name}" | Email: "${item.email}" | Status: "${item.status}" | ID: ${item.id}`);
      });
    }

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

run();
