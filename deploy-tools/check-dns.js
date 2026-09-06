const dns = require('dns');

dns.resolve4('www.reviewsgateway.in', (err, addresses) => {
  console.log('www.reviewsgateway.in:', err || addresses);
});
dns.resolve4('reviewsgateway.in', (err, addresses) => {
  console.log('reviewsgateway.in:', err || addresses);
});
