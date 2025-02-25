require("dotenv").config();
const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const multer = require("multer");
const {v2: cloudinary} = require("cloudinary");
const {CloudinaryStorage} = require("multer-storage-cloudinary");
const midtransClient = require("midtrans-client");

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// === Konfigurasi Cloudinary ===
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Konfigurasi Multer untuk Cloudinary
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: "profile_images",
    allowed_formats: ["jpg", "png", "jpeg"],
    resource_type: "image",
  },
});

const upload = multer({storage: storage});

// === Endpoint untuk Cloudinary ===
app.post("/upload", upload.single("image"), (req, res) => {
  if (req.file) {
    res.status(200).json({
      success: true,
      message: "Image uploaded successfully!",
      imageUrl: req.file.path,
    });
  } else {
    res.status(400).json({success: false, message: "Failed to upload image"});
  }
});

// === Konfigurasi Midtrans ===
const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: process.env.MIDTRANS_SERVER_KEY,
});

// Endpoint untuk membuat transaksi
app.post("/pay", async (req, res) => {
  try {
    const {orderId, grossAmount, firstName, lastName, email, phone} = req.body;

    if (!orderId || !grossAmount || !firstName || !email || !phone) {
      return res.status(400).json({error: "Missing required fields"});
    }

    const parameter = {
      transaction_details: {
        order_id: orderId,
        gross_amount: parseInt(grossAmount),
      },
      customer_details: {
        first_name: firstName,
        last_name: lastName || "",
        email: email,
        phone: phone,
      },
    };

    const transaction = await snap.createTransaction(parameter);

    res.status(200).json({
      transactionToken: transaction.token,
      orderId: orderId,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({error: "Failed to create transaction"});
  }
});

// Endpoint untuk memeriksa status transaksi dengan Midtrans SDK
app.get("/transaction-status", async (req, res) => {
  try {
    const {orderId} = req.query;
    if (!orderId) {
      return res.status(400).json({error: "orderId is required"});
    }

    const transactionStatus = await snap.transaction.status(orderId);
    res.status(200).json(transactionStatus);
  } catch (error) {
    console.error("Error fetching transaction status:", error);
    res.status(500).json({error: "Failed to fetch transaction status"});
  }
});

// Middleware Global untuk Menangani Error
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({error: "Internal Server Error"});
});

// === Ekspor ke Firebase Cloud Functions ===
exports.api = functions.https.onRequest(app);
