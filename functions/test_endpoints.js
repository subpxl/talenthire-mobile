const axios = require('axios');

const BASE_URL = 'https://us-central1-talenthire-d86a1.cloudfunctions.net';

async function testEndpoints() {
  console.log('=== Testing Live Firebase Function Endpoints ===\n');

  // 1. Test createCashfreeOrder callable
  console.log('1. Testing createCashfreeOrder...');
  try {
    const response = await axios.post(`${BASE_URL}/createCashfreeOrder`, {
      data: {
        userId: 'xYhr3BDMsqYEZMK1ABCD',  // Real-looking Firestore UID format
        amount: 200.0,
        purpose: 'premium_upgrade'
      }
    }, {
      headers: { 'Content-Type': 'application/json' }
    });
    const result = response.data?.result;
    console.log('   ✅ createCashfreeOrder SUCCESS');
    console.log('   orderId:', result?.orderId);
    console.log('   paymentSessionId:', result?.paymentSessionId ? result.paymentSessionId.substring(0, 40) + '...' : 'MISSING!');
    console.log('   environment:', result?.environment);
    if (!result?.paymentSessionId) {
      console.log('   ❌ PROBLEM: No paymentSessionId returned!');
    }
  } catch (error) {
    console.log('   ❌ createCashfreeOrder FAILED');
    if (error.response) {
      console.log('   Status:', error.response.status);
      console.log('   Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.log('   Error:', error.message);
    }
  }

  console.log('\n2. Testing cashfreeWebhook (basic reachability)...');
  try {
    const response = await axios.post(`${BASE_URL}/cashfreeWebhook`, {
      type: 'TEST'
    }, {
      headers: { 'Content-Type': 'application/json' },
      validateStatus: (s) => s < 500  // Accept 4xx as "reachable"
    });
    console.log('   ✅ cashfreeWebhook is reachable. Status:', response.status, '(expected 400/401 without valid signature)');
  } catch (error) {
    if (error.response?.status >= 500) {
      console.log('   ❌ cashfreeWebhook returned 500 - still has errors!');
      console.log('   Data:', error.response?.data);
    } else if (error.response) {
      console.log('   ✅ cashfreeWebhook reachable. Status:', error.response.status);
    } else {
      console.log('   ❌ Cannot reach webhook:', error.message);
    }
  }

  console.log('\n3. Checking full createCashfreeOrder response structure...');
  try {
    const response = await axios.post(`${BASE_URL}/createCashfreeOrder`, {
      data: {
        userId: 'testUser123',
        amount: 20.0,
        purpose: 'first_message'
      }
    }, {
      headers: { 'Content-Type': 'application/json' }
    });
    console.log('   Full response.data:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.log('   Error:', error.response?.data || error.message);
  }
}

testEndpoints();
