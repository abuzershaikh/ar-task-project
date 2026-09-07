const dns = require('dns');

const resolver = new dns.Resolver();
// Use Cloudflare and Google to see public resolution
resolver.setServers(['1.1.1.1', '8.8.8.8']);

resolver.resolve4('reviewsgateway.in', (err, addresses) => {
  console.log('Public DNS reviewsgateway.in:', err ? err.message : addresses);
});

resolver.resolve4('www.reviewsgateway.in', (err, addresses) => {
  console.log('Public DNS www.reviewsgateway.in:', err ? err.message : addresses);
});

// Query Bluehost nameserver directly
const bluehostResolver = new dns.Resolver();
bluehostResolver.setServers(['162.159.24.72']); // ns1.bluehost.in

bluehostResolver.resolve4('reviewsgateway.in', (err, addresses) => {
  console.log('Bluehost NS1 reviewsgateway.in:', err ? err.message : addresses);
});

bluehostResolver.resolve4('www.reviewsgateway.in', (err, addresses) => {
  console.log('Bluehost NS1 www.reviewsgateway.in:', err ? err.message : addresses);
});
