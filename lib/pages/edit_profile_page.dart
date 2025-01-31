// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Crop image
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Image',
            ),
          ],
        );

        if (croppedFile != null) {
          // Resize image
          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            croppedFile.path,
            '${croppedFile.path}_compressed.jpg',
            quality: 85, // Adjust image quality (0-100)
          );

          setState(() {
            _imageFile = compressedFile != null
                ? File(compressedFile.path)
                : File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memproses gambar: $e'),
      ));
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final cloudinaryUrl =
          Uri.parse('https://api.cloudinary.com/v1_1/dru7n46a5/image/upload');
      final request = http.MultipartRequest('POST', cloudinaryUrl);

      // Tambahkan data wajib ke Cloudinary
      request.fields['upload_preset'] = 'mandala';

      // Tambahkan file gambar ke request
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['secure_url']; // URL gambar yang diunggah
      } else {
        print('Gagal mengunggah gambar: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error saat mengunggah gambar: $e');
      return null;
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
          throw Exception('Pengguna tidak ditemukan');
        }

        // Unggah foto profil jika ada perubahan
        String? newProfileUrl = widget.profileImageUrl;
        if (_imageFile != null) {
          newProfileUrl = await _uploadImageToCloudinary(_imageFile!);
          if (newProfileUrl == null) {
            throw Exception('Gagal mengunggah gambar');
          }
        }

        // Update data di Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'profileImageUrl': newProfileUrl,
        });

        // Update foto profil di Firebase Auth
        if (newProfileUrl != null) {
          await user.updatePhotoURL(newProfileUrl);
        }

        // Update nama di Firebase Auth
        await user.updateDisplayName(_nameController.text);

        // Update password jika dimasukkan
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

        // Reload pengguna untuk memperbarui data
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil berhasil diperbarui!')),
        );

        // Kembali ke halaman sebelumnya dengan data yang diperbarui
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
                                : widget.profileImageUrl.isNotEmpty
                                    ? NetworkImage(widget.profileImageUrl)
                                        as ImageProvider
                                    : AssetImage('assets/default_avatar.png')
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
                    Text(
                      'Ganti Password',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        child: Text(
                          'Simpan Perubahan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
