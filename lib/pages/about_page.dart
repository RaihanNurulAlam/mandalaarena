// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tentang Aplikasi')),
      body: Center(
        child: Text('Informasi tentang aplikasi Mandala Arena.'),
      ),
    );
  }
}
