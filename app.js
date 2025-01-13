const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const midtransClient = require('midtrans-client');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Setup Midtrans client
const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: 'SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-',
  clientKey: 'SB-Mid-client-HsSGwXWH6zCQ2Hmb',
});

// Endpoint untuk membuat transaksi
app.post('/pay', async (req, res) => {
  try {
    const { orderId, grossAmount, firstName, lastName, email, phone } = req.body;

    // Buat payload transaksi
    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: parseInt(grossAmount),
      },
      customer_details: {
        first_name: firstName,
        last_name: lastName,
        email: email,
        phone: phone,
      },
    };

    // Buat token transaksi
    const transaction = await snap.createTransaction(parameter);

    // Kirim token transaksi ke Flutter
    res.status(200).json({ transactionToken: transaction.token });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to create transaction' });
  }
});

app.listen(3000, () => {
  console.log('Server is running on http://localhost:3000');
});
