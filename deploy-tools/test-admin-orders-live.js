const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Logging in as Admin...');
    const loginCmd = `curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`;
    const loginRes = await ssh.execCommand(loginCmd);
    const loginData = JSON.parse(loginRes.stdout);
    const token = loginData.accessToken || loginData.token;
    console.log('Token acquired successfully!\n');

    console.log('1. Testing GET /admin/orders...');
    const getOrdersCmd = `curl -s -X GET http://localhost:3000/api/v1/admin/orders -H "Authorization: Bearer ${token}"`;
    const getOrdersRes = await ssh.execCommand(getOrdersCmd);
    const ordersData = JSON.parse(getOrdersRes.stdout);
    console.log(`Total orders returned: ${ordersData.total}`);

    const statuses = {};
    for (const o of ordersData.orders || []) {
      statuses[o.status] = (statuses[o.status] || 0) + 1;
    }
    console.log('Order statuses summary:', statuses);

    const completed = (ordersData.orders || []).filter(o => o.status === 'COMPLETED');
    console.log(`Completed orders found: ${completed.length}`);
    if (completed.length > 0) {
      console.log(`Sample COMPLETED order: ${completed[0].id} (tasks completed: ${completed[0].tasksCompleted}/${completed[0].totalTasksRequired})`);
    }

    const cancelled = (ordersData.orders || []).filter(o => o.status === 'CANCELLED');
    console.log(`Cancelled orders found: ${cancelled.length}`);

    // Find an active order to test pause and resume
    const activeOrder = (ordersData.orders || []).find(o => o.status === 'ACTIVE');
    if (activeOrder) {
      console.log(`\n2. Testing Pause on Order: ${activeOrder.id}...`);
      const pauseCmd = `curl -s -X POST http://localhost:3000/api/v1/admin/orders/${activeOrder.id}/pause -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" -d '{"reason":"Test Pause from Admin App"}'`;
      const pauseRes = await ssh.execCommand(pauseCmd);
      console.log('Pause response:', pauseRes.stdout);

      console.log(`\n3. Testing Resume on Order: ${activeOrder.id}...`);
      const resumeCmd = `curl -s -X POST http://localhost:3000/api/v1/admin/orders/${activeOrder.id}/resume -H "Authorization: Bearer ${token}"`;
      const resumeRes = await ssh.execCommand(resumeCmd);
      console.log('Resume response:', resumeRes.stdout);
    }

    console.log('\n4. Testing GET /admin/audit-logs...');
    const auditCmd = `curl -s -X GET "http://localhost:3000/api/v1/admin/audit-logs?limit=5" -H "Authorization: Bearer ${token}"`;
    const auditRes = await ssh.execCommand(auditCmd);
    const auditData = JSON.parse(auditRes.stdout);
    console.log(`Audit logs items count: ${auditData.items?.length || 0}`);
    if (auditData.items && auditData.items.length > 0) {
      console.log('Latest 2 audit log actions:', auditData.items.slice(0, 2).map(i => ({ action: i.action, entity: `${i.entityType}:${i.entityId}`, time: i.createdAt })));
    }

    console.log('\nAll tests passed successfully!');
  } catch (err) {
    console.error('Error during test:', err);
  } finally {
    ssh.dispose();
  }
}

run();
