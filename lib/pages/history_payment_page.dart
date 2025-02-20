import 'package:flutter/material.dart';

class HistoryPaymentPage extends StatelessWidget {
  final String status;

  const HistoryPaymentPage({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Pembayaran'),
      ),
      body: Center(
        child: Text('Status Pembayaran: $status'),
      ),
    );
  }
}
