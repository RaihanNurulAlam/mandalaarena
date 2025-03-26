const functions = require("firebase-functions");
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const midtransClient = require('midtrans-client');
const axios = require('axios');
const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");

const app = express();

// Enhanced CORS configuration
const corsOptions = {
  origin: [
    'https://mandalaarenaapp-95d0d.web.app',
    'https://mandalaarenaapp-95d0d.firebaseapp.com',
    'http://localhost',
    'http://localhost:5000', // Add additional ports if needed
    'https://your-custom-domain.com' // Add if you have custom domain
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  optionsSuccessStatus: 200
};

// Apply CORS middleware before other middleware
app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Enable pre-flight for all routes

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Midtrans Configuration
const snap = new midtransClient.Snap({
  isProduction: false,
  serverKey: 'SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-',
  clientKey: 'SB-Mid-client-HsSGwXWH6zCQ2Hmb',
});

// Enhanced error handling middleware
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: err.message 
  });
});

// Pay endpoint with improved error handling
app.post('/pay', async (req, res) => {
  try {
    console.log('Received payment request:', req.body);
    
    const { orderId, grossAmount, firstName, lastName, email, phone } = req.body;

    if (!orderId || !grossAmount || !firstName || !email || !phone) {
      console.warn('Missing required fields');
      return res.status(400).json({ 
        error: 'Missing required fields',
        required: ['orderId', 'grossAmount', 'firstName', 'email', 'phone']
      });
    }

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
      credit_card: { secure: true },
      callbacks: {
        finish: 'https://mandalaarenaapp-95d0d.web.app/payment-complete',
        error: 'https://mandalaarenaapp-95d0d.web.app/payment-error',
        pending: 'https://mandalaarenaapp-95d0d.web.app/payment-pending'
      },
      expiry: {
        unit: 'hours',
        duration: 24
      }
    };

    const transaction = await snap.createTransaction(parameter);
    // Tambahkan log untuk debugging
    console.log('Midtrans response:', transaction);

    res.status(200).json({
      status: 'success',
      transactionToken: transaction.token,
      redirect_url: transaction.redirect_url,
      orderId: orderId,
    });

  } catch (error) {
    console.error('Payment processing error:', {
      error: error.message,
      stack: error.stack,
      requestBody: req.body
    });
    
    res.status(500).json({ 
      status: 'error',
      error: 'Transaction failed',
      details: error.message,
      code: error.code || 'UNKNOWN_ERROR'
    });
  }
});

// Transaction status endpoint
app.get('/transaction-status', async (req, res) => {
  try {
    const { orderId } = req.query;
    if (!orderId) {
      return res.status(400).json({ error: 'orderId is required' });
    }

    const response = await axios.get(
      `https://api.sandbox.midtrans.com/v2/${orderId}/status`,
      {
        headers: {
          'Accept': 'application/json',
          'Authorization': `Basic ${Buffer.from(snap.apiConfig.serverKey + ":").toString("base64")}`,
        },
        timeout: 10000 // 10 seconds timeout
      }
    );

    res.status(200).json(response.data);
  } catch (error) {
    console.error('Status check error:', {
      error: error.message,
      orderId: req.query.orderId
    });
    
    const statusCode = error.response?.status || 500;
    res.status(statusCode).json({ 
      error: 'Failed to fetch transaction status',
      details: error.response?.data || error.message 
    });
  }
});

// Notification handler
app.post('/notification-handler', async (req, res) => {
  try {
    console.log('Received notification:', req.body);
    const statusResponse = await snap.transaction.notification(req.body);
    
    // Process the notification...
    
    res.status(200).send('Notification processed');
  } catch (error) {
    console.error('Notification error:', error);
    res.status(500).send('Error processing notification');
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

setGlobalOptions({
  region: "asia-southeast2",
  memory: "1GB",
  timeoutSeconds: 60,
});

exports.api = onRequest(app);