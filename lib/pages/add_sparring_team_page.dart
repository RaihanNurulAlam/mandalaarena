// ignore_for_file: use_build_context_synchronously, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';

class AddSparringTeamPage extends StatefulWidget {
  @override
  _AddSparringTeamPageState createState() => _AddSparringTeamPageState();
}

class _AddSparringTeamPageState extends State<AddSparringTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final List<String> _availableDays = [];
  final List<String> _availableHours = [];
  File? _imageFile;
  String? _selectedCategory;

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
    '08:00 - 10:00',
    '10:00 - 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    '18:00 - 20:00',
    '20:00 - 22:00',
  ];

  final List<String> _categories = [
    'Tim Basket',
    'Tim Basket 3x3',
    'Tim Minisoccer',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveTeam() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      if (_availableDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih setidaknya satu hari')),
        );
        return;
      }

      if (_availableHours.isEmpty) {
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

      // Upload gambar ke Firebase Storage (opsional)
      // Di sini kita hanya menyimpan URL gambar lokal untuk contoh
      final imageUrl = _imageFile!.path;

      final newTeam = SparringTeam(
        id: DateTime.now().toString(),
        name: _nameController.text,
        imageUrl: imageUrl,
        availableDays: _availableDays,
        availableHours: _availableHours,
        contact: _contactController.text,
        category: _selectedCategory!,
      );

      // Simpan ke Firestore
      await FirebaseFirestore.instance
          .collection('sparring_teams')
          .doc(newTeam.id)
          .set(newTeam.toMap());

      Navigator.pop(context, newTeam);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Tim Sparring'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40, // Memperbesar lingkaran tim
                    backgroundImage:
                        _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null
                        ? Icon(Icons.add_a_photo, size: 50)
                        : null,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Tim',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tim tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: 'Kontak (No. Telepon)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kontak tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih kategori tim';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pilih Hari Tersedia:',
                            style: TextStyle(fontSize: 16)),
                        Wrap(
                          spacing: 8,
                          children: _daysOfWeek.map((day) {
                            return FilterChip(
                              label: Text(day),
                              selected: _availableDays.contains(day),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _availableDays.add(day);
                                  } else {
                                    _availableDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pilih Jam Tersedia:',
                            style: TextStyle(fontSize: 16)),
                        Wrap(
                          spacing: 8,
                          children: _timeSlots.map((time) {
                            return FilterChip(
                              label: Text(time),
                              selected: _availableHours.contains(time),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _availableHours.add(time);
                                  } else {
                                    _availableHours.remove(time);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveTeam,
                  child: Text(
                    'Simpan',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.blueAccent, // Warna tombol
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
