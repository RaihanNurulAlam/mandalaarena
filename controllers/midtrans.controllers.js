const midtransClient = require('midtrans-client');
const otpGenerator = require('otp-generator');

let snap = new midtransClient.Snap({
    isProduction: false,
    serverKey: 'SB-Mid-server-cy93tLqGdUiBnvuFQXhVjlH-' // Ganti dengan server key Anda
});

module.exports = {
    midtrans: async (req, res) => {
        const { orderId, grossAmount, firstName, lastName, email, phone } = req.body;
        let parameter = {
            "transaction_details": {
                "order_id": orderId,
                "gross_amount": grossAmount,
            },
            "credit_card": {
                "secure": true
            },
            "customer_details": {
                "first_name": firstName,
                "last_name": lastName,
                "email": email,
                "phone": phone,
            }
        };

        try {
            const transaction = await snap.createTransaction(parameter);
            let transactionToken = transaction.token;
            console.log('transactionToken:', transactionToken);
            res.json({ transactionToken });
        } catch (error) {
            console.error('Error creating transaction:', error);
            res.status(500).json({ error: error.message });
        }
    },
};