const dns = require('dns').promises;

async function check() {
  console.log('=== Checking reviewsgateway.in NS ===');
  try {
    const ns = await dns.resolveNs('reviewsgateway.in');
    console.log('NS records:', ns);
  } catch (e) {
    console.log('Error NS:', e.code || e.message);
  }

  console.log('\n=== Checking reviewsgateway.in A record ===');
  try {
    const a = await dns.resolve4('reviewsgateway.in');
    console.log('A records:', a);
  } catch (e) {
    console.log('Error A:', e.code || e.message);
  }

  console.log('\n=== Checking www.reviewsgateway.in A record ===');
  try {
    const a = await dns.resolve4('www.reviewsgateway.in');
    console.log('www A records:', a);
  } catch (e) {
    console.log('Error www A:', e.code || e.message);
  }
}

check();
