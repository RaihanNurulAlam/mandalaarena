// ignore_for_file: use_build_context_synchronously, prefer_interpolation_to_compose_strings, avoid_print, deprecated_member_use

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
    super.key,
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

  // State untuk gambar dan loading
  Uint8List? _webImage;
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false; // <-- State untuk loading

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
        // Set _imageUrl ke null agar pratinjau menampilkan gambar baru
        setState(() {
          _imageUrl = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    // Jika tidak ada gambar baru yang dipilih, kembalikan URL gambar yang lama
    if (_imageFile == null && _webImage == null) {
      return widget.initialImageUrl;
    }

    try {
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
        return widget.initialImageUrl; // Fallback
      }

      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return widget
          .initialImageUrl; // Jika gagal upload, jangan hapus gambar lama
    }
  }

  Future<void> _updateArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? newImageUrl = await _uploadImage();

        await FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.documentId)
            .update({
          'title': _titleController.text,
          'subtitle': _subtitleController.text,
          'content': _contentController.text,
          'imageUrl': newImageUrl,
          'timestamp': Timestamp.now(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Artikel berhasil diperbarui!')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui artikel: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // ### PERUBAHAN UTAMA UNTUK UI ADA DI SINI ###
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Edit Artikel'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
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
                          // Logika untuk menampilkan gambar yang sudah ada atau yang baru dipilih
                          child: _webImage != null
                              ? Image.memory(_webImage!, fit: BoxFit.cover)
                              : _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : (_imageUrl != null && _imageUrl!.isNotEmpty)
                                      ? Image.network(
                                          _imageUrl!, fit: BoxFit.cover,
                                          // Tambahkan loading & error builder untuk Image.network
                                          loadingBuilder:
                                              (context, child, progress) {
                                            return progress == null
                                                ? child
                                                : Center(
                                                    child:
                                                        CircularProgressIndicator());
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                                child: Icon(Icons.broken_image,
                                                    size: 50,
                                                    color: Colors.grey[600]));
                                          },
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 50,
                                                color: Colors.grey[600]),
                                            SizedBox(height: 12),
                                            Text("Ubah Gambar Sampul",
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 16)),
                                          ],
                                        ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    // --- Form Fields (Judul, Subjudul, Isi) ---
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
                        onPressed: _isLoading ? null : _updateArticle,
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
                            : Text('Perbarui Artikel',
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
