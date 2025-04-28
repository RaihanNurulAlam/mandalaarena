// ignore_for_file: use_build_context_synchronously, sort_child_properties_last, avoid_print, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'dart:typed_data'; // Untuk Uint8List
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';

class EditSparringTeamPage extends StatefulWidget {
  final SparringTeam team;
  const EditSparringTeamPage({required this.team});

  @override
  _EditSparringTeamPageState createState() => _EditSparringTeamPageState();
}

class _EditSparringTeamPageState extends State<EditSparringTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  File? _imageFile; // Untuk Android/iOS
  Uint8List? _webImage; // Untuk Web
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

  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      // Dapatkan referensi ke file gambar lama di Firebase Storage
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }

  Future<String?> _uploadImage(String teamName) async {
    try {
      if (_imageFile == null && _webImage == null) {
        return null; // Jika tidak ada gambar baru, kembalikan null
      }

      // Format nama file: hapus spasi dan karakter khusus, lalu tambahkan .jpg
      String fileName =
          teamName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase() +
              '.jpg';

      // Referensi ke Firebase Storage dengan nama file yang sesuai
      Reference storageRef =
          FirebaseStorage.instance.ref().child('team_images/$fileName');

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

  void _updateTeam() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih setidaknya satu hari')),
        );
        return;
      }

      if (_selectedHour == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih setidaknya satu jam')),
        );
        return;
      }

      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih kategori tim')),
        );
        return;
      }

      String? newImageUrl;

      // Jika ada gambar baru, hapus gambar lama dan upload gambar baru
      if (_imageFile != null || _webImage != null) {
        // Hapus gambar lama dari Firebase Storage
        await _deleteOldImage(widget.team.imageUrl);

        // Upload gambar baru ke Firebase Storage dengan nama tim yang baru
        newImageUrl = await _uploadImage(_nameController.text.trim());
      }

      final updatedTeam = SparringTeam(
        id: widget.team.id,
        name: _nameController.text,
        imageUrl: newImageUrl ??
            widget.team
                .imageUrl, // Gunakan URL baru jika ada, jika tidak, gunakan yang lama
        availableDays: [_selectedDay!], // Menggunakan hari yang dipilih
        availableHours: [_selectedHour!], // Menggunakan jam yang dipilih
        contact: _contactController.text,
        category: _selectedCategory!,
        createdBy: widget.team.createdBy,
        createdAt: widget.team.createdAt, // Tetapkan createdAt yang lama
      );

      // Update data tim di Firestore
      await FirebaseFirestore.instance
          .collection('sparring_teams')
          .doc(updatedTeam.id)
          .set(updatedTeam.toMap(), SetOptions(merge: true));

      Navigator.pop(context, updatedTeam);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Tim Sparring')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : _webImage != null
                            ? MemoryImage(_webImage!)
                            : NetworkImage(widget.team.imageUrl)
                                as ImageProvider,
                    child: _imageFile == null && _webImage == null
                        ? Icon(Icons.add_a_photo, size: 20)
                        : null,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Tim',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Nama tim tidak boleh kosong'
                        : null,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Kontak (No. Telepon)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value!.isEmpty ? 'Kontak tidak boleh kosong' : null,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Kategori Tim',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Pilih Hari Tersedia:',
                            style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: _daysOfWeek.map((day) {
                            return ChoiceChip(
                              label: Text(day),
                              selected: _selectedDay == day,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDay = selected ? day : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Pilih Jam Tersedia:',
                            style: TextStyle(fontSize: 16)),
                      ),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: _timeSlots.map((time) {
                            return ChoiceChip(
                              label: Text(time),
                              selected: _selectedHour == time,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedHour = selected ? time : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateTeam,
                  child: Text('Simpan Perubahan',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
