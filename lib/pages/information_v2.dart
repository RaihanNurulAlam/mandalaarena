// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, unused_local_variable, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandalaarenaapp/pages/add_article_page.dart';
import 'package:mandalaarenaapp/pages/models/articlecard.dart';
import 'package:mandalaarenaapp/pages/models/articlecard_page.dart';

class InformationPage extends StatefulWidget {
  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Terkini'),
        actions: [
          FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // or a loading indicator
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox.shrink(); // or an error message
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final isAdmin = userData?['isAdmin'] ?? false;

                if (isAdmin) {
                  return IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      final newArticle = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddArticlePage(),
                        ),
                      );
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('articles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada artikel.'));
          }

          final articles = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ArticleCard(
              title: data['title'],
              imagePath: data['imagePath'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailPage(
                      title: data['title'],
                      imagePath: data['imagePath'],
                      content: buildContentWidgets(data['content']),
                    ),
                  ),
                );
              },
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: articles,
          );
        },
      ),
    );
  }

  List<Widget> buildContentWidgets(List<dynamic> contentData) {
    List<Widget> contentWidgets = [];
    for (var item in contentData) {
      if (item is String) {
        contentWidgets.add(Text(item, style: TextStyle(fontSize: 16)));
      } else if (item is Map<String, dynamic>) {
        // Handle other content types as needed, e.g., images
      }
      contentWidgets.add(SizedBox(height: 10));
    }
    return contentWidgets;
  }
}
