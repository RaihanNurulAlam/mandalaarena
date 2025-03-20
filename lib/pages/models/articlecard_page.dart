// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';

class ArticleDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Widget> content;

  const ArticleDetailPage({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
            const SizedBox(height: 16),
            // Judul artikel dengan alignment justify
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: title,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Subjudul artikel dengan alignment justify
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  children: [
                    TextSpan(
                      text: subtitle,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Konten artikel dengan teks justify
            ...content.map((widget) {
              if (widget is Text) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: widget.data,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return widget;
            }).toList(),
          ],
        ),
      ),
    );
  }
}
