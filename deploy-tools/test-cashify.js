const { fetchPlayStoreMetadata } = require('./test-playstore-scrape');

async function testCashify() {
  const r = await fetchPlayStoreMetadata('com.reglobe.cashify');
  console.log('Cashify Metadata:\n', JSON.stringify(r, null, 2));
  process.exit(0);
}

testCashify();
