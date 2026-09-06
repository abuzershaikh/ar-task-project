const net = require('net');

function queryWhois(server, domain) {
  return new Promise((resolve, reject) => {
    const client = net.createConnection({ host: server, port: 43 }, () => {
      client.write(domain + '\r\n');
    });

    let data = '';
    client.on('data', (chunk) => {
      data += chunk.toString();
    });

    client.on('end', () => {
      resolve(data);
    });

    client.on('error', (err) => {
      reject(err);
    });

    client.setTimeout(10000, () => {
      client.destroy();
      resolve(data || 'Timeout');
    });
  });
}

async function run() {
  const servers = ['whois.registry.in', 'whois.nixi.in'];
  for (const s of servers) {
    console.log(`\n========================================`);
    console.log(`Querying ${s} for swiftcommerce.in`);
    console.log(`========================================`);
    try {
      const res = await queryWhois(s, 'swiftcommerce.in');
      console.log(res);
    } catch (e) {
      console.log('Error:', e.message);
    }
  }
}

run();
