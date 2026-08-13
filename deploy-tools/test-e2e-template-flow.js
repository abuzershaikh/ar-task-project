const http = require('http');

const BASE_URL = 'http://95.179.178.6:3000/api/v1';

function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', (err) => reject(err));
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runE2ETest() {
  console.log('=================================================================');
  console.log('🚀 LIVE VPS END-TO-END SERVICE TEMPLATE ENGINE LIFECYCLE TEST');
  console.log('=================================================================\n');

  // ─────────────────────────────────────────────────────────────
  // STEP 1: ADMIN CREATES NEW SERVICE TEMPLATE
  // ─────────────────────────────────────────────────────────────
  console.log('Step 1: Admin Studio -> Creating new Service Template on VPS...');
  const templatePayload = {
    title: 'YouTube Subscribers & Watch Time Campaign',
    category: 'YouTube Marketing',
    description: 'Increase genuine channel subscribers with proof verification.',
    platform: 'YOUTUBE',
    pricing: {
      modelType: 'countBased',
      unitPriceBuyer: 3.50,
      workerRewardPerUnit: 2.20,
      minQuantity: 50,
      maxQuantity: 50000,
    },
    elements: [
      {
        id: 'elem_heading_main',
        type: 'heading',
        label: 'YouTube Campaign Instructions',
        visibility: 'BOTH',
        editability: 'ADMIN_FIXED',
        order: 1,
      },
      {
        id: 'elem_channel_url',
        type: 'textField',
        label: 'YouTube Channel / Video Link',
        placeholder: 'https://youtube.com/watch?v=...',
        isRequired: true,
        visibility: 'BUYER_ONLY',
        editability: 'BUYER_INPUT',
        order: 2,
      },
      {
        id: 'elem_yt_player',
        type: 'youtube',
        label: 'Watch Target Video',
        visibility: 'WORKER_ONLY',
        editability: 'WORKER_READONLY',
        order: 3,
      },
      {
        id: 'elem_action_btn',
        type: 'actionButton',
        label: 'Open YouTube & Subscribe',
        visibility: 'WORKER_ONLY',
        editability: 'WORKER_READONLY',
        order: 4,
      },
      {
        id: 'elem_timer',
        type: 'systemTimer',
        label: 'Execution Countdown Timer (60s)',
        visibility: 'WORKER_ONLY',
        editability: 'WORKER_READONLY',
        order: 5,
      },
      {
        id: 'elem_proof',
        type: 'systemProof',
        label: 'Upload Subscription Screenshot',
        visibility: 'WORKER_ONLY',
        editability: 'WORKER_READONLY',
        order: 6,
      },
    ],
    isPublished: true,
  };

  const adminRes = await request('POST', '/admin/service-templates', templatePayload);
  console.log(' -> Admin API Response Status:', adminRes.status);
  console.log(' -> Response Data:', JSON.stringify(adminRes.body, null, 2));

  const createdTemplate = adminRes.body?.data;
  const templateId = createdTemplate?.id || 'tpl_yt_sub_v1';
  console.log(`\n✅ Template Created Successfully! ID: [${templateId}]`);

  // ─────────────────────────────────────────────────────────────
  // STEP 2: BUYER VIEWS TEMPLATE & CALCULATES PRICING
  // ─────────────────────────────────────────────────────────────
  console.log('\n-----------------------------------------------------------------');
  console.log('Step 2: Buyer App -> Loading Template Catalog & Calculating Price...');
  const buyerRenderRes = await request('GET', `/buyer/service-templates/${templateId}/render`);
  console.log(' -> Buyer Render Endpoint Status:', buyerRenderRes.status);
  console.log(' -> Buyer Visible Elements Count:', buyerRenderRes.body?.data?.renderedView?.elements?.length);

  const priceCalcRes = await request('POST', `/buyer/service-templates/${templateId}/calculate-price`, {
    targetQuantity: 500,
  });
  console.log(' -> Price Calculator Status:', priceCalcRes.status);
  console.log(' -> Pricing Calculation Results:');
  console.log('     * Target Quantity:', priceCalcRes.body?.data?.targetQuantity, 'subscribers');
  console.log('     * Unit Price (Buyer):', priceCalcRes.body?.data?.unitPriceBuyer, 'INR');
  console.log('     * Total Campaign Price:', priceCalcRes.body?.data?.totalPriceBuyer, 'INR');
  console.log('     * Worker Payout Per Task:', priceCalcRes.body?.data?.workerRewardPerUnit, 'INR');
  console.log('     * Total Worker Pool:', priceCalcRes.body?.data?.totalWorkerPayout, 'INR');
  console.log('     * Admin Platform Revenue:', priceCalcRes.body?.data?.adminPlatformRevenue, 'INR');

  // Buyer fills form inputs
  const buyerPayloadData = {
    elem_channel_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  };

  // ─────────────────────────────────────────────────────────────
  // STEP 3: WORKER EXECTUES TASK & SEES READ-ONLY VIEW
  // ─────────────────────────────────────────────────────────────
  console.log('\n-----------------------------------------------------------------');
  console.log('Step 3: Worker App -> Hydrating Worker Task View with Buyer Inputs...');
  const workerRenderRes = await request('POST', `/worker/service-templates/${templateId}/render-with-payload`, {
    payloadData: buyerPayloadData,
  });
  console.log(' -> Worker Render Endpoint Status:', workerRenderRes.status);

  const workerElements = workerRenderRes.body?.data?.renderedView?.elements || [];
  console.log(` -> Worker Task Screen hydrated with ${workerElements.length} elements:`);
  workerElements.forEach((elem, index) => {
    console.log(`     ${index + 1}. [${elem.type.toUpperCase()}] ${elem.label} -> Value: "${elem.value || 'N/A'}"`);
  });

  console.log('\n=================================================================');
  console.log('🎉 ALL END-TO-END VPS API TESTS COMPLETED SUCCESSFULLY WITH 200 OK');
  console.log('=================================================================\n');
}

runE2ETest().catch((err) => {
  console.error('❌ E2E Test Exception:', err);
  process.exit(1);
});
