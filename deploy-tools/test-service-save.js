const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function testFullSave() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const loginRes = await ssh.execCommand(`curl -s -X POST http://localhost:3000/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"snapbizux@gmail.com","password":"80978097"}'`);
    const token = JSON.parse(loginRes.stdout).data.accessToken;

    const res = await ssh.execCommand(`curl -s http://localhost:3000/api/v1/admin/services -H "Authorization: Bearer ${token}"`);
    const services = JSON.parse(res.stdout).services;
    const first = services[0];
    console.log('Testing PATCH with exact flutter payload on:', first.service.id);

    const fullPayload = {
      name: first.service.name,
      description: first.service.description || '',
      category: first.service.category || 'General',
      serviceType: first.service.serviceType || 'custom',
      aiGeneratorEnabled: false,
      aiGeneratorConfig: { language: 'English', tone: 'natural', uniqueness: true },
      isActive: true,
      elements: [],
      reviewMode: 'BUYER',
      workerLimit: 10,
      minCompleteHours: 1,
      maxCompleteHours: 168,
      minAcceptHours: 1,
      maxAcceptHours: 72,
      videoTutorialUrl: null,
      audioGuideUrl: null,
      adminInstructions: null,
      linkFieldLabel: 'Target Link / URL',
      linkFieldPlaceholder: 'https://...',
      textFieldLabel: 'Custom Text / Instructions',
      textFieldPlaceholder: 'Enter text...',
      watchtimeSeconds: 0,
    };

    const patchRes = await ssh.execCommand(`curl -s -w '\\nHTTP_CODE:%{http_code}' -X PATCH http://localhost:3000/api/v1/admin/services/${first.service.id} -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" -d '${JSON.stringify(fullPayload)}'`);
    console.log('Patch response:\n', patchRes.stdout);

    const pricingPayload = {
      buyerUnitPrice: 6.0,
      marginType: 'FIXED',
      marginValue: 1.5,
      workerReward: 4.5
    };
    const pricingRes = await ssh.execCommand(`curl -s -w '\\nHTTP_CODE:%{http_code}' -X POST http://localhost:3000/api/v1/admin/services/${first.service.id}/pricing -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" -d '${JSON.stringify(pricingPayload)}'`);
    console.log('Pricing response:\n', pricingRes.stdout);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    ssh.dispose();
  }
}

testFullSave();
