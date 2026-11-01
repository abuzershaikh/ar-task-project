const { GoogleMapsMetadataService } = require('../Task engine/shared/services/google-maps-metadata.service.js');

async function test() {
  const service = new GoogleMapsMetadataService();
  const url = 'https://maps.app.goo.gl/8TsYLjAEEEpUYspq7?g_st=ac';
  console.log('Testing getBusinessMetadata...');
  const res = await service.getBusinessMetadata(url);
  console.log('Result:', JSON.stringify(res, null, 2));
}

test().catch(console.error);
