// ignore_for_file: use_key_in_widget_constructors, file_names

import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/widgets/HomeAppBar.dart';

class HomePage2 extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(children: [
        HomeAppBar()
      ],),
    );
    
  }
}