// ignore_for_file: use_build_context_synchronously, avoid_print, sort_child_properties_last, prefer_interpolation_to_compose_strings

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';

class AddSparringTeamPage extends StatefulWidget {
  final SparringTeam? team;
  const AddSparringTeamPage({this.team});
  @override
  _AddSparringTeamPageState createState() => _AddSparringTeamPageState();
}

class _AddSparringTeamPageState extends State<AddSparringTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  Uint8List? _webImage; // Untuk menyimpan gambar di Web
  File? _imageFile; // Untuk Android/iOS
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

  Future<String?> _uploadImage() async {
    try {
      if (_imageFile == null && _webImage == null) {
        return null; // Jika tidak ada gambar, biarkan kosong
      }

      // Ambil nama tim dari input pengguna
      String teamName = _nameController.text.trim();

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

  Future<void> _saveTeam() async {
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Edit gambar terlebih dahulu!')),
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama tim harus diisi!')),
      );
      return;
    }

    if (_contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kontak harus diisi!')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
      );
      return;
    }

    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih hari terlebih dahulu!')),
      );
      return;
    }

    if (_selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih jam terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      // Menampilkan indikator loading
    });

    try {
      // 1️⃣ **Upload gambar ke Firebase Storage**
      String? imageUrl = await _uploadImage();

      // 3️⃣ **Simpan data tim ke Firestore**
      await FirebaseFirestore.instance.collection('sparring_teams').add({
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': imageUrl, // Simpan URL gambar di sini
        'contact': _contactController.text.trim(),
        'availableDays': _selectedDay != null ? [_selectedDay!] : [],
        'availableHours': _selectedHour != null ? [_selectedHour!] : [],
        'createdAt': Timestamp.now(),
      });

      // 4️⃣ **Kembali ke halaman sebelumnya**
      Navigator.pop(context, true); // Kembali dengan membawa data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tim berhasil ditambahkan!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tim: ${e.toString()}')),
      );
    } finally {
      setState(() {
        // Sembunyikan indikator loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Tim Sparring')),
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
                    backgroundImage:
                        _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile != null
                        ? ClipOval(
                            child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : _webImage != null
                            ? ClipOval(
                                child:
                                    Image.memory(_webImage!, fit: BoxFit.cover))
                            : Icon(Icons.add_a_photo, size: 20),
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
                    validator: (value) =>
                        value!.isEmpty ? 'Nama tim tidak boleh kosong' : null,
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
                    validator: (value) =>
                        value == null ? 'Pilih kategori terlebih dahulu' : null,
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
                            final isUnavailable =
                                time == '18:00'; // Jam 18:00 tidak bisa dipilih
                            return ChoiceChip(
                              label: Text(time),
                              selected: _selectedHour == time,
                              onSelected: isUnavailable
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        _selectedHour = selected ? time : null;
                                      });
                                    },
                              backgroundColor: isUnavailable
                                  ? Colors.grey.shade300
                                  : Colors.grey
                                      .shade100, // Nonaktifkan warna untuk jam tidak tersedia
                              labelStyle: TextStyle(
                                color:
                                    isUnavailable ? Colors.grey : Colors.black,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveTeam();
                    }
                  },
                  child: Text('Simpan', style: TextStyle(color: Colors.white)),
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
