// ignore_for_file: use_build_context_synchronously, sort_child_properties_last, avoid_print, prefer_interpolation_to_compose_strings, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';

class EditSparringTeamPage extends StatefulWidget {
  final SparringTeam team;
  const EditSparringTeamPage({super.key, required this.team});

  @override
  _EditSparringTeamPageState createState() => _EditSparringTeamPageState();
}

class _EditSparringTeamPageState extends State<EditSparringTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  File? _imageFile;
  Uint8List? _webImage;
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

  // --- PERUBAHAN: Menghapus 'Tim Basket 3x3' agar konsisten ---
  final List<String> _categories = [
    'Tim Basket',
    'Tim Minisoccer',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.team.name;
    _contactController.text = widget.team.contact;
    _selectedCategory = widget.team.category;
    _selectedDay = widget.team.availableDays.isNotEmpty
        ? widget.team.availableDays.first
        : null;
    _selectedHour = widget.team.availableHours.isNotEmpty
        ? widget.team.availableHours.first
        : null;
  }

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

  Future<void> _deleteOldImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Error deleting old image: $e');
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

  void _updateTeam() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDay == null ||
          _selectedHour == null ||
          _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Harap lengkapi semua pilihan (hari, jam, dan kategori).')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      String? newImageUrl;
      if (_imageFile != null || _webImage != null) {
        if (widget.team.imageUrl.isNotEmpty) {
          await _deleteOldImage(widget.team.imageUrl);
        }
        newImageUrl = await _uploadImage(_nameController.text.trim());
      }

      final updatedData = {
        'name': _nameController.text.trim(),
        'imageUrl': newImageUrl ?? widget.team.imageUrl,
        'availableDays': [_selectedDay!],
        'availableHours': [_selectedHour!],
        'contact': _contactController.text.trim(),
        'category': _selectedCategory!,
      };

      await FirebaseFirestore.instance
          .collection('sparring_teams')
          .doc(widget.team.id)
          .update(updatedData);

      Navigator.pop(context); // Tutup dialog loading
      Navigator.pop(context,
          true); // Kembali ke halaman sebelumnya dan tandai ada perubahan
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Tim Sparring'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // --- Bagian Gambar ---
                  _buildImagePickerSection(),
                  const SizedBox(height: 8),
                  Text("Ganti Logo Tim",
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),

                  // --- Bagian Informasi Dasar ---
                  _buildInfoCard(),
                  const SizedBox(height: 24),

                  // --- Bagian Jadwal ---
                  _buildScheduleCard(),
                  const SizedBox(height: 32),

                  // --- Tombol Simpan ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('Simpan Perubahan'),
                    onPressed: _updateTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Center(
      child: Stack(
        children: [
          // Widget untuk menampilkan gambar (bisa dari file baru, web, atau network)
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.grey[200],
            backgroundImage: _webImage != null
                ? MemoryImage(_webImage!)
                : _imageFile != null
                    ? FileImage(_imageFile!)
                    : NetworkImage(widget.team.imageUrl.isNotEmpty
                        ? widget.team.imageUrl
                        : 'https://via.placeholder.com/150') as ImageProvider,
          ),
          // Tombol edit di pojok kanan bawah
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 3, color: Colors.white),
                  color: Colors.black,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
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
            // --- PERUBAHAN: Validasi No. WA disamakan ---
            TextFormField(
              controller: _contactController,
              decoration: _inputDecoration('Kontak (No. WA)', Icons.phone)
                  .copyWith(
                      hintText: '6281234567890',
                      helperText: 'Awali dengan 62 tanpa spasi atau +',
                      helperStyle: TextStyle(color: Colors.grey[600])),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kontak tidak boleh kosong';
                }
                final isDigitsOnly = RegExp(r'^[0-9]+$').hasMatch(value);
                if (!isDigitsOnly) {
                  return 'Kontak hanya boleh berisi angka';
                }
                if (!value.startsWith('62')) {
                  return 'Kontak harus diawali dengan 62';
                }
                if (value.length < 10) {
                  return 'Nomor kontak tidak valid';
                }
                return null;
              },
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
            // Judul diubah agar konsisten
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

  // --- PERUBAHAN: Logika jam 18:00 diaktifkan ---
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
            // Logika untuk membuat jam 18:00 tidak tersedia telah di-comment
            // final isUnavailable = item == '18:00';

            return ChoiceChip(
              label: Text(item),
              selected: isSelected,
              // Pengecekan isUnavailable dihapus dari sini
              onSelected: (selected) => onSelect(selected ? item : null),
              // Pengecekan isUnavailable dihapus dari sini
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                  // Pengecekan isUnavailable dihapus dari sini
                  color: isSelected ? Colors.white : Colors.black,
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
      prefixIcon: Icon(icon, color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }
}
