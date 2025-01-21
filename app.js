const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const midtransClient = require('midtrans-client');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Setup Midtrans client
const snap = new midtransClient.Snap({
  isProduction: false, // Ubah ke `true` jika menggunakan environment produksi
  serverKey: 'SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-', // Ganti dengan server key Anda
  clientKey: 'SB-Mid-client-HsSGwXWH6zCQ2Hmb', // Ganti dengan client key Anda
});

// Endpoint untuk membuat transaksi
app.post('/pay', async (req, res) => {
  try {
    const { orderId, grossAmount, firstName, lastName, email, phone } = req.body;

    // Validasi input
    if (!orderId || !grossAmount || !firstName || !email || !phone) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Parameter transaksi Midtrans
    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: parseInt(grossAmount),
      },
      customer_details: {
        first_name: firstName,
        last_name: lastName || '',
        email: email,
        phone: phone,
      },
    };

    // Membuat transaksi di Midtrans
    const transaction = await snap.createTransaction(parameter);

    res.status(200).json({
      transactionToken: transaction.token,
      orderId: orderId,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to create transaction' });
  }
});

// Endpoint untuk memeriksa status transaksi
app.get('/transaction-status', async (req, res) => {
  try {
    const { orderId } = req.query;

    // Validasi input
    if (!orderId) {
      return res.status(400).json({ error: 'Order ID is required' });
    }

    // Mendapatkan status transaksi dari Midtrans
    const transactionStatus = await snap.transaction.status(orderId);

    res.status(200).json(transactionStatus);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to fetch transaction status' });
  }
});

// Jalankan server
app.listen(3000, () => {
  console.log('Server is running on http://localhost:3000');
});
