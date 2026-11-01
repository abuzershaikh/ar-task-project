const { extractTaskIdentity, resolveShortUrl } = require('/opt/task-engine/dist/shared/common/utils/task-identity.util');

const urls = [
  'https://maps.app.goo.gl/9yGZ7L6zXJ4aB1n67',
  'https://goo.gl/maps/xyz123',
  'https://www.google.com/maps/place/Taj+Mahal/@27.1751448,78.0421422,17z',
  'https://www.google.com/search?kgmid=/g/11y5cbvjh_&hl=en-IN&q=Studio+Folio+Films',
  'https://share.google/WkRHZB34ySWejYpCl',
  'https://www.google.com/maps?cid=1028472918237',
  'https://maps.google.com/?q=Taj+Mahal'
];

for (const u of urls) {
  const identity = extractTaskIdentity({ requirements: { targetUrl: u } });
  console.log('URL:', u);
  console.log(' -> normalizedUrl:', identity.normalizedUrl);
  console.log(' -> entityKey:', identity.entityKey);
}
