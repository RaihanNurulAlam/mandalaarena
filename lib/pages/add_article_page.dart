// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings, avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddArtikelPage extends StatefulWidget {
  @override
  _AddArtikelPageState createState() => _AddArtikelPageState();
}

class _AddArtikelPageState extends State<AddArtikelPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();
  Uint8List? _webImage; // Untuk menyimpan gambar di Web
  File? _imageFile; // Untuk Android/iOS

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

      // Referensi ke Firebase Storage dengan folder 'articles'
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

  Future<void> _addArtikel() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        // Menampilkan indikator loading
      });

      try {
        // 1️⃣ **Upload gambar ke Firebase Storage**
        String? imageUrl = await _uploadImage();

        // 2️⃣ **Simpan artikel ke Firestore**
        await FirebaseFirestore.instance.collection('articles').add({
          'title': _titleController.text,
          'subtitle': _subtitleController.text,
          'content': _contentController.text,
          'imageUrl': imageUrl,
          'timestamp': Timestamp.now(),
        });

        // 3️⃣ **Reset form**
        _titleController.clear();
        _subtitleController.clear();
        _contentController.clear();
        setState(() {
          _imageFile = null;
          _webImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Artikel berhasil ditambahkan!')),
        );

        Navigator.pop(context); // Kembali ke halaman artikel
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan artikel: ${e.toString()}')),
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
        title: Text('Tambah Artikel'),
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
                          : Icon(Icons.add_a_photo, size: 40),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Judul Artikel'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul artikel tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _subtitleController,
                  decoration: InputDecoration(labelText: 'Subjudul Artikel'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Subjudul artikel tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
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
              ),
              SizedBox(height: 20),
              ElevatedButton(
  onPressed: _addArtikel,
  style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, // Warna teks putih
    backgroundColor: Colors.black, // Warna background hitam
  ),
  child: Text('Tambah Artikel'),
),
            ],
          ),
        ),
      ),
    );
  }
}
