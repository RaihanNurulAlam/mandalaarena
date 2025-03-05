// ignore_for_file: avoid_print, use_rethrow_when_possible, use_build_context_synchronously, sort_child_properties_last

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mandalaarenaapp/pages/models/sparring_team_model.dart';
import 'package:mandalaarenaapp/pages/sparring_team_page.dart';

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
  final _costController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDay;
  String? _selectedHour;

  XFile? _imageFile; // Digunakan untuk Web & Mobile
  Uint8List? _webImage; // Digunakan khusus untuk Web

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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Baca data gambar sebagai Uint8List untuk Web
        var f = await pickedFile.readAsBytes();
        setState(() {
          _webImage = f;
        });
      } else {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    }
  }

  Future<String> _uploadImage() async {
    try {
      if (_imageFile == null && _webImage == null) {
        throw "Pilih gambar terlebih dahulu";
      }

      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          FirebaseStorage.instance.ref().child('sparring_teams/$fileName.jpg');

      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = storageReference.putData(_webImage!); // Web: putData
      } else {
        File file = File(_imageFile!.path);
        uploadTask = storageReference.putFile(file); // Mobile: putFile
      }

      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Error uploading image: $e");
      throw e;
    }
  }

  void _saveTeam() async {
    // panggil validator
    if (_formKey.currentState!.validate()) {
      if ((_imageFile != null || _webImage != null) &&
          _selectedCategory != null &&
          _selectedDay != null &&
          _selectedHour != null) {
        try {
          final imageUrl = await _uploadImage();
          final user = FirebaseAuth.instance.currentUser;

          final newTeam = SparringTeam(
            id: DateTime.now().toString(),
            name: _nameController.text,
            imageUrl: imageUrl,
            availableDays: [_selectedDay!],
            availableHours: [_selectedHour!],
            contact: _contactController.text,
            category: _selectedCategory!,
            createdBy: user!.uid,
            cost: double.parse(_costController.text),
            createdAt: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection('sparring_teams')
              .doc(newTeam.id)
              .set(newTeam.toMap());

          // Navigasi ke SparringPage setelah data berhasil disimpan
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SparringTeamPage()),
          );
        } catch (e) {
          print('Error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan data: $e')),
          );
        }
      } else {
        String errorMessage = 'Harap lengkapi semua data terlebih dahulu';
        if (_imageFile == null && _webImage == null) {
          errorMessage = "Harap pilih gambar terlebih dahulu";
        }
        if (_selectedCategory == null) {
          errorMessage = "Harap pilih kategori tim terlebih dahulu";
        }
        if (_selectedDay == null) {
          errorMessage = "Harap pilih hari terlebih dahulu";
        }
        if (_selectedHour == null) {
          errorMessage = "Harap pilih jam terlebih dahulu";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Harap lengkapi data terlebih dahulu!")),
      );
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
                    backgroundImage: _webImage != null
                        ? MemoryImage(_webImage!) // Web
                        : _imageFile != null
                            ? FileImage(File(_imageFile!.path)) // Mobile
                            : null,
                    child: (_imageFile == null && _webImage == null)
                        ? Icon(Icons.add_a_photo, size: 20)
                        : null,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
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
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
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
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _costController,
                    decoration: InputDecoration(
                      labelText: 'Biaya Sparring',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Biaya tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    validator: (value) {
                      if (value == null) {
                        return 'Kategori tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      if (_selectedDay == null)
                        Text(
                          "Pilih Hari terlebih dahulu",
                          style: TextStyle(color: Colors.red),
                        )
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      if (_selectedHour == null)
                        Text(
                          "Pilih Jam terlebih dahulu",
                          style: TextStyle(color: Colors.red),
                        )
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveTeam,
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
