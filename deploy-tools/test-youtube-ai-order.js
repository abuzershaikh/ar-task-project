const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function runE2ETest() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const testScript = `
const jwt = require('jsonwebtoken');
const http = require('http');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_key_change_in_prod';
const buyerId = 'd0797d56-e7e4-47a2-9051-0d95f4f89e2a';

// Sign token
const token = jwt.sign(
  { sub: buyerId, id: buyerId, email: 'buyer_5921@test.com', role: 'BUYER' },
  JWT_SECRET,
  { expiresIn: '1d' }
);

console.log('Generated Buyer JWT Token successfully!');

// Make order request
const payload = JSON.stringify({
  serviceCode: 'YOUTUBE_COMMENT',
  quantity: 5,
  title: 'Real Estate Luxury Walkthrough Campaign',
  description: 'AI Generated comments for apartment tour',
  requirements: {
    targetUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    topic: 'Luxury Apartment Walkthrough & Architecture',
    language: 'English',
    tone: 'enthusiastic',
    aiGeneratorEnabled: true
  },
  timeToAcceptHours: 24,
  timeToCompleteHours: 48
});

const req = http.request({
  hostname: '127.0.0.1',
  port: 3000,
  path: '/api/v1/buyer/orders',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token,
    'Content-Length': Buffer.byteLength(payload)
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Order API Response:', data);
  });
});

req.on('error', (e) => console.error('Request Error:', e));
req.write(payload);
req.end();
`;

    await ssh.execCommand(`cat << 'EOF' > /opt/task-engine/run_test.js\n${testScript}\nEOF`);
    const runRes = await ssh.execCommand('node -r dotenv/config /opt/task-engine/run_test.js', { cwd: '/opt/task-engine' });
    console.log('Order Execution Result:\n', runRes.stdout);
    if (runRes.stderr) console.error('Stderr:', runRes.stderr);

    await new Promise(r => setTimeout(r, 2500));

    // Check order_units in DB
    const units = await ssh.execCommand(
      `mysql -e "SELECT id, order_id, unit_number, generated_content, status FROM task_platform.order_units ORDER BY created_at DESC LIMIT 5;"`
    );
    console.log('\n=== GENERATED ORDER UNITS IN MYSQL ===\n', units.stdout);

    // Check worker tasks in DB
    const tasks = await ssh.execCommand(
      `mysql -e "SELECT id, task_type, requirements, reward_amount, status FROM task_platform.tasks ORDER BY created_at DESC LIMIT 5;"`
    );
    console.log('\n=== GENERATED WORKER TASKS IN MYSQL ===\n', tasks.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

runE2ETest();
