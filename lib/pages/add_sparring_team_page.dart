// ignore_for_file: use_build_context_synchronously, avoid_print, sort_child_properties_last, prefer_interpolation_to_compose_strings, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';

class AddSparringTeamPage extends StatefulWidget {
  final SparringTeam? team;
  const AddSparringTeamPage({super.key, this.team});
  @override
  _AddSparringTeamPageState createState() => _AddSparringTeamPageState();
}

class _AddSparringTeamPageState extends State<AddSparringTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  Uint8List? _webImage;
  File? _imageFile;
  String? _selectedCategory;
  String? _selectedDay;
  String? _selectedHour;

  final List<String> _daysOfWeek = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  final List<String> _timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];
  final List<String> _categories = [
    'Tim Basket',
    'Tim Basket 3x3',
    'Tim Minisoccer',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
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

  Future<String?> _uploadImage(String teamName) async {
    try {
      if (_imageFile == null && _webImage == null) return null;
      String fileName =
          teamName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase() +
              '_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('team_images/$fileName');
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

  Future<void> _saveTeam() async {
    // 1. Validasi form dan pilihan
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Logo tim harus diisi!')));
      return;
    }
    if (_selectedCategory == null ||
        _selectedDay == null ||
        _selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap lengkapi semua pilihan jadwal dan kategori.')));
      return;
    }

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Upload gambar
      String? imageUrl = await _uploadImage(_nameController.text.trim());
      if (imageUrl == null) throw Exception("Gagal mengunggah gambar");

      // 3. Simpan data ke Firestore
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Pengguna tidak login");

      await FirebaseFirestore.instance.collection('sparring_teams').add({
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'contact': _contactController.text.trim(),
        'availableDays': [_selectedDay!],
        'availableHours': [_selectedHour!],
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
      });

      // Tutup dialog loading
      Navigator.pop(context);
      // Kembali ke halaman sebelumnya
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tim berhasil ditambahkan!')),
      );
    } catch (e) {
      // Tutup dialog loading jika terjadi error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tim: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tambah Tim Sparring'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Bagian Gambar ---
              _buildImagePickerSection(),
              const SizedBox(height: 8),
              Center(
                  child: Text("Pilih Logo Tim",
                      style: TextStyle(color: Colors.grey[600]))),
              const SizedBox(height: 24),

              // --- Bagian Informasi Dasar ---
              _buildInfoCard(),
              const SizedBox(height: 24),

              // --- Bagian Jadwal ---
              _buildScheduleCard(),
              const SizedBox(height: 32),

              // --- Tombol Simpan ---
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Tambahkan Tim'),
                onPressed: _saveTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(65),
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(width: 4, color: Colors.white),
            boxShadow: [
              BoxShadow(
                spreadRadius: 2,
                blurRadius: 10,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
            shape: BoxShape.circle,
          ),
          child: _imageFile == null && _webImage == null
              ? const Center(
                  child: Icon(Icons.add_a_photo, color: Colors.grey, size: 40))
              : ClipOval(
                  child: kIsWeb
                      ? Image.memory(_webImage!, fit: BoxFit.cover)
                      : Image.file(_imageFile!, fit: BoxFit.cover),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Nama Tim', Icons.group),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Nama tim tidak boleh kosong'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: _inputDecoration('Kontak (No. WA)', Icons.phone),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value!.isEmpty ? 'Kontak tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              onChanged: (value) => setState(() => _selectedCategory = value),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              decoration: _inputDecoration('Kategori Tim', Icons.category),
              validator: (value) => value == null ? 'Pilih kategori' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jadwal Sparring',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildChoiceChipGroup('Hari', _daysOfWeek, _selectedDay, (day) {
              setState(() => _selectedDay = day);
            }),
            const SizedBox(height: 16),
            _buildChoiceChipGroup('Jam', _timeSlots, _selectedHour, (time) {
              setState(() => _selectedHour = time);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChipGroup(String title, List<String> items,
      String? selectedItem, Function(String?) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: items.map((item) {
            final isSelected = selectedItem == item;
            final isUnavailable = item == '18:00'; // Contoh jam tidak tersedia

            return ChoiceChip(
              label: Text(item),
              selected: isSelected,
              onSelected: isUnavailable
                  ? null
                  : (selected) => onSelect(selected ? item : null),
              backgroundColor:
                  isUnavailable ? Colors.grey[300] : Colors.grey[100],
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                  color: isUnavailable
                      ? Colors.grey[500]
                      : isSelected
                          ? Colors.white
                          : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              shape: StadiumBorder(
                  side: BorderSide(
                      color: isSelected ? Colors.black : Colors.grey[300]!)),
              elevation: isSelected ? 2 : 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }
}
