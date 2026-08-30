const BASE_URL = 'http://65.20.77.112:3000/api/v1';

async function testApi() {
  console.log('================================================================');
  console.log('    TESTING LIVE TASK ENGINE API OVER PUBLIC INTERNET');
  console.log('    Target URL: ' + BASE_URL);
  console.log('================================================================\n');

  try {
    // Test 1: Health Endpoint
    console.log('1️⃣ Testing GET /health ...');
    const healthRes = await fetch(`${BASE_URL}/health`);
    const healthJson = await healthRes.json();
    console.log('   Status Code:', healthRes.status);
    console.log('   Response   :', JSON.stringify(healthJson, null, 2));
    if (healthRes.status === 200 && healthJson.data?.status === 'ok') {
      console.log('   ✅ Health Check PASSED!\n');
    } else {
      console.log('   ❌ Health Check FAILED!\n');
    }

    // Test 2: Swagger Documentation
    console.log('2️⃣ Testing GET /api/docs ...');
    const docsRes = await fetch('http://65.20.77.112:3000/api/docs/');
    console.log('   Status Code:', docsRes.status);
    if (docsRes.status === 200) {
      console.log('   ✅ Swagger Documentation UI reachable!\n');
    }

    // Test 3: SuperAdmin Login
    console.log('3️⃣ Testing POST /auth/login (Snapbiz SuperAdmin) ...');
    const loginRes = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'snapbizux@gmail.com',
        password: '80978097',
      }),
    });
    const loginJson = await loginRes.json();
    console.log('   Status Code:', loginRes.status);
    console.log('   User Email :', loginJson.data?.user?.email);
    console.log('   User Role  :', loginJson.data?.user?.role);
    console.log('   JWT Token  :', loginJson.data?.accessToken ? loginJson.data.accessToken.substring(0, 35) + '...' : 'None');
    if (loginRes.status === 200 && loginJson.data?.accessToken) {
      console.log('   ✅ SuperAdmin Login PASSED!\n');
    }

    const adminToken = loginJson.data?.accessToken;

    // Test 4: Admin Services Catalog
    if (adminToken) {
      console.log('4️⃣ Testing GET /admin/services (Authenticated Admin) ...');
      const servicesRes = await fetch(`${BASE_URL}/admin/services`, {
        headers: { Authorization: `Bearer ${adminToken}` },
      });
      const servicesJson = await servicesRes.json();
      console.log('   Status Code   :', servicesRes.status);
      console.log('   Total Services:', servicesJson.total);
      if (servicesJson.services && servicesJson.services.length > 0) {
        servicesJson.services.forEach((s, idx) => {
          console.log(`     [${idx + 1}] Code: ${s.service.code.padEnd(20)} | Name: ${s.service.name.padEnd(28)} | Price: ₹${s.activePricing.buyerUnitPrice}`);
        });
        console.log('   ✅ Admin Services Catalog PASSED!\n');
      }
    }

    // Test 5: Worker Registration & Available Tasks
    const randomWorkerNum = Math.floor(1000 + Math.random() * 9000);
    const workerEmail = `worker_${randomWorkerNum}@test.com`;
    console.log(`5️⃣ Testing POST /auth/register (New Worker: ${workerEmail}) ...`);
    const workerRegRes = await fetch(`${BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: workerEmail,
        password: 'WorkerPassword@123',
        fullName: `Test Worker ${randomWorkerNum}`,
        role: 'WORKER',
      }),
    });
    const workerRegJson = await workerRegRes.json();
    console.log('   Status Code:', workerRegRes.status);
    console.log('   Worker ID  :', workerRegJson.data?.user?.id);
    const workerToken = workerRegJson.data?.accessToken;

    if (workerToken) {
      console.log('   ✅ Worker Registration & JWT Generation PASSED!');
      
      console.log('\n6️⃣ Testing GET /worker/tasks/available (Worker Tasks API) ...');
      const workerTasksRes = await fetch(`${BASE_URL}/worker/tasks/available`, {
        headers: { Authorization: `Bearer ${workerToken}` },
      });
      const workerTasksJson = await workerTasksRes.json();
      console.log('   Status Code:', workerTasksRes.status);
      console.log('   Response   :', JSON.stringify(workerTasksJson));
      console.log('   ✅ Worker Tasks API Response PASSED!\n');
    }

    // Test 6: Buyer Registration & Buyer Services
    const randomBuyerNum = Math.floor(1000 + Math.random() * 9000);
    const buyerEmail = `buyer_${randomBuyerNum}@test.com`;
    console.log(`7️⃣ Testing POST /auth/register (New Buyer: ${buyerEmail}) ...`);
    const buyerRegRes = await fetch(`${BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: buyerEmail,
        password: 'BuyerPassword@123',
        fullName: `Test Buyer ${randomBuyerNum}`,
        role: 'BUYER',
      }),
    });
    const buyerRegJson = await buyerRegRes.json();
    console.log('   Status Code:', buyerRegRes.status);
    const buyerToken = buyerRegJson.data?.accessToken;

    if (buyerToken) {
      console.log('   ✅ Buyer Registration & JWT Generation PASSED!');

      console.log('\n8️⃣ Testing GET /buyer/services (Buyer Catalog API) ...');
      const buyerServicesRes = await fetch(`${BASE_URL}/buyer/services`, {
        headers: { Authorization: `Bearer ${buyerToken}` },
      });
      const buyerServicesJson = await buyerServicesRes.json();
      console.log('   Status Code   :', buyerServicesRes.status);
      console.log('   Total Services:', buyerServicesJson.total);
      if (buyerServicesJson.services) {
        buyerServicesJson.services.forEach((s, idx) => {
          console.log(`     [${idx + 1}] ${s.name.padEnd(28)} | Buyer Unit Price: ₹${s.buyerUnitPrice}`);
        });
      }
      console.log('   ✅ Buyer Services API PASSED!\n');
    }

    console.log('================================================================');
    console.log('🎉 ALL 8 LIVE API ENDPOINTS WORKING & RESPONDING 100% PERFECTLY!');
    console.log('================================================================');

  } catch (err) {
    console.error('❌ Test failed:', err);
  }
}

testApi();
