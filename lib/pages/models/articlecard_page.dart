// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';

class ArticleDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Widget> content;

  const ArticleDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background yang lembut
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        title: Text(
          "Detail Artikel",
          style: TextStyle(fontSize: 18),
        ),
      ),
      // PERUBAHAN 1: Layout dibuat terpusat dengan lebar maksimal
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800), // Lebar maksimal konten
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Gambar Sampul ---
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      // PERUBAHAN 2: Membuat sudut gambar melengkung
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height:
                            350, // Gambar dibuat lebih besar agar lebih menarik
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 350,
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image,
                                size: 50, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 24),

                  // --- Judul Artikel ---
                  // PERUBAHAN 3: Menggunakan Text biasa dengan style yang jelas
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12),

                  // --- Subjudul Artikel ---
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  Divider(height: 48, thickness: 0.5),

                  // --- Konten Artikel ---
                  // PERUBAHAN 4: Menggunakan Column untuk konten dan mengubah perataan teks
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content.map((widget) {
                      if (widget is Text) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            widget.data ?? '',
                            // PERUBAHAN 5: Rata kiri lebih mudah dibaca
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.7, // Jarak antar baris lebih besar
                              color: Colors.grey.shade900,
                            ),
                          ),
                        );
                      }
                      // Jika ada widget selain teks (misal: gambar di tengah artikel)
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: widget,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
