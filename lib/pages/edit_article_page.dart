// ignore_for_file: use_build_context_synchronously, duplicate_ignore, prefer_interpolation_to_compose_strings, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class EditArticlePage extends StatefulWidget {
  final String documentId;
  final String initialTitle;
  final String initialSubtitle;
  final String initialContent;
  final String initialImageUrl;

  const EditArticlePage({
    required this.documentId,
    required this.initialTitle,
    required this.initialSubtitle,
    required this.initialContent,
    required this.initialImageUrl,
  });

  @override
  _EditArticlePageState createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();
  Uint8List? _webImage;
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _subtitleController.text = widget.initialSubtitle;
    _contentController.text = widget.initialContent;
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          _webImage = await pickedFile.readAsBytes();
        } else {
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
        return _imageUrl; // Jika tidak ada gambar baru, gunakan URL lama
      }

      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('articles/$fileName');

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

  Future<void> _updateArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        // Menampilkan indikator loading
      });

      try {
        // 1️⃣ **Upload gambar ke Firebase Storage (jika ada gambar baru)**
        String? imageUrl = await _uploadImage();

        // 2️⃣ **Update artikel di Firestore**
        await FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.documentId)
            .update({
          'title': _titleController.text,
          'subtitle': _subtitleController.text,
          'content': _contentController.text,
          'imageUrl': imageUrl ?? _imageUrl,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Artikel berhasil diperbarui!')),
        );

        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Kembali ke halaman artikel
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui artikel: ${e.toString()}')),
        );
      } finally {
        setState(() {
          // Sembunyikan indikator loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Artikel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
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
                          : _imageUrl != null
                              ? Image.network(_imageUrl!, fit: BoxFit.cover)
                              : Icon(Icons.add_a_photo, size: 40),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Judul Artikel'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul artikel tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _subtitleController,
                decoration: InputDecoration(labelText: 'Subjudul Artikel'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Subjudul artikel tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Isi Artikel'),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Isi artikel tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateArticle,
                child: Text('Perbarui Artikel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
