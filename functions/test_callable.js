const axios = require('axios');

async function testCallable() {
  const url = 'https://us-central1-talenthire-d86a1.cloudfunctions.net/createCashfreeOrder';
  
  const payload = {
    data: {
      userId: 'test_user_123',
      amount: 200.0,
      purpose: 'premium_upgrade'
    }
  };

  try {
    console.log('Calling Firebase Function...');
    const response = await axios.post(url, payload, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    console.log('Success:', response.data);
  } catch (error) {
    if (error.response) {
      console.error('Error Status:', error.response.status);
      console.error('Error Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('Error:', error.message);
    }
  }
}

testCallable();
