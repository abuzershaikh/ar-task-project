async function testAuth() {
  const baseUrl = 'http://95.179.178.6:3000/api/v1/auth';
  const testEmail = `test_${Date.now()}@example.com`;
  const password = 'Password123!';

  console.log('--- Testing Registration ---');
  try {
    const registerRes = await fetch(`${baseUrl}/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: password,
        fullName: 'Test User',
        role: 'BUYER', // Using BUYER as per AuthService allowed roles
        phone: '+1234567890'
      })
    });
    const registerData = await registerRes.json();
    console.log('Register Response Status:', registerRes.status);
    console.log('Register Data:', registerData);

    if (registerRes.status === 201 || registerRes.status === 200) {
      console.log('\n--- Testing Login ---');
      const loginRes = await fetch(`${baseUrl}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: testEmail,
          password: password
        })
      });
      const loginData = await loginRes.json();
      console.log('Login Response Status:', loginRes.status);
      console.log('Login Data:', loginData);
    }
  } catch (error) {
    console.error('Error during API test:', error);
  }
}

testAuth();
