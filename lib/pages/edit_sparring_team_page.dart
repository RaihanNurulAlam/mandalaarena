// ignore_for_file: use_build_context_synchronously, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _updateTeam() async {
    if (_formKey.currentState!.validate()) {
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

      final updatedTeam = SparringTeam(
        id: widget.team.id,
        name: _nameController.text,
        imageUrl: _imageFile != null ? _imageFile!.path : widget.team.imageUrl,
        availableDays: _availableDays,
        availableHours: _availableHours,
        contact: _contactController.text,
        category: _selectedCategory!,
        createdBy: widget.team.createdBy,
      );

      await FirebaseFirestore.instance
          .collection('sparring_teams')
          .doc(updatedTeam.id)
          .update(updatedTeam.toMap());

      Navigator.pop(context, updatedTeam);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.team.name;
    _contactController.text = widget.team.contact;
    _availableDays.addAll(widget.team.availableDays);
    _availableHours.addAll(widget.team.availableHours);
    _selectedCategory = widget.team.category;
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
                        : NetworkImage(widget.team.imageUrl) as ImageProvider,
                    child: _imageFile == null
                        ? Icon(Icons.add_a_photo, size: 20)
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
                  validator: (value) =>
                      value!.isEmpty ? 'Nama tim tidak boleh kosong' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: 'Kontak (No. Telepon)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value!.isEmpty ? 'Kontak tidak boleh kosong' : null,
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
                ),
                SizedBox(height: 20),
                Column(
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
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Column(
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
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateTeam,
                  child: Text('Simpan Perubahan',
                      style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.white,
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
