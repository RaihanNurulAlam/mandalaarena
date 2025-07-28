import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mandalaarenaapp/pages/add_article_page.dart';
import 'package:mandalaarenaapp/pages/edit_article_page.dart'; // Import halaman edit artikel
import 'package:mandalaarenaapp/pages/models/articlecard.dart';
import 'package:mandalaarenaapp/pages/models/articlecard_page.dart';

class InformationPage extends StatefulWidget {
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
      if (userDoc.exists) {
        setState(() {
          _isAdmin = userDoc.get('isAdmin') as bool;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Artikel', style: TextStyle(color: Colors.black)),
        ),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddArtikelPage(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('articles')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Belum ada artikel.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8, // Tambahkan margin vertikal
                      ),
                      child: ArticleCard(
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
                              title: Text('Hapus Artikel'),
                              content: Text(
                                  'Apakah Anda yakin ingin menghapus artikel ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        Colors.black, // Warna hitam
                                    foregroundColor:
                                        Colors.white, // Font warna putih
                                  ),
                                  child: Text('Batal'),
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
                                  child: Text('Hapus'),
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
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
