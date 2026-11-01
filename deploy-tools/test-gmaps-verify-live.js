const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  // Unique target URL so worker exclusions never hit it
  const uniqueId = Date.now();
  const testMapsUrl = `https://www.google.com/maps/place/Test+Cafe+${uniqueId}/@19.0760,72.8777,15z`;

  const payload = {
    serviceCode: 'GOOGLE_BUSINESS_REVIEW',
    quantity: 1,
    title: `Google Maps Review Test ${uniqueId}`,
    description: 'Verifying Google Maps Task creation and worker feed',
    autoApprove: false,
    reviewMode: 'manual',
    requirements: {
      targetUrl: testMapsUrl,
      topic: 'Great coffee and wonderful service',
      language: 'English',
      sampleComments: ['Best coffee shop in town! Clean and prompt service.'],
      unitPrice: 25.0,
      // intentionally omit businessName to verify auto-detection / fallback handling
    },
    timeToAcceptHours: 24,
    timeToCompleteHours: 48
  };

  console.log('--- 1. Calling POST /api/v1/buyer/orders ---');
  const postCmd = `curl -s -X POST http://127.0.0.1:3000/api/v1/buyer/orders ` +
    `-H "Content-Type: application/json" ` +
    `-H "x-user-id: H2G6uuWWCFaEGFdtahczIymFt363" ` +
    `-H "x-user-email: androidgeniuspro@gmail.com" ` +
    `-H "x-user-role: BUYER" ` +
    `-d '${JSON.stringify(payload)}'`;

  const orderRes = await ssh.execCommand(postCmd);
  console.log('Create Order Response:\n', orderRes.stdout);
  let orderData;
  try {
    orderData = JSON.parse(orderRes.stdout);
  } catch (e) {
    console.error('Failed to parse order response:', e);
    ssh.dispose();
    return;
  }

  const orderId = orderData?.order?.id;
  console.log('Created Order ID:', orderId);

  // Wait 2.5s for event listener to create task
  await new Promise(r => setTimeout(r, 2500));

  console.log('\n--- 2. Checking tasks in MySQL for Order ID:', orderId, '---');
  const tasksRes = await ssh.execCommand(
    `mysql task_platform -e "SELECT id, order_id, platform, task_type, status, assigned_to, LEFT(requirements, 250) FROM tasks WHERE order_id='${orderId}';"`
  );
  console.log('Tasks in DB:\n', tasksRes.stdout);

  console.log('\n--- 3. Calling GET /api/v1/worker/tasks/available for fresh test worker ---');
  const workerRes = await ssh.execCommand(
    `curl -s -H "x-user-email: test_worker_${uniqueId}@gmail.com" -H "x-user-id: worker_${uniqueId}" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available`
  );
  const workerData = JSON.parse(workerRes.stdout);
  console.log('Available tasks total count:', workerData.tasks?.length);
  const foundTask = (workerData.tasks || []).find(t => t.orderId === orderId);
  console.log('Found newly created GMB task in available tasks?:', Boolean(foundTask));
  if (foundTask) {
    console.log('Task Details:', {
      id: foundTask.id,
      platform: foundTask.platform,
      taskType: foundTask.taskType,
      title: foundTask.title,
      businessName: foundTask.requirements?.businessName,
      targetUrl: foundTask.requirements?.targetUrl,
    });
  } else {
    console.log('Available tasks list:');
    (workerData.tasks || []).slice(0, 5).forEach(t => console.log(` - [${t.taskType}] [${t.platform}] ID: ${t.id} Order: ${t.orderId}`));
  }

  ssh.dispose();
}

run().catch(console.error);
