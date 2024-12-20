import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final double totalPrice;
  const PaymentPage({required this.totalPrice, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Price: IDR $totalPrice',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Booking Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Booking Time: ${TimeOfDay.now().format(context)}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('Duration: 2 Hours', style: TextStyle(fontSize: 16)), // Example duration
            const SizedBox(height: 20),
            const Text('Select Payment Method:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Implement Midtrans payment integration here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment method selected. Proceeding to pay.')),
                );
              },
              child: const Text('Pay with Midtrans'),
            ),
          ],
        ),
      ),
    );
  }
}