// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print, deprecated_member_use

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
  // ... (Semua fungsi dan variabel state dari sebelumnya tetap sama)
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();
  Uint8List? _webImage;
  File? _imageFile;
  bool _isLoading = false;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    // ... (kode _uploadImage tidak berubah)
    try {
      if (_imageFile == null && _webImage == null) return null;
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
        return null;
      }
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _addArtikel() async {
    // ... (kode _addArtikel tidak berubah)
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        String? imageUrl = await _uploadImage();
        await FirebaseFirestore.instance.collection('articles').add({
          'title': _titleController.text,
          'subtitle': _subtitleController.text,
          'content': _contentController.text,
          'imageUrl': imageUrl,
          'timestamp': Timestamp.now(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Artikel berhasil ditambahkan!')));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal menambahkan artikel: ${e.toString()}')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ### PERUBAHAN UTAMA ADA DI DALAM FUNGSI BUILD INI ###
  @override
  Widget build(BuildContext context) {
    // Dekorasi untuk semua input field agar konsisten
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100], // Warna background utama
      appBar: AppBar(
        title: Text('Tambah Artikel Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // Layout di-center dan lebarnya dibatasi
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700), // Batas lebar maksimum
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 15,
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Image Picker ---
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.cover)
                              : _webImage != null
                                  ? Image.memory(_webImage!, fit: BoxFit.cover)
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            size: 50, color: Colors.grey[600]),
                                        SizedBox(height: 12),
                                        Text("Pilih Gambar Sampul",
                                            style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 16)),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    // --- Judul ---
                    Text("Judul Artikel",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: inputDecoration.copyWith(
                          hintText: 'Masukkan judul...'),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Judul tidak boleh kosong'
                          : null,
                    ),
                    SizedBox(height: 24),

                    // --- Subjudul ---
                    Text("Subjudul",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: inputDecoration.copyWith(
                          hintText: 'Masukkan subjudul singkat...'),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Subjudul tidak boleh kosong'
                          : null,
                    ),
                    SizedBox(height: 24),

                    // --- Isi Artikel ---
                    Text("Isi Artikel",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _contentController,
                      decoration: inputDecoration.copyWith(
                          hintText: 'Tulis isi artikel di sini...'),
                      maxLines: 10,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Isi artikel tidak boleh kosong'
                          : null,
                    ),
                    SizedBox(height: 30),

                    // --- Tombol Submit ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addArtikel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3))
                            : Text('Terbitkan Artikel',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
