// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Center(
        child: Text('Form untuk melakukan pembayaran.'),
      ),
    );
  }
}
