const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const midtransClient = require("midtrans-client");
const axios = require("axios");

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// === Konfigurasi Midtrans ===
const snap = new midtransClient.Snap({
  isProduction: false, // Ubah ke `true` jika menggunakan environment produksi
  serverKey: "SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-", // Ganti dengan server key Anda
  clientKey: "SB-Mid-client-HsSGwXWH6zCQ2Hmb", // Ganti dengan client key Anda
});

// Endpoint untuk membuat transaksi
app.post("/pay", async (req, res) => {
  try {
    const { orderId, grossAmount, firstName, lastName, email, phone } =
      req.body;

    // Validasi input
    if (!orderId || !grossAmount || !firstName || !email || !phone) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: parseInt(grossAmount, 10),
      },
      customer_details: {
        first_name: firstName,
        last_name: lastName || "",
        email,
        phone,
      }, // Tambahkan trailing comma di sini
    };

    // Membuat transaksi di Midtrans
    const transaction = await snap.createTransaction(parameter);

    res.status(200).json({
      transactionToken: transaction.token,
      orderId,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to create transaction" });
  }
});

// Endpoint untuk memeriksa status transaksi
app.get("/transaction-status", async (req, res) => {
  try {
    const { orderId } = req.query;
    if (!orderId) {
      return res.status(400).json({ error: "orderId is required" });
    }

    const response = await axios.get(
      `https://api.sandbox.midtrans.com/v2/${orderId}/status`,
      {
        headers: {
          Authorization: `Basic ${Buffer.from(
            `${snap.apiConfig.serverKey}:`
          ).toString("base64")}`,
        },
      }
    );

    res.status(200).json(response.data);
  } catch (error) {
    console.error("Error fetching transaction status:", error);
    res.status(500).json({ error: "Failed to fetch transaction status" });
  }
});

// Ekspor ke Firebase Cloud Functions
exports.api = functions.https.onRequest(app);
