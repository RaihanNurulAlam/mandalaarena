import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final Timestamp createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? 'Judul Tidak Tersedia',
      description: data['description'] ?? 'Deskripsi tidak tersedia.',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
