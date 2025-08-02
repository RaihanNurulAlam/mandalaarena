// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mandalaarenaapp/pages/add_article_page.dart';
import 'package:mandalaarenaapp/pages/edit_article_page.dart';
import 'package:mandalaarenaapp/pages/models/articlecard.dart';
import 'package:mandalaarenaapp/pages/models/articlecard_page.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});
  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && userDoc.exists) {
        setState(() {
          _isAdmin = userDoc.get('isAdmin') as bool;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double desktopMaxWidth = 1200;
        final double horizontalPadding =
            (constraints.maxWidth > desktopMaxWidth)
                ? (constraints.maxWidth - desktopMaxWidth) / 2
                : 20.0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('articles')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(horizontalPadding);
            }

            // ### PERUBAHAN ### Menggunakan SingleChildScrollView dan Wrap
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Artikel',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (_isAdmin)
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Colors.black, size: 32),
                            tooltip: 'Tambah Artikel',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddArtikelPage(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  _buildArticlesContent(
                      constraints, horizontalPadding, snapshot.data!.docs),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ### PERUBAHAN ### Widget baru menggunakan Wrap
  Widget _buildArticlesContent(BoxConstraints constraints, double pagePadding,
      List<QueryDocumentSnapshot> docs) {
    final bool isWideScreen = constraints.maxWidth > 750;

    final double availableWidth = constraints.maxWidth - (pagePadding * 2);
    final int crossAxisCount = isWideScreen ? 2 : 1;
    const double spacing = 16.0;
    final double itemWidth =
        (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(docs.length, (index) {
        return SizedBox(
          width: itemWidth,
          child: _buildArticleCard(docs[index]),
        );
      }),
    );
  }

  Widget _buildArticleCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return ArticleCard(
      title: data['title'],
      subtitle: data['subtitle'],
      imagePath: data['imageUrl'],
      isAdmin: _isAdmin,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailPage(
              title: data['title'],
              subtitle: data['subtitle'],
              imageUrl: data['imageUrl'],
              content: [
                Text(data['content']),
              ],
            ),
          ),
        );
      },
      onDelete: () async {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Artikel'),
            content:
                const Text('Apakah Anda yakin ingin menghapus artikel ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('articles')
                      .doc(doc.id)
                      .delete();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditArticlePage(
              documentId: doc.id,
              initialTitle: data['title'],
              initialSubtitle: data['subtitle'],
              initialContent: data['content'],
              initialImageUrl: data['imageUrl'],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(double horizontalPadding) {
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Artikel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Colors.black, size: 32),
                  tooltip: 'Tambah Artikel',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddArtikelPage(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text('Belum ada artikel.'),
          ),
        ),
      ],
    );
  }
}
