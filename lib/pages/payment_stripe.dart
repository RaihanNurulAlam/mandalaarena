import 'package:flutter/material.dart';

class PaymentStripe extends StatefulWidget {
  const PaymentStripe({super.key});

  @override
  State<PaymentStripe> createState() => _PaymentStripeState();
}

class _PaymentStripeState extends State<PaymentStripe> {
  double amount = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment with Stripe'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(
                'Pay Now ${amount.toString()}',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
