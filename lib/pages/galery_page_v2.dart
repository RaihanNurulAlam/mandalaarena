// ignore_for_file: avoid_web_libraries_in_flutter, use_build_context_synchronously, library_prefixes, avoid_print, unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'dart:html' as html;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as Path;

class GalleryPage extends StatefulWidget {
  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  html.File? _imageFile;
  String? _imageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  String? _uploadedFileURL;

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((e) {
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        final reader = html.FileReader();

        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _imageFile = file;
            _imageUrl = reader.result as String?; // Store the data URL
          });
        });
      }
    });

    input.click();
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gambar terlebih dahulu.')),
      );
      return;
    }

    try {
      final dateTime = DateTime.now().toIso8601String();
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref('gallery/$dateTime${Path.basename(_imageFile!.name)}');
      await ref.putBlob(_imageFile!);

      String imageUrl = await ref.getDownloadURL();
      setState(() {
        _uploadedFileURL = imageUrl;
      });

      await _firestore.collection('gallery').add({
        'imageUrl': _uploadedFileURL,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar berhasil diunggah.')),
      );

      setState(() {
        _imageFile = null;
        _uploadedFileURL = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunggah gambar.')),
      );
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isAdmin = user?.email ==
        'raihannurulalam14@gmail.com'; // Ganti dengan email admin yang sebenarnya

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri Aktivitas',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: _pickImage,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (_imageUrl != null && isAdmin) // Use _imageUrl for preview
            Image.network(
              _imageUrl!, // Display the data URL here
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          if (_uploadedFileURL != null && isAdmin)
            Image.network(
              _uploadedFileURL!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          if (_imageFile != null && isAdmin)
            ElevatedButton(
                onPressed: _uploadImage, child: const Text("Unggah Gambar")),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('gallery')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Belum ada gambar di galeri.'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final imageData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    final imageUrl = imageData['imageUrl'];

                    return Image.network(imageUrl, fit: BoxFit.cover);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
