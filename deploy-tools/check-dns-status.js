const dns = require('dns').promises;

async function test() {
  const resolvers = [
    { name: 'System Default', resolver: null },
    { name: 'Google (8.8.8.8)', ip: '8.8.8.8' },
    { name: 'Cloudflare (1.1.1.1)', ip: '1.1.1.1' },
    { name: 'Bluehost NS1 (162.159.24.72)', ip: '162.159.24.72' },
    { name: 'Bluehost NS2 (162.159.25.143)', ip: '162.159.25.143' }
  ];

  for (const domain of ['swiftcommerce.in', 'www.swiftcommerce.in']) {
    console.log(`\n========================================`);
    console.log(`Domain: ${domain}`);
    console.log(`========================================`);
    for (const r of resolvers) {
      try {
        let res;
        if (r.ip) {
          const resObj = new dns.Resolver();
          resObj.setServers([r.ip]);
          res = await resObj.resolve4(domain);
        } else {
          res = await dns.resolve4(domain);
        }
        console.log(`[${r.name}] -> SUCCESS: ${res.join(', ')}`);
      } catch (err) {
        console.log(`[${r.name}] -> ERROR: ${err.code || err.message}`);
      }
    }
  }
}

test();
