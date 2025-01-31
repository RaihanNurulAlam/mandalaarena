// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final List<Map<String, dynamic>> _reviews = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Map<int, TextEditingController> _replyControllers = {};
  double _currentRating = 3.0;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final reviewsSnapshot =
        await FirebaseFirestore.instance.collection('reviews').get();
    setState(() {
      _reviews.clear();
      for (var doc in reviewsSnapshot.docs) {
        _reviews.add({
          'id': doc.id,
          'name': doc['name'],
          'rating': (doc['rating'] as num).toDouble(), // Konversi ke double
          'description': doc['description'],
          'replies': List<String>.from(doc['replies']),
        });
      }
    });
  }

  Future<void> _addReview() async {
    if (_nameController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty) {
      final newReview = {
        'name': _nameController.text,
        'rating': _currentRating, // Sudah bertipe double dari RatingBar
        'description': _descriptionController.text,
        'replies': [],
      };

      final docRef =
          await FirebaseFirestore.instance.collection('reviews').add(newReview);
      setState(() {
        _reviews.add({
          'id': docRef.id,
          ...newReview,
        });
        _nameController.clear();
        _descriptionController.clear();
        _currentRating = 3.0;
      });
    }
  }

  Future<void> _addReply(int index, String reply) async {
    if (reply.isNotEmpty) {
      final reviewId = _reviews[index]['id'];
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .update({
        'replies': FieldValue.arrayUnion([reply]),
      });

      setState(() {
        _reviews[index]['replies'].add(reply);
        _replyControllers[index]?.clear();
      });
    }
  }

  Future<void> _deleteReview(int index) async {
    final reviewId = _reviews[index]['id'];
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete();

    setState(() {
      _reviews.removeAt(index);
      _replyControllers.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tentang Aplikasi', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        // backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ulasan Pengguna:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _reviews.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada ulasan.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        _replyControllers[index] ??= TextEditingController();
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    RatingBarIndicator(
                                      rating: review['rating'],
                                      itemBuilder: (context, index) => Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 18.0,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  review['description'],
                                  style: TextStyle(fontSize: 13),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Balasan:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                ...review['replies']
                                    .map<Widget>((reply) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2.0),
                                          child: Text('- $reply',
                                              style: TextStyle(fontSize: 13)),
                                        )),
                                SizedBox(height: 8),
                                TextField(
                                  controller: _replyControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Balas ulasan',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _addReply(
                                        index,
                                        _replyControllers[index]?.text ?? '',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors
                                            .black, // Atur warna latar belakang di sini
                                      ),
                                      child: Text(
                                        'Kirim Balasan',
                                        style: TextStyle(
                                            color: Colors
                                                .white), // Atur warna teks di sini
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteReview(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              Divider(),
              Text(
                'Tambahkan Ulasan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Rating:',
                style: TextStyle(fontSize: 14),
              ),
              RatingBar(
                initialRating: _currentRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20,
                ratingWidget: RatingWidget(
                  full: Icon(Icons.star, color: Colors.amber),
                  half: Icon(Icons.star_half, color: Colors.amber),
                  empty: Icon(Icons.star_border, color: Colors.amber),
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _currentRating = rating;
                  });
                },
              ),
              SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Ulasan',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: TextStyle(fontSize: 14),
                maxLines: 2,
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.black, // Set the background color to black
                  ),
                  child: Text('Tambah Ulasan',
                      style: TextStyle(fontSize: 14, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
