// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // --- State Variables ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Map<String, dynamic>> _reviews = [];
  final Map<int, TextEditingController> _replyControllers = {};

  // UI State Management
  bool _isLoading = true;
  String? _errorMessage;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  double _currentRating = 3.0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Data Fetching and Manipulation (LOGIKA TIDAK DIUBAH) ---

  Future<void> _fetchData() async {
    await _checkAdminStatus();
    await _fetchReviews();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted && userDoc.exists) {
          _isAdmin = userDoc.get('isAdmin') as bool;
        }
      } catch (e) {
        _isAdmin = false;
      }
    }
  }

  Future<void> _fetchReviews() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _reviews.clear();
          for (var doc in reviewsSnapshot.docs) {
            final data = doc.data();
            _reviews.add({
              'id': doc.id,
              'name': data.containsKey('name') ? doc['name'] : 'Anonim',
              'profileImageUrl': data.containsKey('profileImageUrl')
                  ? doc['profileImageUrl']
                  : null,
              'rating': (doc['rating'] as num).toDouble(),
              'description': doc['description'],
              'replies': List<String>.from(doc['replies']),
              'timestamp': doc['timestamp'] as Timestamp?,
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat ulasan. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addReview() async {
    final user = _auth.currentUser;
    String? name;
    String? uid;
    String? photoURL;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      name =
          userDoc.exists ? userDoc.get('name') : user.displayName ?? 'Pengguna';
      photoURL =
          userDoc.exists ? userDoc.get('profileImageUrl') : user.photoURL;
      uid = user.uid;
    } else {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nama tidak boleh kosong.')));
        return;
      }
      name = _nameController.text;
      photoURL = null;
      uid = null;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Deskripsi ulasan tidak boleh kosong.')));
      return;
    }

    final newReview = {
      'uid': uid,
      'name': name,
      'profileImageUrl': photoURL,
      'rating': _currentRating,
      'description': _descriptionController.text,
      'replies': [],
      'timestamp': FieldValue.serverTimestamp(),
    };

    Navigator.pop(context);
    await FirebaseFirestore.instance.collection('reviews').add(newReview);

    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _currentRating = 3.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ulasan berhasil ditambahkan! ✨')));

    _fetchReviews();
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
    if (!_isAdmin) return;
    try {
      final reviewId = _reviews[index]['id'];
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();
      setState(() => _reviews.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ulasan berhasil dihapus.'),
          backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus ulasan.')));
    }
  }

  void _showAddReviewSheet() {
    final user = _auth.currentUser;
    _currentRating = 3.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Beri Ulasan Anda ✍️',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    if (user == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: 'Nama Anda',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline)),
                        ),
                      ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Tulis ulasan...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_outlined)),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Rating Anda:",
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        RatingBar.builder(
                          initialRating: _currentRating,
                          minRating: 1,
                          itemCount: 5,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 2.0),
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {
                            modalSetState(() => _currentRating = rating);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: _addReview,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: const Text('Kirim Ulasan',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16))),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _fetchReviews, child: const Text('Coba Lagi'))
      ]));
    }

    return LayoutBuilder(builder: (context, constraints) {
      const double desktopMaxWidth = 1200;
      final double horizontalPadding = (constraints.maxWidth > desktopMaxWidth)
          ? (constraints.maxWidth - desktopMaxWidth) / 2
          : 20.0;

      if (_reviews.isEmpty) {
        return _buildEmptyState();
      }

      // ### PERUBAHAN ### Menggunakan SingleChildScrollView dan Wrap
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ulasan Pengguna',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: Colors.black, size: 32),
                    tooltip: 'Tambah Ulasan',
                    onPressed: _showAddReviewSheet,
                  ),
                ],
              ),
            ),
            // Konten menggunakan Wrap
            _buildReviewsContent(constraints, horizontalPadding),
            const SizedBox(height: 30),
          ],
        ),
      );
    });
  }

  // ### PERUBAHAN ### Widget baru menggunakan Wrap
  Widget _buildReviewsContent(BoxConstraints constraints, double pagePadding) {
    final bool isWideScreen = constraints.maxWidth > 750;

    // Kalkulasi lebar item
    final double availableWidth = constraints.maxWidth - (pagePadding * 2);
    final int crossAxisCount =
        isWideScreen ? (constraints.maxWidth > 1200 ? 3 : 2) : 1;
    const double spacing = 16.0;
    final double itemWidth =
        (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(_reviews.length, (index) {
        return SizedBox(
          width: itemWidth,
          child: _buildReviewCard(index),
        );
      }),
    );
  }

  Widget _buildReviewCard(int index) {
    final review = _reviews[index];
    _replyControllers[index] ??= TextEditingController();
    final Timestamp? timestamp = review['timestamp'];
    final String formattedDate = timestamp != null
        ? DateFormat('EEEE, d MMMM yyyy').format(timestamp.toDate())
        : 'Beberapa waktu lalu';
    final photoURL = review['profileImageUrl'];

    return Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
            mainAxisSize: MainAxisSize.min, // Penting untuk Wrap
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                        ? NetworkImage(photoURL)
                        : null,
                    child: (photoURL == null || photoURL.isEmpty)
                        ? const Icon(Icons.person_outline,
                            color: Colors.black54)
                        : null),
                title: Text(review['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text(formattedDate, style: const TextStyle(fontSize: 12)),
                trailing: _isAdmin
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deleteReview(index),
                        tooltip: 'Hapus Ulasan')
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RatingBarIndicator(
                          rating: review['rating'],
                          itemBuilder: (context, index) =>
                              const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 20.0),
                      const SizedBox(height: 12),
                      Text(review['description'],
                          style: const TextStyle(
                              fontSize: 14.5,
                              color: Colors.black87,
                              height: 1.4)),
                    ]),
              ),
              if (review['replies'].isNotEmpty)
                _buildAdminReply(review['replies']),
              if (_isAdmin) _buildReplyField(index),
            ]));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Belum Ada Ulasan',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Jadilah yang pertama memberikan ulasan!',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center)
      ]),
    );
  }

  Widget _buildAdminReply(List<dynamic> replies) {
    return Container(
      width: double.infinity,
      color: Colors.black.withOpacity(0.05),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Balasan Admin:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          ...replies.map<Widget>((reply) => Text('• $reply',
              style: const TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildReplyField(int index) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: TextField(
            controller: _replyControllers[index],
            decoration: InputDecoration(
                hintText: 'Tulis balasan sebagai admin...',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _addReply(
                        index, _replyControllers[index]?.text ?? '')))));
  }
}
