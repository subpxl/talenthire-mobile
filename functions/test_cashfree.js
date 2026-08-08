const axios = require('axios');

const CLIENT_ID = process.env.CASHFREE_CLIENT_ID || '';
const CLIENT_SECRET = process.env.CASHFREE_CLIENT_SECRET || '';
const BASE_URL = 'https://sandbox.cashfree.com/pg';

async function testCreateOrder() {
  const customerId = 'test_user_123';
  const orderId = `ord_${Date.now()}_${customerId}`;
  const amount = 200;

  const requestBody = {
    order_id: orderId,
    order_amount: amount,
    order_currency: 'INR',
    customer_details: {
      customer_id: customerId,
      customer_phone: '9999999999',
      customer_email: `${customerId}@example.com`,
      customer_name: customerId,
    },
    order_meta: {
      notify_url: 'https://us-central1-talenthire-d86a1.cloudfunctions.net/cashfreeWebhook',
    },
  };

  try {
    console.log('Sending request to Cashfree...', JSON.stringify(requestBody, null, 2));
    const response = await axios.post(`${BASE_URL}/orders`, requestBody, {
      headers: {
        'x-client-id': CLIENT_ID,
        'x-client-secret': CLIENT_SECRET,
        'x-api-version': '2023-08-01',
        'Content-Type': 'application/json',
      },
    });
    console.log('Success!');
    console.log('Response data:', response.data);
  } catch (error) {
    console.error('Error testing Cashfree API:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error(error.message);
    }
  }
}

testCreateOrder();
