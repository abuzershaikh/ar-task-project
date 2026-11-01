const { GoogleMapsMetadataService } = require('/opt/task-engine/dist/shared/services/google-maps-metadata.service');

async function test() {
  const service = new GoogleMapsMetadataService();
  const testLinks = [
    'https://maps.app.goo.gl/uXpD8b9oHk2nNxv78',
    'https://maps.google.com/?q=Taj+Mahal',
    'https://www.google.com/search?kgmid=/g/11y5cbvjh_&hl=en-IN&q=Studio+Folio+Films'
  ];

  for (const link of testLinks) {
    console.log('Testing link:', link);
    try {
      const res = await service.getBusinessMetadata(link);
      console.log('Result:', res);
    } catch (e) {
      console.error('Error:', e);
    }
  }
}

test();
