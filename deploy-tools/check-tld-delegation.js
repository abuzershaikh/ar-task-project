const dns = require('dns').promises;

async function checkTld() {
  console.log('Finding .in nameservers...');
  try {
    const inNs = await dns.resolveNs('in');
    console.log('.in nameservers:', inNs);

    for (const ns of inNs) {
      console.log(`\nQuerying .in TLD NS: ${ns}`);
      try {
        const ips = await dns.resolve4(ns);
        const tldResolver = new dns.Resolver();
        tldResolver.setServers([ips[0]]);
        const subNs = await tldResolver.resolveNs('swiftcommerce.in');
        console.log(`Delegation NS for swiftcommerce.in at ${ns}:`, subNs);
      } catch (err) {
        console.log(`Error querying ${ns}: ${err.code || err.message}`);
      }
    }
  } catch (e) {
    console.log('Error resolving in NS:', e);
  }
}

checkTld();
