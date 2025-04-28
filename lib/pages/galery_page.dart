// ignore_for_file: use_build_context_synchronously, avoid_print, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb

class GalleryPage extends StatefulWidget {
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  Uint8List? _webImage; // Untuk menyimpan gambar di Web
  File? _imageFile; // Untuk Android/iOS

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
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          // Web: Simpan sebagai Uint8List
          _webImage = await pickedFile.readAsBytes();
        } else {
          // Mobile/Desktop: Simpan sebagai File
          _imageFile = File(pickedFile.path);
        }
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    try {
      if (_imageFile == null && _webImage == null) {
        return null; // Jika tidak ada gambar, biarkan kosong
      }

      // Generate nama file unik
      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';

      // Referensi ke Firebase Storage dengan folder 'gallery'
      Reference storageRef =
          FirebaseStorage.instance.ref().child('gallery/$fileName');

      UploadTask uploadTask;
      if (kIsWeb && _webImage != null) {
        uploadTask = storageRef.putData(_webImage!);
      } else if (_imageFile != null) {
        uploadTask = storageRef.putFile(_imageFile!);
      } else {
        throw Exception("Gambar tidak ditemukan");
      }

      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _addImage() async {
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih gambar terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      // Menampilkan indikator loading
    });

    try {
      // 1️⃣ **Upload gambar ke Firebase Storage**
      String? imageUrl = await _uploadImage();

      // 2️⃣ **Simpan URL gambar ke Firestore**
      await FirebaseFirestore.instance.collection('gallery').add({
        'imageUrl': imageUrl,
        'uploadedBy': _auth.currentUser?.uid,
        'timestamp': Timestamp.now(),
      });

      // 3️⃣ **Reset gambar yang dipilih**
      setState(() {
        _imageFile = null;
        _webImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gambar berhasil diupload!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupload gambar: ${e.toString()}')),
      );
    } finally {
      setState(() {
        // Sembunyikan indikator loading
      });
    }
  }

  Future<void> _deleteImage(String docId, String imageUrl) async {
    try {
      // 1️⃣ **Hapus gambar dari Firestore**
      await FirebaseFirestore.instance
          .collection('gallery')
          .doc(docId)
          .delete();

      // 2️⃣ **Hapus gambar dari Firebase Storage**
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gambar berhasil dihapus!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus gambar: ${e.toString()}')),
      );
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Upload Gambar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      setState(
                          () {}); // Perbarui tampilan popup setelah memilih gambar
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : _webImage != null
                              ? Image.memory(_webImage!, fit: BoxFit.cover)
                              : Icon(Icons.add_a_photo, size: 40),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_imageFile == null && _webImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Pilih gambar terlebih dahulu!')),
                        );
                        return;
                      }
                      Navigator.pop(context); // Tutup popup
                      _addImage(); // Upload gambar
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, // Warna teks putih
                      backgroundColor: Colors.black, // Warna background hitam
                    ),
                    child: Text('Upload'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteImage(String docId, String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus gambar ini?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Tidak jadi hapus
              style: TextButton.styleFrom(
                backgroundColor: Colors.black, // Warna latar belakang hitam
                foregroundColor: Colors.white, // Warna teks putih
              ),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // Konfirmasi hapus
              style: TextButton.styleFrom(
                backgroundColor: Colors.black, // Warna latar belakang hitam
                foregroundColor: Colors.white, // Warna teks putih
              ),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteImage(docId, imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    // Pengkondisian jumlah kolom berdasarkan lebar layar
    if (screenWidth > 1200) {
      crossAxisCount = 3;
    } else if (screenWidth > 750) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Galeri Aktivitas', style: TextStyle(color: Colors.black)),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Icon(Icons.add),
                onPressed: _showUploadDialog,
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gallery')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Belum ada gambar.'));
          }
          return GridView.builder(
            padding: EdgeInsets.only(
                left: 30, right: 30, bottom: 20), // Padding untuk semua sisi
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5, // Ukuran landscape dan portrait sama
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var imageUrl = doc['imageUrl'];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (_isAdmin)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteImage(doc.id, imageUrl),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
