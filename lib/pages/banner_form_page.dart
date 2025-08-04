// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/banner_model.dart';

class BannerFormPage extends StatefulWidget {
  final BannerModel? banner;

  const BannerFormPage({super.key, this.banner});

  @override
  State<BannerFormPage> createState() => _BannerFormPageState();
}

class _BannerFormPageState extends State<BannerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _imageFile;
  String? _networkImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.banner != null) {
      _titleController.text = widget.banner!.title;
      _descriptionController.text = widget.banner!.description;
      _networkImageUrl = widget.banner!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil gambar: $e")),
      );
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      String fileName =
          'banners/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb) {
        await ref.putData(await image.readAsBytes());
      } else {
        await ref.putFile(File(image.path));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengunggah gambar: $e")),
      );
      return null;
    }
  }

  Future<void> _submitForm() async {
    // Validasi gambar: harus ada gambar jika membuat banner baru
    if (_imageFile == null && widget.banner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih gambar untuk banner.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl = _networkImageUrl;

    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
      if (imageUrl == null) {
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'createdAt': widget.banner?.createdAt ?? Timestamp.now(),
      };

      if (widget.banner == null) {
        await FirebaseFirestore.instance.collection('banners').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(widget.banner!.id)
            .update(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Banner berhasil disimpan!")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan data banner: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.banner != null;

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
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Banner' : 'Tambah Banner Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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
                    // --- Komponen Gambar Terpadu ---
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildImagePreview(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Judul (Opsional) ---
                    const Text("Judul (Opsional)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: inputDecoration.copyWith(
                          hintText: 'Masukkan judul banner...'),
                      // Validator dihapus agar opsional
                    ),
                    const SizedBox(height: 24),

                    // --- Deskripsi (Opsional) ---
                    const Text("Deskripsi (Opsional)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: inputDecoration.copyWith(
                          hintText: 'Masukkan deskripsi singkat...'),
                      maxLines: 3,
                      // Validator dihapus agar opsional
                    ),
                    const SizedBox(height: 30),

                    // --- Tombol Submit ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3),
                              )
                            : Text(
                                isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Tambah Banner',
                                style: const TextStyle(
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

  Widget _buildImagePreview() {
    Widget placeholder = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 50, color: Colors.grey[600]),
        const SizedBox(height: 12),
        Text("Pilih Gambar Banner",
            style: TextStyle(color: Colors.grey[700], fontSize: 16)),
      ],
    );

    if (_imageFile != null) {
      if (kIsWeb) {
        return Image.network(_imageFile!.path,
            fit: BoxFit.cover, width: double.infinity);
      } else {
        return Image.file(File(_imageFile!.path),
            fit: BoxFit.cover, width: double.infinity);
      }
    } else if (_networkImageUrl != null) {
      return Image.network(_networkImageUrl!,
          fit: BoxFit.cover, width: double.infinity);
    } else {
      return placeholder;
    }
  }
}
