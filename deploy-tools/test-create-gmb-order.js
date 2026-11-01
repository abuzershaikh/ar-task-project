const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 15000,
  });

  const payload = {
    serviceCode: 'GOOGLE_BUSINESS_REVIEW',
    quantity: 2,
    title: 'Google Business 5-Star Rating & Review Campaign (2 tasks)',
    description: 'Custom content campaign',
    autoApprove: false,
    reviewMode: 'manual',
    requirements: {
      autoApprove: false,
      targetUrl: 'https://maps.app.goo.gl/9yGZ7L6zXJ4aB1n67',
      topic: 'Best cafe and good ambiance',
      language: 'English',
      tone: 'natural',
      aiGeneratorEnabled: true,
      minWords: 10,
      maxWords: 30,
      sampleComments: [
        'Amazing coffee and peaceful ambiance. Highly recommended!',
        'Loved the service and friendly staff here. Great place to hang out!'
      ],
      appName: 'Cafe Delight Test',
      businessName: 'Cafe Delight Test',
      appIcon: 'https://maps.gstatic.com/tactile/pane/default_geocode-2x.png',
      packageId: null,
      unitPrice: 25.0
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

  // Wait 2 seconds for event emitter & task generation
  await new Promise(r => setTimeout(r, 2000));

  console.log('\n--- 2. Checking tasks in MySQL for Order ID:', orderId, '---');
  const tasksRes = await ssh.execCommand(
    `mysql task_platform -e "SELECT id, order_id, task_type, status, assigned_to, LEFT(requirements, 120) FROM tasks WHERE order_id='${orderId}';"`
  );
  console.log('Tasks in DB:\n', tasksRes.stdout);

  console.log('\n--- 3. Calling GET /api/v1/worker/tasks/available for test worker ---');
  const workerRes = await ssh.execCommand(
    `curl -s -H "x-user-email: test_worker_gmb_999@gmail.com" -H "x-user-id: worker_gmb_999" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available`
  );
  const workerData = JSON.parse(workerRes.stdout);
  console.log('Available tasks total count:', workerData.tasks?.length);
  const foundTask = (workerData.tasks || []).find(t => t.orderId === orderId);
  console.log('Found newly created GMB task in available tasks?:', Boolean(foundTask));
  if (foundTask) {
    console.log('Task Details:', JSON.stringify(foundTask, null, 2));
  } else {
    console.log('All available task IDs/types:');
    (workerData.tasks || []).forEach(t => console.log(` - [${t.taskType}] ID: ${t.id} Order: ${t.orderId}`));
  }

  ssh.dispose();
}

run().catch(console.error);
