const net = require('net');

function checkPort(host, port, timeout = 3000) {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    socket.setTimeout(timeout);
    socket.on('connect', () => {
      socket.destroy();
      resolve({ port, status: 'OPEN' });
    });
    socket.on('timeout', () => {
      socket.destroy();
      resolve({ port, status: 'TIMEOUT' });
    });
    socket.on('error', (err) => {
      resolve({ port, status: err.code });
    });
    socket.connect(port, host);
  });
}

async function run() {
  console.log('=== Checking api.reviewsgateway.in (13.126.210.93) Ports ===');
  const ports = [80, 443, 3000, 5000, 8080];
  for (const p of ports) {
    const res = await checkPort('13.126.210.93', p);
    console.log(`Port ${p}: ${res.status}`);
  }

  console.log('\n=== Checking Our New VPS (65.20.77.112) Ports ===');
  for (const p of [80, 443, 3000, 3001]) {
    const res = await checkPort('65.20.77.112', p);
    console.log(`Port ${p}: ${res.status}`);
  }
}

run();
