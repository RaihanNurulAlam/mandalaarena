// ignore_for_file: use_build_context_synchronously, avoid_print, prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String profileImageUrl;
  final String phoneNumber;

  const EditProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.phoneNumber,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  Uint8List? _imageBytes;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    _phoneController.text = widget.phoneNumber;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedImage =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedImage != null) {
      final imageBytes = await pickedImage.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
        if (!kIsWeb) {
          _imageFile = File(pickedImage.path);
        }
      });
    }
  }

  Future<void> _deleteOldImage(String imageUrl) async {
    if (!imageUrl.contains('firebasestorage.googleapis.com')) {
      print("Skipping delete: URL is not a Firebase Storage URL.");
      return;
    }
    try {
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
      print("Old image deleted successfully.");
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null && _imageBytes == null) return null;

    try {
      String fileName = '$userId.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profile/$fileName');

      UploadTask uploadTask;
      if (kIsWeb && _imageBytes != null) {
        uploadTask = storageRef.putData(_imageBytes!);
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Pengguna tidak ditemukan');
      final userId = user.uid;

      bool passwordFieldsAreFilled = _oldPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty;

      if (passwordFieldsAreFilled) {
        if (_oldPasswordController.text.isEmpty ||
            _newPasswordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          throw Exception("Harap isi semua field password untuk menggantinya.");
        }
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception('Password baru dan konfirmasi password tidak cocok.');
        }

        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPasswordController.text,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newPasswordController.text);
      }

      String? newProfileUrl;

      if (_imageBytes != null) {
        if (widget.profileImageUrl.isNotEmpty) {
          await _deleteOldImage(widget.profileImageUrl);
        }
        newProfileUrl = await _uploadImage(userId);
        if (newProfileUrl == null) throw Exception('Gagal mengunggah gambar');
      }

      Map<String, dynamic> dataToUpdate = {};

      if (_nameController.text != widget.userName) {
        dataToUpdate['name'] = _nameController.text;
      }
      if (_phoneController.text != widget.phoneNumber) {
        dataToUpdate['phone'] = _phoneController.text;
      }
      if (newProfileUrl != null) {
        dataToUpdate['profileImageUrl'] = newProfileUrl;
      }

      if (dataToUpdate.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(dataToUpdate);
      }

      if (_nameController.text != user.displayName) {
        await user.updateDisplayName(_nameController.text);
      }

      await user.reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Profil'), // UI CHANGE: centerTitle dihapus
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16.0), // UI CHANGE: Padding utama dikembalikan
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
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (widget.profileImageUrl.isNotEmpty
                              ? NetworkImage(widget.profileImageUrl)
                              : null) as ImageProvider?,
                      child:
                          _imageBytes == null && widget.profileImageUrl.isEmpty
                              ? Icon(Icons.person,
                                  size: 70, color: Colors.grey.shade700)
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black,
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // UI CHANGE: Jarak dikembalikan
              _buildTextField(_nameController, 'Nama'),
              const SizedBox(height: 20),
              _buildTextField(_emailController, 'Email', isReadOnly: true),
              const SizedBox(height: 20),
              _buildTextField(_phoneController, 'Nomor Telepon',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              const Divider(), // UI CHANGE: Divider dikembalikan
              Padding(
                // UI CHANGE: Padding untuk judul dikembalikan
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Text('Ganti Password',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                  _oldPasswordController,
                  'Password Lama',
                  _isOldPasswordVisible,
                  () => setState(
                      () => _isOldPasswordVisible = !_isOldPasswordVisible)),
              const SizedBox(height: 20),
              _buildPasswordField(
                  _newPasswordController,
                  'Password Baru',
                  _isNewPasswordVisible,
                  () => setState(
                      () => _isNewPasswordVisible = !_isNewPasswordVisible)),
              const SizedBox(height: 20),
              _buildPasswordField(
                  _confirmPasswordController,
                  'Konfirmasi Password Baru',
                  _isConfirmPasswordVisible,
                  () => setState(() =>
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
              const SizedBox(height: 20),
              // UI CHANGE: Struktur tombol Simpan dikembalikan seperti asli
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI CHANGE: Padding dikembalikan ke dalam helper method
  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: isReadOnly,
          fillColor: isReadOnly ? Colors.grey.shade200 : null,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (label != 'Email' && (value == null || value.isEmpty)) {
            return 'Field $label tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }

  // UI CHANGE: Padding dikembalikan ke dalam helper method
  Widget _buildPasswordField(TextEditingController controller, String labelText,
      bool isVisible, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
