// ignore_for_file: use_build_context_synchronously, prefer_const_constructors

import 'dart:io'; // Hanya untuk mobile (Android/iOS)
import 'package:flutter/foundation.dart'
    show kIsWeb; // Untuk mendeteksi platform Web
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

      // Logika upload berbeda untuk Web dan Mobile
      if (kIsWeb) {
        // 🌐 Untuk Web: Upload menggunakan byte data
        await ref.putData(await image.readAsBytes());
      } else {
        // 📱 Untuk Mobile: Upload menggunakan path file
        await ref.putFile(File(image.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengunggah gambar: $e")),
      );
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi gambar: harus ada gambar jika membuat banner baru
    if (_imageFile == null && widget.banner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silakan pilih gambar untuk banner.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl = _networkImageUrl;

    // Jika ada file gambar baru yang dipilih, unggah dulu
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
      if (imageUrl == null) {
        setState(() => _isLoading = false);
        return; // Proses berhenti jika upload gagal
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
        // Buat banner baru
        await FirebaseFirestore.instance.collection('banners').add(data);
      } else {
        // Update banner yang ada
        await FirebaseFirestore.instance
            .collection('banners')
            .doc(widget.banner!.id)
            .update(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Banner berhasil disimpan!")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan data banner: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      // Tampilkan gambar baru yang dipilih
      if (kIsWeb) {
        return Image.network(
          _imageFile!.path,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(_imageFile!.path),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else if (_networkImageUrl != null) {
      // Tampilkan gambar lama dari internet (saat edit)
      return Image.network(
        _networkImageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      // Tampilan placeholder jika tidak ada gambar
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.banner == null ? 'Tambah Banner Baru' : 'Edit Banner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.photo_library),
                label: Text('Pilih Gambar'),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Banner',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Judul tidak boleh kosong'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Deskripsi tidak boleh kosong'
                    : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Simpan Banner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
