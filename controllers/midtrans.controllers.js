const midtransClient = require('midtrans-client');

// Konfigurasi Midtrans Snap Client
const snap = new midtransClient.Snap({
    isProduction: false, // Ubah ke true jika di lingkungan produksi
    serverKey: 'SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-', // Ganti dengan server key Anda
});

// Fungsi untuk Membuat Transaksi
const midtrans = async (req, res) => {
    const { orderId, grossAmount, firstName, lastName, email, phone } = req.body;

    // Validasi Input
    if (!orderId || !grossAmount || !firstName || !email || !phone) {
        return res.status(400).json({ error: 'Invalid data' });
    }

    const parameter = {
        transaction_details: {
            order_id: orderId,
            gross_amount: parseInt(grossAmount), // Pastikan dalam bentuk angka
        },
        credit_card: {
            secure: true,
        },
        customer_details: {
            first_name: firstName,
            last_name: lastName,
            email: email,
            phone: phone,
        },
    };

    try {
        // Buat Transaksi melalui Midtrans
        const transaction = await snap.createTransaction(parameter);

        // Kirimkan Transaction Token ke Client
        const transactionToken = transaction.token;
        console.log('Transaction Token:', transactionToken);
        res.json({ transactionToken });
    } catch (error) {
        console.error('Error creating transaction:', error);
        res.status(500).json({ error: 'Error creating transaction' });
    }
};

// Ekspor `snap` dan `midtrans`
module.exports = { snap, midtrans };
