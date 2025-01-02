// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

Future<void> uploadLapangData() async {
  // Load JSON file
  String data = await rootBundle.loadString('assets/lapang.json');
  List<dynamic> lapangList = json.decode(data);

  // Firestore reference
  CollectionReference lapangCollection =
      FirebaseFirestore.instance.collection('lapang');

  // Upload each item to Firestore
  for (var lapang in lapangList) {
    await lapangCollection.add({
      'name': lapang['name'],
      'description': lapang['description'],
      'price': int.parse(lapang['price']),
      'image_path': lapang['image_path'],
      'rating': double.parse(lapang['rating']),
      'bookings': lapang['bookings'],
      'facilities': lapang['facilities'],
    });
  }
  print('Data uploaded successfully!');
}
