const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const multer = require('multer');
const { v2: cloudinary } = require('cloudinary');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const midtransClient = require('midtrans-client');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// === Konfigurasi Cloudinary ===
cloudinary.config({
  cloud_name: 'dru7n46a5', // Ganti dengan Cloudinary Cloud Name Anda
  api_key: '522939137274927',       // Ganti dengan API Key Anda
  api_secret: 'DhV_qPW7dxmclTU_wQTEZoZR23E', // Ganti dengan API Secret Anda
});

// Konfigurasi Multer untuk penyimpanan di Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'profile_images', // Nama folder di Cloudinary
    allowed_formats: ['jpg', 'png', 'jpeg'], // Format gambar yang diizinkan
  },
});

const upload = multer({ storage: storage });

// === Endpoint untuk Cloudinary ===
// Endpoint untuk mengunggah gambar
app.post('/upload', upload.single('image'), (req, res) => {
  if (req.file) {
    res.status(200).json({
      success: true,
      message: 'Image uploaded successfully!',
      imageUrl: req.file.path,
    });
  } else {
    res.status(400).json({ success: false, message: 'Failed to upload image' });
  }
});

// === Konfigurasi Midtrans ===
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
    if (!orderId) {
      return res.status(400).json({ error: 'orderId is required' });
    }

    const response = await axios.get(`https://api.sandbox.midtrans.com/v2/${orderId}/status`, {
      headers: {
        Authorization: `Basic ${Buffer.from(snap.apiConfig.serverKey + ":").toString("base64")}`,
      },
    });

    res.status(200).json(response.data);
  } catch (error) {
    console.error('Error fetching transaction status:', error);
    res.status(500).json({ error: 'Failed to fetch transaction status' });
  }
});

// Jalankan server
app.listen(3000, () => {
  console.log('Server is running on http://localhost:3000');
});
