import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

void uploadLapanganData() async {
  final jsonData = '''
  [
    {
      "name": "Aula Basket Lapangan Vinyl",
      "description": "Deskripsi Vynil Basket.",
      "price": 300000,
      "image_path": "assets/vynil.jpg",
      "rating": 4.9,
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    }
    {
      "name": "Aula Basket Lapangan Karet",
      "description": "Deskripsi Rubber Basket.",
      "price": "300000",
      "image_path": "assets/rubber.jpg",
      "rating": "4.8",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    },
    {
      "name": "Aula Basket Lapangan 3x3",
      "description": "Deskripsi 3x3 Basket.",
      "price": "300000",
      "image_path": "assets/3x3.jpg",
      "rating": "4.9",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    },
    {
      "name": "Lapang Minisoccer",
      "description": "Deskripsi Minisoccer.",
      "price": "120000",
      "image_path": "assets/mini.jpg",
      "rating": "4.9",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    },
    {
      "name": "Gokart",
      "description": "Deskripsi Gokart.",
      "price": "150000",
      "image_path": "assets/gokart.jpg",
      "rating": "5.0",
      "bookings": [],
      "facilities": ["Shower", "Parking Area", "Locker Room"]
    }
  ]
  ''';
  
  final List<dynamic> lapanganList = jsonDecode(jsonData);

  for (var lapang in lapanganList) {
    await FirebaseFirestore.instance.collection('lapang').add(lapang);
  }
}
