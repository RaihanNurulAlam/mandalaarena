const functions = require('firebase-functions');
const admin = require('firebase-admin');
const midtransClient = require('midtrans-client');
const cors = require('cors')({origin: true});

// Inisialisasi Firebase Admin SDK
admin.initializeApp();

// Inisialisasi Midtrans Snap
const snap = new midtransClient.Snap({
  isProduction: false, // Set true untuk produksi
  // serverKey: 'Mid-server-W2fyw-3QehVgbeJP7On4UxYl', // produksi
  serverKey: 'SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-', // sandbox
  // clientKey: 'Mid-client-QXd7sPAjIKeUCPbW' // produksi
  clientKey: 'SB-Mid-client-HsSGwXWH6zCQ2Hmb' //sandbox
});

// Fungsi utama untuk menangani API
exports.api = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      // Endpoint untuk membuat transaksi pembayaran
      if (req.method === 'POST' && req.path === '/pay') {
        const { 
          orderId, 
          grossAmount, 
          firstName, 
          lastName, 
          email, 
          phone 
        } = req.body;

        // Validasi input
        if (!orderId || !grossAmount || !email) {
          return res.status(400).json({error: 'Missing required fields'});
        }

        const parameter = {
          transaction_details: {
            order_id: orderId,
            gross_amount: parseInt(grossAmount)
          },
          credit_card: {
            secure: true
          },
          customer_details: {
            first_name: firstName || 'Customer',
            last_name: lastName || '',
            email: email,
            phone: phone || ''
          },
          callbacks: {
            finish: 'https://mandalaarenaapp-95d0d.web.app/payment-complete',
            error: 'https://mandalaarenaapp-95d0d.web.app/payment-error',
            pending: 'https://mandalaarenaapp-95d0d.web.app/payment-pending'
          }
        };

        const transaction = await snap.createTransaction(parameter);
        
        // Simpan data transaksi awal ke Firestore
        await admin.firestore().collection('transactions').doc(orderId).set({
          orderId: orderId,
          amount: grossAmount,
          status: 'pending',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          customerEmail: email
        });

        return res.status(200).json({
          success: true,
          redirect_url: transaction.redirect_url,
          transactionToken: transaction.token
        });
      }
      // Endpoint untuk memeriksa status transaksi
      else if (req.method === 'GET' && req.path === '/transaction-status') {
        const orderId = req.query.orderId;
        
        if (!orderId) {
          return res.status(400).json({error: 'orderId is required'});
        }

        // Dapatkan status dari Midtrans
        const transaction = await snap.transaction.status(orderId);
        
        // Update status di Firestore jika diperlukan
        if (transaction.transaction_status === 'settlement' || 
            transaction.transaction_status === 'capture') {
          await admin.firestore().collection('transactions').doc(orderId).update({
            status: 'completed',
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }

        return res.status(200).json({
          transaction_status: transaction.transaction_status,
          status_message: transaction.status_message,
          gross_amount: transaction.gross_amount,
          order_id: transaction.order_id
        });
      }
      // Endpoint tidak dikenali
      else {
        return res.status(404).json({error: 'Endpoint not found'});
      }
    } catch (error) {
      console.error('Error:', error);
      return res.status(500).json({
        error: error.message,
        stack: error.stack
      });
    }
  });
});