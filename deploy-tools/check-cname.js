const dns = require('dns');

const r = new dns.Resolver();
r.setServers(['8.8.8.8']); // Google DNS

r.resolveCname('www.reviewsgateway.in', (err, addresses) => {
  console.log('Google DNS CNAME www.reviewsgateway.in:', err ? err.message : addresses);
});

r.resolve4('www.reviewsgateway.in', (err, addresses) => {
  console.log('Google DNS A www.reviewsgateway.in:', err ? err.message : addresses);
});

r.resolve4('reviewsgateway.in', (err, addresses) => {
  console.log('Google DNS A reviewsgateway.in:', err ? err.message : addresses);
});

const rBh = new dns.Resolver();
rBh.setServers(['162.159.24.72']); // ns1.bluehost.in

rBh.resolveCname('www.reviewsgateway.in', (err, addresses) => {
  console.log('Bluehost NS1 CNAME www.reviewsgateway.in:', err ? err.message : addresses);
});

rBh.resolve4('www.reviewsgateway.in', (err, addresses) => {
  console.log('Bluehost NS1 A www.reviewsgateway.in:', err ? err.message : addresses);
});

rBh.resolve4('reviewsgateway.in', (err, addresses) => {
  console.log('Bluehost NS1 A reviewsgateway.in:', err ? err.message : addresses);
});
