// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, avoid_print, deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;
  final String phoneNumber;

  const EditProfilePage({
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.phoneNumber,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  File? _imageFile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    _phoneController.text = widget.phoneNumber;
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid;

        if (user == null) {
          throw Exception('User tidak ditemukan');
        }

        // Cek atau buat dokumen Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'profileImageUrl': widget.profileImageUrl,
          });
        }

        // Update data Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        });

        // Update password
        if (_oldPasswordController.text.isNotEmpty &&
            _newPasswordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty) {
          final credential = EmailAuthProvider.credential(
            email: widget.userEmail,
            password: _oldPasswordController.text,
          );

          await user.reauthenticateWithCredential(credential);

          if (_newPasswordController.text == _confirmPasswordController.text) {
            await user.updatePassword(_newPasswordController.text);
          } else {
            throw Exception('Password baru tidak cocok');
          }
        }

        // Update foto profil
        String? newProfileUrl = widget.profileImageUrl;
        if (_imageFile != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('$userId.jpg');
          await ref.putFile(_imageFile!);
          newProfileUrl = await ref.getDownloadURL();
          await user.updatePhotoURL(newProfileUrl);
        }

        // Reload pengguna untuk memperbarui data
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil berhasil diperbarui!')),
        );

        // Kembali ke halaman sebelumnya
        Navigator.pop(context, {
          'userName': updatedUser!.displayName ?? _nameController.text,
          'userEmail': updatedUser.email ?? _emailController.text,
          'profileImageUrl': updatedUser.photoURL ?? newProfileUrl,
          'phoneNumber': _phoneController.text,
        });
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e')),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubah Profil'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : NetworkImage(widget.profileImageUrl)
                                    as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, color: Colors.blue),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    Text('Ganti Password',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: _oldPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Password Lama',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
