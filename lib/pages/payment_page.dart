// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatelessWidget {
  final DateTime date;
  final int startHour;
  final int duration;
  final int total;

  PaymentPage({
    required this.date,
    required this.startHour,
    required this.duration,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Booking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Tanggal: ${DateFormat('dd MMM yyyy').format(date)}'),
            Text('Jam Mulai: ${startHour.toString().padLeft(2, '0')}:00'),
            Text('Durasi: $duration Jam'),
            Text('Total: Rp $total'),
            SizedBox(height: 32),
            Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pembayaran Berhasil!')),
                );
                Navigator.pop(context);
              },
              child: Text('Bayar dengan Transfer Bank'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pembayaran Berhasil!')),
                );
                Navigator.pop(context);
              },
              child: Text('Bayar dengan E-Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
