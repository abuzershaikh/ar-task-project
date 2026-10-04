const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const loginRes = await ssh.execCommand(`curl -s -X POST http://127.0.0.1:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
  const loginData = JSON.parse(loginRes.stdout);
  const token = loginData.data?.accessToken;

  console.log('\n--- 1. Testing GET /api/v1/admin/services ---');
  const adminRes = await ssh.execCommand(`curl -s -X GET http://127.0.0.1:3000/api/v1/admin/services -H "Authorization: Bearer ${token}"`);
  try {
    const adminJson = JSON.parse(adminRes.stdout);
    const services = adminJson.services || adminJson.data || adminJson;
    console.log(`Admin services count: ${services.length}`);
    services.forEach(s => {
      const item = s.service || s;
      console.log(`[${item.category}] ${item.code} -> "${item.name}"`);
    });
  } catch (e) {
    console.error('Admin err:', e.message);
  }

  console.log('\n--- 2. Testing GET /api/v1/buyer/services ---');
  // First let's check buyer endpoint with admin or buyer role:
  // In NestJS, @Roles(UserRole.BUYER) checks if user has BUYER role or SUPER_ADMIN
  const buyerRes = await ssh.execCommand(`curl -s -X GET http://127.0.0.1:3000/api/v1/buyer/services -H "Authorization: Bearer ${token}"`);
  try {
    const json = JSON.parse(buyerRes.stdout);
    const services = json.services || json.data || (Array.isArray(json) ? json : []);
    console.log(`Buyer services count: ${services.length}`);
    services.forEach(s => {
      console.log(`[${s.category}] ${s.code} -> "${s.name}" (Type: ${s.serviceType})`);
    });
  } catch (e) {
    console.log('Buyer response:', buyerRes.stdout);
  }

  ssh.dispose();
}

main().catch(console.error);
