// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:cloud_firestore/cloud_firestore.dart';

class Lapang {
  List<String>? bookings;
  String? id;
  String? name;
  String? description;
  String? price;
  String? imagePath;
  String? rating;
  static Future<Lapang?> getLapangFromFirestore(String lapangId) async {
    final lapangDoc = await FirebaseFirestore.instance
        .collection('lapang')
        .doc(lapangId)
        .get();

    if (lapangDoc.exists) {
      return Lapang.fromJson(lapangDoc.data()!);
    } else {
      return null;
    }
  }
  
  Lapang({
    this.id,
    this.name,
    this.description,
    this.price,
    this.imagePath,
    this.rating,
    this.bookings,
  });

  Lapang.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    price = json['price'];
    imagePath = json['image_path'];
    rating = json['rating'];
    bookings = List<String>.from(json['bookings'] ?? []);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['image_path'] = imagePath;
    data['rating'] = rating;
    data['bookings'] = bookings;
    return data;
  }
}
