// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

class InformationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Informasi Terkini')),
      body: Center(
        child: Text('Informasi dan artikel terbaru.'),
      ),
    );
  }
}
