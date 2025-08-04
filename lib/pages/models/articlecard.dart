// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ArticleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isAdmin;

  const ArticleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // PERUBAHAN 1: Kustomisasi bentuk, bayangan, dan kliping kartu
      clipBehavior:
          Clip.antiAlias, // Penting agar gambar mengikuti bentuk kartu
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Gambar dengan tombol admin di atasnya ---
          Stack(
            children: [
              // Gambar utama
              Image.network(
                imagePath,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
                // Memberikan feedback saat gambar dimuat
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator()),
                        );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image,
                        size: 50, color: Colors.grey[400]),
                  );
                },
              ),
              // PERUBAHAN 2: Tombol admin dengan latar belakang agar lebih jelas
              if (isAdmin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        if (onEdit != null)
                          IconButton(
                            icon:
                                Icon(Icons.edit, color: Colors.white, size: 20),
                            onPressed: onEdit,
                            tooltip: 'Edit',
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.red.shade300, size: 20),
                            onPressed: onDelete,
                            tooltip: 'Hapus',
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // --- Area Teks ---
          // PERUBAHAN 3: Padding yang lebih bersih dan konsisten
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Text(
                  title,
                  maxLines: 2, // Mencegah teks terlalu panjang
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                // Subjudul
                Text(
                  subtitle,
                  maxLines: 3, // Mencegah teks terlalu panjang
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700, // Warna lebih kontras
                  ),
                ),
                SizedBox(height: 16),
                // PERUBAHAN 4: Tombol "Baca Selengkapnya" sebagai Call to Action
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onTap,
                    child: Text(
                      'Baca Selengkapnya',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
